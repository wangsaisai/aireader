import json
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime
from models.chat import ChatSession, ChatMessage, MessageType
from utils.helpers import generate_id

logger = logging.getLogger(__name__)

class ChatMemoryService:
    """对话记忆服务"""
    
    def __init__(self):
        # 使用内存存储，生产环境可替换为数据库
        self.sessions: Dict[str, ChatSession] = {}
        self.messages: Dict[str, List[ChatMessage]] = {}  # session_id -> messages
    
    def create_session(self, title: str, book_name: Optional[str] = None) -> ChatSession:
        """创建新会话"""
        session_id = generate_id()
        session = ChatSession(
            id=session_id,
            title=title,
            book_name=book_name,
            created_at=datetime.now(),
            updated_at=datetime.now(),
            message_count=0,
            is_active=True
        )
        
        self.sessions[session_id] = session
        self.messages[session_id] = []
        
        logger.info(f"Created new session: {session_id}")
        return session
    
    def get_session(self, session_id: str) -> Optional[ChatSession]:
        """获取会话"""
        return self.sessions.get(session_id)
    
    def get_all_sessions(self) -> List[ChatSession]:
        """获取所有会话"""
        return list(self.sessions.values())
    
    def get_active_sessions(self) -> List[ChatSession]:
        """获取活跃会话"""
        return [session for session in self.sessions.values() if session.is_active]
    
    def update_session(self, session_id: str, **kwargs) -> Optional[ChatSession]:
        """更新会话"""
        session = self.sessions.get(session_id)
        if not session:
            return None
        
        # 更新字段
        for key, value in kwargs.items():
            if hasattr(session, key):
                setattr(session, key, value)
        
        session.updated_at = datetime.now()
        return session
    
    def delete_session(self, session_id: str) -> bool:
        """删除会话"""
        if session_id in self.sessions:
            del self.sessions[session_id]
            if session_id in self.messages:
                del self.messages[session_id]
            logger.info(f"Deleted session: {session_id}")
            return True
        return False
    
    def add_message(self, session_id: str, content: str, message_type: MessageType, 
                   metadata: Optional[Dict[str, Any]] = None) -> Optional[ChatMessage]:
        """添加消息到会话"""
        if session_id not in self.sessions:
            return None
        
        message = ChatMessage(
            id=generate_id(),
            session_id=session_id,
            content=content,
            type=message_type,
            timestamp=datetime.now(),
            metadata=metadata
        )
        
        self.messages[session_id].append(message)
        
        # 更新会话信息
        session = self.sessions[session_id]
        session.message_count += 1
        session.updated_at = datetime.now()
        
        return message
    
    def get_session_messages(self, session_id: str, limit: Optional[int] = None, 
                           offset: Optional[int] = None) -> List[ChatMessage]:
        """获取会话消息"""
        messages = self.messages.get(session_id, [])
        
        # 按时间戳排序
        messages.sort(key=lambda x: x.timestamp)
        
        # 分页
        if offset is not None:
            messages = messages[offset:]
        if limit is not None:
            messages = messages[:limit]
        
        return messages
    
    def get_conversation_context(self, session_id: str, max_messages: int = 10) -> str:
        """获取对话上下文，用于AI生成回复"""
        messages = self.get_session_messages(session_id, limit=max_messages)
        
        if not messages:
            return ""
        
        # 构建对话历史
        context_parts = []
        for msg in messages:
            if msg.type == MessageType.QUESTION:
                context_parts.append(f"用户: {msg.content}")
            elif msg.type == MessageType.ANSWER:
                context_parts.append(f"助手: {msg.content}")
            elif msg.type == MessageType.BOOK_INFO:
                context_parts.append(f"书籍信息: {msg.content}")
        
        return "\n".join(context_parts)
    
    def update_session_book_info(self, session_id: str, book_name: str, book_info: Dict[str, Any]):
        """更新会话书籍信息"""
        session = self.sessions.get(session_id)
        if session:
            session.book_name = book_name
            session.book_info = book_info
            session.updated_at = datetime.now()
    
    def get_session_stats(self) -> Dict[str, Any]:
        """获取统计信息"""
        total_sessions = len(self.sessions)
        active_sessions = len([s for s in self.sessions.values() if s.is_active])
        total_messages = sum(len(msgs) for msgs in self.messages.values())
        
        return {
            "total_sessions": total_sessions,
            "active_sessions": active_sessions,
            "total_messages": total_messages,
            "sessions_per_book": self._get_sessions_per_book()
        }
    
    def _get_sessions_per_book(self) -> Dict[str, int]:
        """获取每本书的会话数量"""
        book_counts = {}
        for session in self.sessions.values():
            if session.book_name:
                book_counts[session.book_name] = book_counts.get(session.book_name, 0) + 1
        return book_counts
    
    def clear_all_data(self):
        """清空所有数据（仅用于测试）"""
        self.sessions.clear()
        self.messages.clear()
        logger.info("Cleared all chat data")