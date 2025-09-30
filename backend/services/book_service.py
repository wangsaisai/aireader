import re
import json
import logging
from typing import Optional, Dict, Any

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from starlette.background import BackgroundTask

from models import Book
from services.gemini_service import GeminiService
from utils.helpers import get_or_create_book, async_add_book_introduction, async_add_book_report

logger = logging.getLogger(__name__)


class BookService:
    """书籍业务逻辑处理"""

    def __init__(self, db_session: AsyncSession, gemini_service: GeminiService):
        self.db = db_session
        self.gemini_service = gemini_service

    async def get_book_introduction(self, title: str, author: Optional[str] = None) -> (Optional[Dict[str, Any]], BackgroundTask):
        """获取书籍简介"""
        book = await get_or_create_book(self.db, title, author)

        if book.introduction:
            try:
                # Assuming introduction is a JSON string
                introduction_data = json.loads(book.introduction)
                introduction_data['is_found'] = True
                return introduction_data, None
            except json.JSONDecodeError:
                # Fallback for old plain text data
                return {"description": book.introduction, "is_found": True}, None

        book_info = await self.gemini_service.generate_book_info(title)

        if not book_info or not book_info.description:
            return None, None

        # Convert Pydantic model to dict for consistency
        book_info_dict = book_info.dict()
        book_info_dict['is_found'] = True
        introduction_json = json.dumps(book_info_dict)
        task = BackgroundTask(async_add_book_introduction, book_id=book.id, introduction=introduction_json)

        return book_info_dict, task

    async def generate_detailed_report(self, title: str, author: Optional[str] = None) -> (Optional[str], BackgroundTask):
        """生成详细的书籍报告"""
        book = await get_or_create_book(self.db, title, author)

        if book.report:
            return book.report, None

        report = await self.gemini_service.generate_detailed_report(title, author)
        # Pass only the necessary data, not the db session
        task = BackgroundTask(async_add_book_report, book_id=book.id, report=report)

        return report, task
