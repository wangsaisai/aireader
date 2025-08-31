from typing import Optional, List
from pydantic import BaseModel, Field

class BookInfo(BaseModel):
    """书籍信息数据模型"""
    title: str = Field(..., description="书籍标题")
    author: Optional[str] = Field(None, description="作者")
    publisher: Optional[str] = Field(None, description="出版社")
    year: Optional[str] = Field(None, description="出版年份")
    isbn: Optional[str] = Field(None, description="ISBN号")
    description: Optional[str] = Field(None, description="书籍简介")
    summary: Optional[str] = Field(None, description="内容摘要")

class QARequest(BaseModel):
    """问答请求数据模型"""
    book_name: str = Field(..., description="书籍名称")
    question: str = Field(..., description="用户问题")

class QAResponse(BaseModel):
    """问答响应数据模型"""
    answer: str = Field(..., description="AI回答")

class BookInfoRequest(BaseModel):
    """书籍信息请求数据模型"""
    book_name: str = Field(..., description="书籍名称")

class APIResponse(BaseModel):
    """通用API响应模型"""
    success: bool = Field(..., description="请求是否成功")
    data: Optional[dict] = Field(None, description="响应数据")
    error: Optional[str] = Field(None, description="错误信息")
    message: Optional[str] = Field(None, description="响应消息")

class GenerateReportRequest(BaseModel):
    """生成详细报告请求数据模型"""
    book_name: str = Field(..., description="书籍名称")
    author: Optional[str] = Field(None, description="作者名称")

class GenerateReportResponse(BaseModel):
    """生成详细报告响应数据模型"""
    report: str = Field(..., description="生成的详细书籍报告")
