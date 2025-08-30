import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    """应用配置"""
    
    # 基础配置
    app_name: str = Field(default="AI Book Assistant Backend", env="APP_NAME")
    app_version: str = Field(default="1.0.0", env="APP_VERSION")
    debug: bool = Field(default=False, env="DEBUG")
    
    # 服务器配置
    host: str = Field(default="0.0.0.0", env="HOST")
    port: int = Field(default=8000, env="PORT")
    
    # Google API配置
    google_api_key: Optional[str] = Field(default=None, env="GOOGLE_API_KEY")
    gemini_model: str = Field(default="gemini-2.0-flash", env="GEMINI_MODEL")
    
    # 日志配置
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_file: str = Field(default="app.log", env="LOG_FILE")
    
    # CORS配置
    cors_origins: list = Field(default=["*"], env="CORS_ORIGINS")
    cors_allow_credentials: bool = Field(default=True, env="CORS_ALLOW_CREDENTIALS")
    cors_allow_methods: list = Field(default=["*"], env="CORS_ALLOW_METHODS")
    cors_allow_headers: list = Field(default=["*"], env="CORS_ALLOW_HEADERS")
    
    # 缓存配置
    cache_enabled: bool = Field(default=True, env="CACHE_ENABLED")
    cache_ttl: int = Field(default=3600, env="CACHE_TTL")  # 1小时
    
    # API限制配置
    rate_limit_enabled: bool = Field(default=True, env="RATE_LIMIT_ENABLED")
    rate_limit_requests: int = Field(default=100, env="RATE_LIMIT_REQUESTS")
    rate_limit_window: int = Field(default=60, env="RATE_LIMIT_WINDOW")  # 秒
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "allow"

    @property
    def gemini_model_options(self) -> dict:
        """Gemini模型选项"""
        return {
            "2.5-pro": "gemini-2.5-pro",
            "2.5-flash": "gemini-2.5-flash",
            "2.0-flash": "gemini-2.0-flash",
            "2.0-thinking-exp": "gemini-2.0-flash-thinking-exp-01-21",
        }
    
    def validate_settings(self) -> list:
        """验证配置"""
        errors = []
        
        if not self.google_api_key:
            errors.append("GOOGLE_API_KEY is required")
        
        if self.gemini_model not in self.gemini_model_options.values():
            errors.append(f"Invalid GEMINI_MODEL: {self.gemini_model}")
        
        if not (1 <= self.port <= 65535):
            errors.append("PORT must be between 1 and 65535")
        
        if self.rate_limit_requests <= 0:
            errors.append("RATE_LIMIT_REQUESTS must be positive")
        
        return errors

# 全局配置实例
settings = Settings()

# 验证配置
if settings.debug:
    validation_errors = settings.validate_settings()
    if validation_errors:
        print("Configuration errors:")
        for error in validation_errors:
            print(f"  - {error}")
        if not settings.debug:
            raise ValueError("Invalid configuration")