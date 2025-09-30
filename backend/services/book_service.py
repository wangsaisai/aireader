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
        stmt = select(Book).where(
            (Book.title == title) |
            (Book.aliases.like(f"%,{title},%"))
        )
        result = await self.db.execute(stmt)
        book = result.scalars().first()

        if book:
            # If the book is found and the queried title is not in the aliases, add it.
            if title != book.title:
                # Ensure aliases string exists and is not empty
                if not book.aliases:
                    book.aliases = f",{title},"
                # Check if the alias is already in the list
                elif f",{title}," not in book.aliases:
                    book.aliases += f"{title},"

                await self.db.commit()
                await self.db.refresh(book)

        if book and book.introduction:
            try:
                introduction_data = json.loads(book.introduction)
                introduction_data['is_found'] = True
                return introduction_data, None
            except json.JSONDecodeError:
                return {"description": book.introduction, "is_found": True}, None

        # Book not in DB, or has no introduction. Let's ask Gemini.
        book_info = await self.gemini_service.generate_book_info(title)

        # If Gemini doesn't find it, we do nothing and return.
        if not book_info or not book_info.description:
            return None, None

        # Gemini found it. Let's prepare to save it to DB.
        book_info_dict = book_info.dict()
        book_info_dict['is_found'] = True
        introduction_json = json.dumps(book_info_dict)

        # Re-check if the book exists with the canonical title from Gemini
        if not book and book_info.title:
            stmt = select(Book).where(Book.title == book_info.title)
            result = await self.db.execute(stmt)
            book = result.scalars().first()

            # If book found, update its aliases and any missing info
            if book:
                update_needed = False
                # Update aliases
                if not book.aliases:
                    book.aliases = f",{title},"
                    update_needed = True
                elif f",{title}," not in book.aliases:
                    book.aliases += f"{title},"
                    update_needed = True

                # Update missing author
                if not book.author and book_info.author:
                    book.author = book_info.author
                    update_needed = True

                if update_needed:
                    await self.db.commit()
                    await self.db.refresh(book)

        if not book:
            # Create a new book entry if it wasn't in the DB
            book = Book(
                title=book_info.title or title,
                author=book_info.author or author,
                aliases=f",{title},"
            )
            self.db.add(book)
            await self.db.commit()
            await self.db.refresh(book)

        # Schedule a background task to add the introduction
        task = BackgroundTask(async_add_book_introduction, book_id=book.id, introduction=introduction_json)

        return book_info_dict, task

    async def generate_detailed_report(self, title: str, author: Optional[str] = None) -> (Optional[str], BackgroundTask):
        """生成详细的书籍报告"""
        stmt = select(Book).where(
            (Book.title == title) & (Book.author == author)
        )
        result = await self.db.execute(stmt)
        book = result.scalars().first()

        # If the exact book is not found in our DB, we cannot generate a report.
        if not book:
            return None, None

        if book.report:
            return book.report, None

        # Book exists, but no report. Generate it.
        report = await self.gemini_service.generate_detailed_report(title, author)

        if not report:
            return None, None # Failed to generate report.

        # Report generated successfully, save it in the background.
        task = BackgroundTask(async_add_book_report, book_id=book.id, report=report)

        return report, task
