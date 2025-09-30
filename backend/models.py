from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    TIMESTAMP,
    Enum as SQLAlchemyEnum,
    ForeignKey,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from database import Base
import enum




class FeedbackType(enum.Enum):
    like = "like"
    dislike = "dislike"


class Book(Base):
    __tablename__ = "books"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    input_title = Column(String(255))
    author = Column(String(255))
    introduction = Column(Text)
    report = Column(Text)
    created_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    __table_args__ = ({"schema": "public"},)


class QAMessage(Base):
    __tablename__ = "qa_messages"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    author = Column(String(255))
    request_payload = Column(JSONB, nullable=False)
    response_payload = Column(JSONB, nullable=False)
    created_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = ({"schema": "public"},)


class Feedback(Base):
    __tablename__ = "feedback"
    id = Column(Integer, primary_key=True, index=True)
    type = Column(SQLAlchemyEnum(FeedbackType, name="feedback_type"), nullable=False)
    request_payload = Column(JSONB, nullable=False)
    created_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = ({"schema": "public"},)


class APIRequestLog(Base):
    __tablename__ = "api_request_logs"
    id = Column(Integer, primary_key=True, index=True)
    method = Column(String(10), nullable=False)
    path = Column(String(255), nullable=False)
    request_body = Column(JSONB)
    status_code = Column(Integer, nullable=False)
    response_body = Column(JSONB)
    response_time_ms = Column(Integer, nullable=False)
    created_at = Column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = ({"schema": "public"},)
