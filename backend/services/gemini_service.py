import os
import logging
from typing import Optional, Dict, Any
import google.generativeai as genai
from google.generativeai.types import GenerationConfig
from models.book import BookInfo
from utils.helpers import clean_json_response
from config.settings import settings

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GeminiBookInfoError(Exception):
    """Custom exception for when book info generation fails but we have a text response."""
    def __init__(self, message, raw_response=None):
        super().__init__(message)
        self.raw_response = raw_response

class GeminiService:
    """Google Gemini API服务封装"""
    
    def __init__(self, api_key: Optional[str] = None):
        """初始化Gemini服务"""
        self.api_key = api_key or settings.google_api_key or os.getenv('GOOGLE_API_KEY')
        if not self.api_key:
            raise ValueError("Google API key is required")
        
        genai.configure(api_key=self.api_key)
        self.model_name = "gemini-2.5-flash"  # 默认模型
        self.client = genai.GenerativeModel(self.model_name)
        
        # 可用模型选项
        self.model_options = {
            "2.5-pro": "gemini-2.5-pro",
            "2.5-flash": "gemini-2.5-flash",
            "2.0-flash": "gemini-2.0-flash",
            "2.0-thinking-exp": "gemini-2.0-flash-thinking-exp-01-21",
        }
    
    def set_model(self, model_key: str):
        """设置使用的模型"""
        if model_key in self.model_options:
            self.model_name = self.model_options[model_key]
            self.client = genai.GenerativeModel(self.model_name)
        else:
            raise ValueError(f"Invalid model key: {model_key}")
    
    async def generate_book_info(self, book_name: str) -> Optional[BookInfo]:
        """生成书籍信息"""
        content_text = f"No valid response from Gemini for book: {book_name}"  # Default error
        try:
            prompt = self._build_book_info_prompt(book_name)

            config = GenerationConfig(
                temperature=0.3,
                max_output_tokens=4000
            )

            response = self.client.generate_content(
                contents=prompt,
                generation_config=config
            )

            if response and hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and candidate.content:
                    raw_text = ''.join(part.text for part in candidate.content.parts if hasattr(part, 'text'))
                    if raw_text:
                        content_text = raw_text  # Update with actual response

                    book_data = clean_json_response(content_text)
                    if book_data:
                        # If the AI reports the book is not found but omits the title,
                        # we'll inject the user's query as the title to satisfy validation.
                        if book_data.get('is_found') is False and book_data.get('title') is None:
                            book_data['title'] = book_name
                        return BookInfo(**book_data) # Always return the object

            # If we reach here, something went wrong with the API call itself.
            logger.error(f"Failed to generate valid content for book: {book_name}")
            # Return a "not found" object as a fallback.
            return BookInfo(
                title=book_name,
                is_found=False,
                not_found_reason="AI service failed to produce a valid response."
            )

        except Exception as e:
            logger.error(f"Unexpected error in generate_book_info: {str(e)}")
            return BookInfo(
                title=book_name,
                is_found=False,
                not_found_reason=f"An unexpected error occurred: {str(e)}"
            )
    
    async def answer_question(self, book_name: str, question: str) -> Optional[str]:
        """回答关于书籍的问题"""
        try:
            prompt = self._build_qa_prompt(book_name, question)
            
            # 生成配置
            config = GenerationConfig(
                temperature=0.5,
                max_output_tokens=2000
            )
            
            # 调用Gemini API
            response = self.client.generate_content(
                contents=prompt,
                generation_config=config
            )
            
            # 解析响应
            if response and hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and candidate.content:
                    return ''.join(
                        part.text for part in candidate.content.parts 
                        if hasattr(part, 'text')
                    )
            
            logger.error(f"Failed to generate answer for question: {question}")
            return None
            
        except Exception as e:
            logger.error(f"Error answering question: {str(e)}")
            return None
    
    async def answer_question_with_context(self, book_name: str, question: str, context: str = "") -> Optional[str]:
        """回答关于书籍的问题（带对话上下文）"""
        try:
            prompt = self._build_qa_prompt_with_context(book_name, question, context)
            
            # 生成配置
            config = GenerationConfig(
                temperature=0.5,
                max_output_tokens=2000
            )
            
            # 调用Gemini API
            response = self.client.generate_content(
                contents=prompt,
                generation_config=config
            )
            
            # 解析响应
            if response and hasattr(response, 'candidates') and response.candidates:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and candidate.content:
                    return ''.join(
                        part.text for part in candidate.content.parts 
                        if hasattr(part, 'text')
                    )
            
            logger.error(f"Failed to generate answer for question with context: {question}")
            return None
            
        except Exception as e:
            logger.error(f"Error answering question with context: {str(e)}")
            return None
    
    def _build_book_info_prompt(self, book_name: str) -> str:
        """构建书籍信息查询提示词"""
        return f"""你是一个专业的图书信息查询助手。请根据用户提供的书籍名称，通过搜索获取该书籍的完整详细信息。

请以JSON格式返回结果，包含以下字段：
- title: 书籍标题（完整准确的书名）
- author: 作者（所有作者，用逗号分隔）
- publisher: 出版社（出版社名称）
- year: 出版年份（首次出版年份）
- isbn: ISBN号（13位ISBN，如果没有则为null）
- description: 书籍简介（详细的书籍介绍，200-300字）
- summary: 内容摘要（书籍主要内容和主题概述，300-500字）
- genre: 类型/分类（如：科幻、小说、历史等）
- pages: 页数（书籍总页数）
- language: 语言（书籍的原语言）
- rating: 评分（如果有的话，0-5分）
- awards: 获奖情况（获得的重要奖项）
- is_found: 布尔值，表示是否成功找到书籍
- not_found_reason: 如果未找到书籍，请说明原因（例如：书籍不存在、名称不明确有多种可能等）

书籍名称：{book_name}

要求：
1. 无论是否找到书籍，都必须返回is_found字段
2. 如果is_found为false，则必须在not_found_reason中提供解释，其他字段可以为null
3. 请通过搜索获取最新、最准确的书籍信息
4. 确保信息完整，特别是description和summary字段要详细
5. 如果某些信息确实无法获取，请将对应字段设为null
6. 返回格式必须是严格有效的JSON，不要包含任何其他文字说明
7. year字段必须是字符串格式

请开始搜索并整理信息："""
    
    def _build_qa_prompt(self, book_name: str, question: str) -> str:
        """构建问答提示词"""
        return f"""你是一个专业的图书阅读助手，专门回答关于书籍内容的问题。

书籍名称：{book_name}
用户问题：{question}

请基于这本书的内容和相关信息，准确、详细地回答用户的问题。如果信息不足，请说明需要更多信息。
回答要清晰易懂，结构合理。

重要提示：请确保您的整个回复都使用纯文本格式，避免使用任何Markdown语法（例如，不要使用`#`、`*`、`-`、`>`或代码块）来格式化您的回答。请使用自然的段落分隔来组织内容。"""
    
    def _build_qa_prompt_with_context(self, book_name: str, question: str, context: str) -> str:
        """构建带上下文的问答提示词"""
        context_section = f"""
对话历史：
{context}

""" if context.strip() else ""
        
        return f"""你是一个专业的图书阅读助手，专门回答关于书籍内容的问题。{context_section}书籍名称：{book_name}
用户问题：{question}

请基于这本书的内容和相关信息，准确、详细地回答用户的问题。回答时要考虑之前的对话历史，保持连贯性和上下文关联性。
如果信息不足，请说明需要更多信息。
回答要清晰易懂，结构合理。

重要提示：请确保您的整个回复都使用纯文本格式，避免使用任何Markdown语法（例如，不要使用`#`、`*`、`-`、`>`或代码块）来格式化您的回答。请使用自然的段落分隔来组织内容。"""
    
    def _handle_api_error(self, error: Exception) -> str:
        """处理API错误"""
        error_msg = str(error)
        if "API key" in error_msg:
            return "API密钥无效或已过期"
        elif "quota" in error_msg.lower():
            return "API配额已用完"
        elif "network" in error_msg.lower():
            return "网络连接错误"
        else:
            return f"API调用失败: {error_msg}"