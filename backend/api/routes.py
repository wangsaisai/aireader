from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
from api.schemas import BookInfoRequest, QARequest, APIResponse
from services.book_service import BookService
from services.gemini_service import GeminiService
from utils.helpers import create_success_response, create_error_response, log_error

router = APIRouter()

# 依赖注入
def get_book_service() -> BookService:
    """获取书籍服务实例"""
    try:
        gemini_service = GeminiService()
        return BookService(gemini_service)
    except Exception as e:
        log_error(e, "Failed to initialize book service")
        raise HTTPException(status_code=500, detail="Service initialization failed")

@router.post("/book/info", response_model=APIResponse)
async def get_book_info(
    request: BookInfoRequest,
    book_service: BookService = Depends(get_book_service)
):
    """获取书籍信息"""
    try:
        book_info = await book_service.get_book_info(request.book_name)
        
        if book_info:
            return create_success_response(
                data={
                    "title": book_info.title,
                    "author": book_info.author,
                    "publisher": book_info.publisher,
                    "year": book_info.year,
                    "isbn": book_info.isbn,
                    "description": book_info.description,
                    "summary": book_info.summary,
                    "genre": book_info.genre,
                    "pages": book_info.pages,
                    "language": book_info.language,
                    "rating": book_info.rating,
                    "awards": book_info.awards
                },
                message="Book information retrieved successfully"
            )
        else:
            return create_error_response(
                error="Book information not found",
                message="Unable to retrieve book information"
            )
            
    except ValueError as e:
        return create_error_response(
            error=str(e),
            message="Invalid input"
        )
    except Exception as e:
        log_error(e, "Error getting book info")
        return create_error_response(
            error="Internal server error",
            message="Failed to retrieve book information"
        )

@router.post("/book/qa", response_model=APIResponse)
async def answer_question(
    request: QARequest,
    book_service: BookService = Depends(get_book_service)
):
    """回答书籍相关问题"""
    try:
        answer = await book_service.answer_book_question(request.book_name, request.question)
        
        if answer:
            return create_success_response(
                data={"answer": answer},
                message="Question answered successfully"
            )
        else:
            return create_error_response(
                error="No answer generated",
                message="Unable to generate answer for the question"
            )
            
    except ValueError as e:
        return create_error_response(
            error=str(e),
            message="Invalid input"
        )
    except Exception as e:
        log_error(e, "Error answering question")
        return create_error_response(
            error="Internal server error",
            message="Failed to answer question"
        )

@router.get("/health")
async def health_check():
    """健康检查接口"""
    try:
        # 检查Gemini服务是否正常
        gemini_service = GeminiService()
        return create_success_response(
            data={
                "status": "healthy",
                "service": "AI Book Assistant Backend",
                "gemini_model": gemini_service.model_name
            },
            message="Service is running normally"
        )
    except Exception as e:
        log_error(e, "Health check failed")
        return create_error_response(
            error="Service unhealthy",
            message="Health check failed"
        )

@router.get("/cache/stats")
async def get_cache_stats(book_service: BookService = Depends(get_book_service)):
    """获取缓存统计信息"""
    try:
        stats = book_service.get_cache_stats()
        return create_success_response(
            data=stats,
            message="Cache statistics retrieved successfully"
        )
    except Exception as e:
        log_error(e, "Error getting cache stats")
        return create_error_response(
            error="Failed to get cache statistics",
            message="Internal server error"
        )

@router.post("/cache/clear")
async def clear_cache(book_service: BookService = Depends(get_book_service)):
    """清空缓存"""
    try:
        book_service.clear_cache()
        return create_success_response(
            message="Cache cleared successfully"
        )
    except Exception as e:
        log_error(e, "Error clearing cache")
        return create_error_response(
            error="Failed to clear cache",
            message="Internal server error"
        )

# ===== 无状态对话API =====

class ChatMessage(BaseModel):
    """聊天消息模型"""
    role: str  # "user" 或 "assistant"
    content: str

class ChatRequest(BaseModel):
    """聊天请求模型"""
    book_name: str
    messages: List[ChatMessage]
    question: str

@router.post("/chat/ask", response_model=APIResponse)
async def chat_with_history(
    request: ChatRequest,
    book_service: BookService = Depends(get_book_service)
):
    """带历史对话的无状态问答"""
    try:
        # 构建对话上下文
        context_parts = []
        for msg in request.messages:
            if msg.role == "user":
                context_parts.append(f"用户: {msg.content}")
            elif msg.role == "assistant":
                context_parts.append(f"助手: {msg.content}")
        
        context = "\n".join(context_parts)
        
        # 调用问答服务（传入上下文）
        answer = await book_service.answer_book_question_with_context(
            request.book_name, 
            request.question, 
            context
        )
        
        if answer:
            return create_success_response(
                data={"answer": answer},
                message="Question answered successfully"
            )
        else:
            return create_error_response(
                error="No answer generated",
                message="Unable to generate answer for the question"
            )
    except Exception as e:
        log_error(e, "Error in chat with history")
        return create_error_response(
            error="Internal server error",
            message="Failed to answer question"
        )

