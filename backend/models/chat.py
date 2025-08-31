from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class MessageType(str, Enum):
    """消息类型枚举"""
    QUESTION = "question"
    ANSWER = "answer"
    BOOK_INFO = "book_info"

class ChatMessage(BaseModel):
    """聊天消息模型"""
    id: Optional[str] = Field(None, description="消息ID")
    session_id: str = Field(..., description="会话ID")
    content: str = Field(..., description="消息内容")
    type: MessageType = Field(..., description="消息类型")
    timestamp: datetime = Field(default_factory=datetime.now, description="时间戳")
    metadata: Optional[Dict[str, Any]] = Field(None, description="元数据")

class ChatSession(BaseModel):
    """聊天会话模型"""
    id: Optional[str] = Field(None, description="会话ID")
    book_name: Optional[str] = Field(None, description="书籍名称")
    book_info: Optional[Dict[str, Any]] = Field(None, description="书籍信息")
    title: str = Field(..., description="会话标题")
    created_at: datetime = Field(default_factory=datetime.now, description="创建时间")
    updated_at: datetime = Field(default_factory=datetime.now, description="更新时间")
    message_count: int = Field(0, description="消息数量")
    is_active: bool = Field(True, description="是否活跃")

class SessionCreateRequest(BaseModel):
    """创建会话请求"""
    title: str = Field(..., description="会话标题")
    book_name: Optional[str] = Field(None, description="书籍名称")

class SessionUpdateRequest(BaseModel):
    """更新会话请求"""
    title: Optional[str] = Field(None, description="会话标题")
    book_name: Optional[str] = Field(None, description="书籍名称")
    book_info: Optional[Dict[str, Any]] = Field(None, description="书籍信息")
    is_active: Optional[bool] = Field(None, description="是否活跃")

class SessionListResponse(BaseModel):
    """会话列表响应"""
    sessions: List[ChatSession]
    total: int

class MessageHistoryRequest(BaseModel):
    """消息历史请求"""
    session_id: str = Field(..., description="会话ID")
    limit: Optional[int] = Field(50, description="限制数量")
    offset: Optional[int] = Field(0, description="偏移量")

class MessageHistoryResponse(BaseModel):
    """消息历史响应"""
    messages: List[ChatMessage]
    total: int
    session_id: str

class QARequestWithSession(BaseModel):
    """带会话的问答请求"""
    session_id: str = Field(..., description="会话ID")
    question: str = Field(..., description="问题")
    book_name: Optional[str] = Field(None, description="书籍名称")

class DeleteSessionRequest(BaseModel):
    """删除会话请求"""
    session_id: str = Field(..., description="会话ID")