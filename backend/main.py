"""
AI Book Assistant Backend
基于Google Gemini的AI读书助手后端服务
"""

import logging
import sys
import os
import uvicorn
import time
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager

# 添加当前目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import settings
from api.routes import router
from utils.helpers import log_error

# 配置日志
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(settings.log_file),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时执行
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    
    # 验证配置
    if not settings.debug:
        validation_errors = settings.validate_settings()
        if validation_errors:
            logger.error("Configuration validation failed:")
            for error in validation_errors:
                logger.error(f"  - {error}")
            raise ValueError("Invalid configuration")
    
    yield
    
    # 关闭时执行
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

# 添加请求日志中间件
@app.middleware("http")
async def log_requests(request, call_next):
    """记录请求处理时间"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    logger.info(f"{timestamp} - Request {request.method} {request.url.path} completed in {process_time:.4f}s")
    return response

# 添加全局异常处理
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """全局异常处理器"""
    log_error(exc, f"Unhandled exception in {request.url}")
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Internal server error",
            "message": "An unexpected error occurred"
        }
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """HTTP异常处理器"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.detail,
            "message": "HTTP error occurred"
        }
    )

# 添加路由
app.include_router(router, prefix="/api")

# 根路径
@app.get("/")
async def root():
    """根路径"""
    return {
        "success": True,
        "data": {
            "service": settings.app_name,
            "version": settings.app_version,
            "status": "running"
        },
        "message": "AI Book Assistant Backend is running"
    }

# 健康检查
@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "success": True,
        "data": {
            "status": "healthy",
            "service": settings.app_name,
            "version": settings.app_version
        },
        "message": "Service is healthy"
    }

# 开发信息
if settings.debug:
    @app.get("/debug/info")
    async def debug_info():
        """调试信息（仅开发环境）"""
        return {
            "success": True,
            "data": {
                "settings": {
                    "app_name": settings.app_name,
                    "app_version": settings.app_version,
                    "debug": settings.debug,
                    "host": settings.host,
                    "port": settings.port,
                    "gemini_model": settings.gemini_model,
                    "cors_origins": settings.cors_origins,
                    "cache_enabled": settings.cache_enabled,
                    "rate_limit_enabled": settings.rate_limit_enabled
                }
            },
            "message": "Debug information"
        }

def main():
    """主函数"""
    logger.info(f"Starting server on {settings.host}:{settings.port}")
    
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )

if __name__ == "__main__":
    main()