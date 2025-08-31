import re
import json
import logging
from typing import Optional, Dict, Any
from models.book import BookInfo
from services.gemini_service import GeminiService

logger = logging.getLogger(__name__)

def clean_json_response(text: str) -> Optional[Dict[str, Any]]:
    """清理并解析JSON响应"""
    try:
        # 移除markdown代码块标记
        text = re.sub(r'```json\s*|\s*```', '', text)
        
        # 移除前后空白
        text = text.strip()
        
        # 尝试直接解析
        return json.loads(text)
    except json.JSONDecodeError:
        # 如果直接解析失败，尝试提取JSON对象
        try:
            # 查找JSON对象开始和结束位置
            start = text.find('{')
            end = text.rfind('}') + 1
            
            if start != -1 and end > start:
                json_str = text[start:end]
                return json.loads(json_str)
        except:
            pass
        
        logger.error(f"Failed to parse JSON response: {text[:200]}...")
        return None

def validate_book_name(book_name: str) -> bool:
    """验证书籍名称"""
    if not book_name or not book_name.strip():
        return False
    
    # 基本长度检查
    if len(book_name.strip()) < 2 or len(book_name.strip()) > 200:
        return False
    
    return True

def format_book_response(book_info: BookInfo) -> Dict[str, Any]:
    """格式化书籍信息响应"""
    return {
        "title": book_info.title,
        "author": book_info.author,
        "publisher": book_info.publisher,
        "year": book_info.year,
        "isbn": book_info.isbn,
        "description": book_info.description,
        "summary": book_info.summary
    }

class BookService:
    """书籍业务逻辑处理"""
    
    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service
        self.book_cache = {}  # 简单的内存缓存
    
    async def get_book_info(self, book_name: str) -> Optional[BookInfo]:
        """获取书籍信息"""
        # 验证输入
        if not validate_book_name(book_name):
            raise ValueError("Invalid book name")
        
        # 检查缓存
        cache_key = book_name.lower().strip()
        if cache_key in self.book_cache:
            return self.book_cache[cache_key]
        
        # 调用Gemini服务
        book_info = await self.gemini_service.generate_book_info(book_name)
        
        # 缓存结果
        if book_info:
            self.book_cache[cache_key] = book_info
        
        return book_info
    
    async def answer_book_question(self, book_name: str, question: str) -> Optional[str]:
        """回答书籍相关问题"""
        # 验证输入
        if not validate_book_name(book_name):
            raise ValueError("Invalid book name")
        
        if not question or not question.strip():
            raise ValueError("Question cannot be empty")
        
        # 调用Gemini服务
        answer = await self.gemini_service.answer_question(book_name, question)
        
        return answer
    
    async def answer_book_question_with_context(self, book_name: str, question: str, context: str = "") -> Optional[str]:
        """回答书籍相关问题（带上下文）"""
        # 验证输入
        if not validate_book_name(book_name):
            raise ValueError("Invalid book name")
        
        if not question or not question.strip():
            raise ValueError("Question cannot be empty")
        
        # 调用Gemini服务（传入上下文）
        answer = await self.gemini_service.answer_question_with_context(book_name, question, context)
        
        return answer

    async def generate_detailed_report(self, book_name: str, author: Optional[str] = None) -> Optional[str]:
        """生成详细的书籍报告"""
        # 验证输入
        if not validate_book_name(book_name):
            raise ValueError("Invalid book name")
        
        # 调用Gemini服务生成报告
        report = await self.gemini_service.generate_detailed_report(book_name, author)
        
        return report
    
    def get_cached_book_info(self, book_name: str) -> Optional[BookInfo]:
        """获取缓存的书籍信息"""
        cache_key = book_name.lower().strip()
        return self.book_cache.get(cache_key)
    
    def clear_cache(self):
        """清空缓存"""
        self.book_cache.clear()
    
    def get_cache_stats(self) -> Dict[str, int]:
        """获取缓存统计信息"""
        return {
            "total_cached_books": len(self.book_cache),
            "cache_keys": list(self.book_cache.keys())
        }