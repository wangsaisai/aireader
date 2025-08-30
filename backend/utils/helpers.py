import re
import json
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

def clean_json_response(text: str) -> Optional[Dict[str, Any]]:
    """清理并解析JSON响应"""
    try:
        # 移除markdown代码块标记
        text = re.sub(r'```json\s*|\s*```', '', text)
        
        # 移除前后空白
        text = text.strip()
        
        # 尝试直接解析
        data = json.loads(text)
        
        # 转换数据类型以匹配BookInfo模型
        if 'year' in data and data['year'] is not None:
            data['year'] = str(data['year'])
        if 'pages' in data and data['pages'] is not None:
            data['pages'] = str(data['pages'])
        if 'rating' in data and data['rating'] is not None:
            data['rating'] = str(data['rating'])
        if 'awards' in data and data['awards'] is not None:
            if isinstance(data['awards'], list):
                data['awards'] = ', '.join(data['awards'])
            else:
                data['awards'] = str(data['awards'])
        
        return data
    except json.JSONDecodeError:
        # 如果直接解析失败，尝试提取JSON对象
        try:
            # 查找JSON对象开始和结束位置
            start = text.find('{')
            end = text.rfind('}') + 1
            
            if start != -1 and end > start:
                json_str = text[start:end]
                data = json.loads(json_str)
                
                # 转换数据类型以匹配BookInfo模型
                if 'year' in data and data['year'] is not None:
                    data['year'] = str(data['year'])
                if 'pages' in data and data['pages'] is not None:
                    data['pages'] = str(data['pages'])
                if 'rating' in data and data['rating'] is not None:
                    data['rating'] = str(data['rating'])
                if 'awards' in data and data['awards'] is not None:
                    if isinstance(data['awards'], list):
                        data['awards'] = ', '.join(data['awards'])
                    else:
                        data['awards'] = str(data['awards'])
                
                return data
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

def format_book_response(book_info) -> Dict[str, Any]:
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

def sanitize_input(text: str) -> str:
    """清理用户输入"""
    if not text:
        return ""
    
    # 移除潜在的恶意字符
    text = re.sub(r'[<>"\']', '', text)
    
    # 限制长度
    if len(text) > 1000:
        text = text[:1000]
    
    return text.strip()

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