import os
import logging
import asyncio
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

            response = await asyncio.to_thread(
                self.client.generate_content,
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
            response = await asyncio.to_thread(
                self.client.generate_content,
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
            response = await asyncio.to_thread(
                self.client.generate_content,
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
    
    
    async def generate_detailed_report(self, book_name: str, author: Optional[str] = None) -> Optional[str]:
        """生成详细的书籍报告"""
        try:
            # 为了速度，我们使用 gemini-2.5-flash 模型来生成报告
            pro_model_name = self.model_options.get("2.5-flash", "gemini-2.5-flash")
            pro_client = genai.GenerativeModel(pro_model_name)

            prompt = self._build_detailed_report_prompt(book_name, author)

            # 为长篇报告生成特定配置
            config = GenerationConfig(
                temperature=0.4,
                max_output_tokens=8192  # 增加Token上限以生成详细报告
            )

            # 调用Gemini API
            response = await asyncio.to_thread(
                pro_client.generate_content,
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

            logger.error(f"未能为书籍生成详细报告：{book_name}")
            return "生成详细报告失败，请稍后再试。"

        except Exception as e:
            logger.error(f"生成详细报告时出错：{str(e)}")
            return f"生成报告时发生错误: {str(e)}"

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
    

    def _build_detailed_report_prompt(self, book_name: str, author: Optional[str] = None) -> str:
        """构建生成详细书籍报告的提示词"""
        author_info = f"作者：{author}" if author else ""
        return f"""我希望你扮演一位深刻的书籍分析专家，运用你的专业知识和洞察力，为我剖析一本书。请根据文末提供的书籍信息，生成一份极其详尽且富有深度的分析报告。

**报告的核心目标是：** 彻底挖掘并清晰阐释书籍的**核心洞见**与**主要观点**，同时全面覆盖其他重要分析维度。

请在报告中包含以下方面的内容，并确保分析的深度和广度：

1.  **基本信息：**
    *   作者简介：深入介绍作者的学术/创作背景、知识体系、写作风格特点、所属流派或领域。提及可能深刻影响本书创作的其他关键作品、人生经历或思想转变。
    *   出版信息：首次出版的确切时间与背景。
    *   书籍分类：精准定位本书所属的大类（如社科、哲学、文学、历史、科普、心理学、传记等），并尽可能细化至具体子领域（如社科中的批判理论、人类学民族志；文学中的魔幻现实主义、成长小说等）。

2.  **核心内容精粹：**
    *   **（重点）** 提纲挈领地概述全书探讨的核心议题、试图解答的关键问题或（若是小说）驱动情节发展的核心冲突与脉络。
    *   梳理全书的宏观结构（如章节安排、逻辑递进关系、叙事框架），点明各主要部分的关键内容和功能。

3.  **【重中之重】核心洞见与主要观点深度剖析：**
    *   **（极其重点）** **集中火力、不吝篇幅地**分析和提炼书中提出的**最核心、最具原创性、最具启发性的深刻洞见和关键论断**。作者通过本书究竟想向世界传达什么根本性的信息？
    *   详细阐述这些核心观点是如何被论证的？作者运用了哪些证据、逻辑或叙事技巧来支撑它们？
    *   这些观点的新颖性、颠覆性或深刻性体现在何处？它们挑战了哪些传统认知或流行观念？
    *   （如果是小说）深入解读其核心主题（如爱、死亡、自由、正义等）、反复出现的象征意象、人物弧光背后揭示的人性或社会现实。

4.  **关键概念与理论框架解读：**
    *   识别并透彻解释书中反复出现、或对理解核心观点至关重要的**独特概念、术语、理论模型或分析框架**。
    *   阐明这些概念的精确内涵、来源（是作者原创、借用还是批判性发展？），以及它们在构建全书论证体系或叙事世界中的核心作用。

5.  **书中名言警句/精彩摘录：**
    *   精选书中**最能体现核心思想、语言精辟、发人深省或极具代表性**的名言警句、经典段落。
    *   摘录原文，并可选择性地附上简要的语境说明或意义解读，以展现其精华所在。

6.  **书籍评价、争议与深远影响：**
    *   客观总结本书在学术界、评论界及不同读者群体中的主流评价，务必包含**赞誉和批评**两方面的主要声音。
    *   本书自问世以来，在思想界、特定学科领域、社会文化层面或后续创作中引发了哪些具体而重要的影响？（例如：开创了新的研究范式、引发了重大社会讨论、成为某领域的奠基之作、被广泛引用、获得重大奖项等）。
    *   是否存在围绕本书的著名争议、重要的学术辩论或持续的批评焦点？具体内容是什么？
    *   时效性与现代审视： 根据最新的科学研究、学术进展或社会观念变迁，评估本书内容的时代局限性。明确指出书中是否有观点因后续发展而被认为过时、存在错误，或者需要进行补充、修正和批判性看待？

7.  **阅读策略与进阶建议：**
    *   为渴望深度理解本书的读者提供具体的阅读方法建议：需要哪些学科背景或知识储备？阅读时应特别留意哪些线索或论证层次？适合快速把握脉络还是需要字斟句酌地精读？推荐采用何种笔记法（如思维导图、章节摘要、概念卡片）？
    *   推荐哪些有助于加深理解的辅助阅读材料？（如：作者的其他著作、相关的学术论文、评论文章、纪录片、访谈、同一主题的其他经典书籍等）。

8.  **目标读者画像：**
    *   清晰描绘本书最适合的读者群体特征：是专业研究者、高校学生、特定行业从业人员、对特定议题有浓厚兴趣的公众读者，还是寻求特定情感共鸣或人生启迪的读者？
    *   阅读本书可能需要读者具备哪些先验的知识基础、思维能力或兴趣偏好？

9.  **同类书比较与独特定位：**
    *   列举若干本探讨相似主题、领域或体裁的重要书籍。
    *   **着重对比分析**：本书与这些同类书籍相比，在核心观点、研究方法、论证风格、叙事策略、材料选择、结论或整体基调上有哪些**显著的异同**？本书的独特性和不可替代的价值体现在哪里？

请确保你的分析报告展现出真正的专家水准：**洞察深刻、论证严谨、信息翔실、结构清晰、语言精练且富有启发性。**

**重要提示**：请确保您的整个回复都使用纯文本格式，避免使用任何Markdown语法（例如，不要使用`#`、`*`、`-`、`>`或代码块）来格式化您的回答。请使用自然的段落分隔来组织内容。

如果书籍信息不足或无法进行详细分析，请在报告开头明确说明原因。


---
**需要分析的书籍信息：**
书名：{book_name}
{author_info}
"""

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
