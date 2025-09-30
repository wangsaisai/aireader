import re
import json
import logging
from typing import Optional, Dict, Any

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

# Import the session factory, not a session instance
from database import AsyncSessionLocal
from models import Book, QAMessage, Feedback

logger = logging.getLogger(__name__)


async def get_or_create_book(db: AsyncSession, title: str, author: Optional[str] = None) -> Book:
    """获取或创建书籍 (在请求周期内执行)"""
    result = await db.execute(
        select(Book).filter_by(title=title, author=author)
    )
    book = result.scalars().first()

    if not book:
        book = Book(title=title, author=author)
        db.add(book)
        await db.commit()
        await db.refresh(book)

    return book


# --- Background Task Functions ---
# These functions create their own DB session.

async def async_add_book_introduction(book_id: int, introduction: str):
    """(后台任务) 异步添加书籍简介"""
    async with AsyncSessionLocal() as session:
        async with session.begin():
            book = await session.get(Book, book_id)
            if book and not book.introduction:
                book.introduction = introduction


async def async_add_book_report(book_id: int, report: str):
    """(后台任务) 异步添加书籍报告"""
    async with AsyncSessionLocal() as session:
        async with session.begin():
            book = await session.get(Book, book_id)
            if book and not book.report:
                book.report = report


async def async_save_qa_message(book_id: int, request_payload: dict, response_payload: dict):
    """(后台任务) 异步保存问答消息"""
    async with AsyncSessionLocal() as session:
        async with session.begin():
            chat_message = QAMessage(
                book_id=book_id,
                request_payload=request_payload,
                response_payload=response_payload
            )
            session.add(chat_message)


async def async_save_feedback(request_payload: dict):
    """(后台任务) 异步保存用户反馈"""
    async with AsyncSessionLocal() as session:
        async with session.begin():
            feedback_type = request_payload.pop('feedback_type', None)
            feedback = Feedback(
                request_payload=request_payload
            )
            session.add(feedback)


# --- Other Utility Functions ---

def clean_json_response(text: str) -> Optional[Dict[str, Any]]:
    """清理并解析JSON响应"""
    # ... (rest of the function remains the same)
    try:
        text = re.sub(r'```json\s*|\s*```', '', text).strip()
        return json.loads(text)
    except json.JSONDecodeError:
        logger.error(f"Failed to parse JSON response: {text[:200]}...")
        return None


def validate_book_name(book_name: str) -> bool:
    """验证书籍名称"""
    if not book_name or not book_name.strip() or not (2 <= len(book_name.strip()) <= 200):
        return False
    return True


def sanitize_input(text: str) -> str:
    """清理用户输入"""
    if not text:
        return ""
    text = re.sub(r'[<>"\']', '', text)
    return text.strip()[:1000]


def log_error(error: Exception, context: str = ""):
    """记录错误日志"""
    error_msg = f"{context}: {str(error)}" if context else str(error)
    logger.error(error_msg, exc_info=True)


def create_success_response(data: Any = None, message: str = "Success") -> Dict[str, Any]:
    """创建成功响应"""
    return {
        "success": True,
        "data": data,
        "error": None,
        "message": message
    }


def create_error_response(error: str, message: str = "Error") -> Dict[str, Any]:
    """创建错误响应"""
    return {
        "success": False,
        "data": None,
        "error": error,
        "message": message
    }
