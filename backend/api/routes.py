import logging
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from api.schemas import BookInfoRequest, APIResponse, GenerateReportRequest, ComplaintCreate, ChatRequest, LikeCreate
from services.book_service import BookService
from services.gemini_service import GeminiService
from utils.helpers import (
    create_success_response, create_error_response, log_error, get_or_create_book,
    async_save_qa_message, async_save_feedback
)
from database import get_db

router = APIRouter()
logger = logging.getLogger(__name__)

# Dependency Injection
def get_gemini_service() -> GeminiService:
    return GeminiService()

def get_book_service(db: AsyncSession = Depends(get_db), gemini_service: GeminiService = Depends(get_gemini_service)) -> BookService:
    return BookService(db, gemini_service)

@router.post("/book/info", response_model=APIResponse)
async def get_book_introduction(
    request: BookInfoRequest,
    background_tasks: BackgroundTasks,
    book_service: BookService = Depends(get_book_service)
):
    """获取书籍简介"""
    try:
        book_info, task = await book_service.get_book_introduction(request.book_name, request.author)
        if task:
            background_tasks.add_task(task)

        if book_info:
            logger.info(f"Book info found for '{request.book_name}'")
            return create_success_response(data=book_info)
        else:
            logger.warning(f"No introduction found for '{request.book_name}'")
            return create_error_response("Not found", "Could not retrieve introduction for the book.")
    except Exception as e:
        log_error(e, "Error getting book introduction")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat/generate_report", response_model=APIResponse)
async def generate_detailed_report(
    request: GenerateReportRequest,
    background_tasks: BackgroundTasks,
    book_service: BookService = Depends(get_book_service)
):
    """生成详细的书籍报告"""
    try:
        report, task = await book_service.generate_detailed_report(request.book_name, request.author)
        if task:
            background_tasks.add_task(task)
        return create_success_response(data={"report": report})
    except Exception as e:
        log_error(e, "Error generating detailed report")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat/ask", response_model=APIResponse)
async def chat_with_history(
    request: ChatRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    gemini_service: GeminiService = Depends(get_gemini_service)
):
    """带历史对话的无状态问答"""
    try:
        book = await get_or_create_book(db, request.book_name)

        context = "\n".join([f"{msg.role}: {msg.content}" for msg in request.messages])
        answer = await gemini_service.answer_question_with_context(request.book_name, request.question, context)

        if answer:
            response_data = {"answer": answer}
            background_tasks.add_task(async_save_qa_message, book_id=book.id, request_payload=request.dict(), response_payload=response_data)
            return create_success_response(data=response_data)
        else:
            return create_error_response(error="No answer generated")

    except Exception as e:
        log_error(e, "Error in chat with history")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/complaint", response_model=APIResponse)
async def submit_complaint(
    request: ComplaintCreate,
    background_tasks: BackgroundTasks
):
    """接收用户投诉"""
    try:
        feedback_data = request.dict()
        feedback_data['feedback_type'] = 'dislike'
        background_tasks.add_task(async_save_feedback, request_payload=feedback_data)
        return create_success_response(message="Complaint submitted successfully")
    except Exception as e:
        log_error(e, "Error submitting complaint")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/like", response_model=APIResponse)
async def submit_like(
    request: LikeCreate,
    background_tasks: BackgroundTasks
):
    """接收用户点赞"""
    try:
        feedback_data = request.dict()
        feedback_data['feedback_type'] = 'like'
        background_tasks.add_task(async_save_feedback, request_payload=feedback_data)
        return create_success_response(message="Like submitted successfully")
    except Exception as e:
        log_error(e, "Error submitting like")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health_check():
    """健康检查接口"""
    return create_success_response(data={"status": "healthy"})
