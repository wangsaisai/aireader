"""
AI Book Assistant Backend
基于Google Gemini的AI读书助手后端服务
"""

import logging
import sys
import os
import uvicorn
import time
import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from starlette.background import BackgroundTask
from starlette.types import Message

# 添加当前目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import settings
from api.routes import router
from utils.helpers import log_error
from database import init_db, AsyncSessionLocal
from models import APIRequestLog

# 配置日志
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")

    validation_errors = settings.validate_settings()
    if validation_errors:
        for error in validation_errors:
            logger.error(f"  - {error}")
        raise ValueError("Invalid configuration")

    logger.info("Initializing database...")
    await init_db()
    logger.info("Database initialized.")

    yield

    logger.info(f"Shutting down {settings.app_name}")

# 创建FastAPI应用
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="基于Google Gemini的AI读书助手后端服务",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
)

async def log_request_to_db(
    method: str,
    path: str,
    request_body: bytes,
    response_body: bytes,
    status_code: int,
    process_time: float
):
    """(后台任务) 异步记录请求到数据库"""
    async with AsyncSessionLocal() as session:
        try:
            request_body_json = None
            if request_body:
                try:
                    request_body_json = json.loads(request_body)
                except json.JSONDecodeError:
                    request_body_json = {"raw_body": request_body.decode('utf-8', 'ignore')}

            response_body_json = None
            if response_body:
                try:
                    response_body_json = json.loads(response_body)
                except json.JSONDecodeError:
                    response_body_json = {"raw_body": response_body.decode('utf-8', 'ignore')}

            log_entry = APIRequestLog(
                method=method,
                path=path,
                request_body=request_body_json,
                status_code=status_code,
                response_body=response_body_json,
                response_time_ms=int(process_time * 1000)
            )
            session.add(log_entry)
            await session.commit()
        except Exception as e:
            logger.error(f"Failed to log request to DB: {e}", exc_info=True)
            await session.rollback()

@app.middleware("http")
async def log_requests_middleware(request: Request, call_next):
    """中间件：记录请求，并安全地处理请求和响应体以供后台日志记录"""
    start_time = time.time()

    # 1. 安全地读取请求体一次
    request_body = await request.body()

    # 2. 创建一个新的 "receive" 函数，它将返回缓存的请求体
    #    这使得后续的应用（如FastAPI的Pydantic解析）可以再次读取它
    async def receive() -> Message:
        return {"type": "http.request", "body": request_body, "more_body": False}

    # 3. 创建一个新的请求对象，它使用我们伪造的 "receive" 函数
    new_request = Request(request.scope, receive)

    # 4. 使用新的请求对象调用应用
    response = await call_next(new_request)
    process_time = time.time() - start_time

    # 5. 安全地读取响应体一次
    response_body = b""
    async for chunk in response.body_iterator:
        response_body += chunk

    # 6. 创建后台任务，传递请求和响应体的字节串副本
    task = BackgroundTask(
        log_request_to_db,
        method=request.method,
        path=request.url.path,
        request_body=request_body,
        response_body=response_body,
        status_code=response.status_code,
        process_time=process_time
    )

    # 7. 返回一个新的响应，因为原始的 body_iterator 已被消耗
    return Response(
        content=response_body,
        status_code=response.status_code,
        headers=dict(response.headers),
        media_type=response.media_type,
        background=task
    )

# 添加全局异常处理
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """全局异常处理器"""
    log_error(exc, f"Unhandled exception in {request.url}")
    return JSONResponse(status_code=500, content={"success": False, "error": "Internal server error"})

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """HTTP异常处理器"""
    return JSONResponse(status_code=exc.status_code, content={"success": False, "error": exc.detail})

# 添加路由
app.include_router(router, prefix="/api")

# 根路径
@app.get("/")
async def root():
    return {"service": settings.app_name, "version": settings.app_version, "status": "running"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )
