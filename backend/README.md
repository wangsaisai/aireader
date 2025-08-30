# AI Book Assistant Backend

基于Google Gemini的AI读书助手后端服务。

## 功能特性

- 📚 书籍信息查询：根据书籍名称获取详细信息
- 🤖 智能问答：回答关于书籍内容的各种问题
- 🔍 搜索增强：集成Google搜索获取最新信息
- 🚀 高性能：异步处理，支持并发请求
- 🛡️ 安全可靠：输入验证，错误处理
- 📊 缓存优化：减少API调用，提高响应速度

## 快速开始

### 1. 安装依赖

```bash
cd backend
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入你的 Google API 密钥
```

### 3. 运行服务

```bash
python main.py
```

或使用 uvicorn：

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

## API 接口

### 书籍信息查询
```
POST /api/book/info
Content-Type: application/json

{
  "book_name": "三体"
}
```

### 书籍问答
```
POST /api/book/qa
Content-Type: application/json

{
  "book_name": "三体",
  "question": "这本书的主要主题是什么？"
}
```

### 健康检查
```
GET /api/health
```

### 缓存管理
```
GET /api/cache/stats      # 获取缓存统计
POST /api/cache/clear     # 清空缓存
```

## 配置说明

主要配置项：

- `GOOGLE_API_KEY`: Google Gemini API密钥
- `GEMINI_MODEL`: 使用的Gemini模型
- `HOST`: 服务器地址
- `PORT`: 服务器端口
- `DEBUG`: 调试模式
- `CACHE_ENABLED`: 是否启用缓存
- `RATE_LIMIT_ENABLED`: 是否启用请求限制

## 项目结构

```
backend/
├── main.py                 # 应用入口
├── api/
│   ├── __init__.py
│   ├── routes.py          # API路由
│   └── schemas.py         # 数据模型
├── services/
│   ├── __init__.py
│   ├── gemini_service.py  # Gemini AI服务
│   └── book_service.py    # 书籍处理服务
├── models/
│   ├── __init__.py
│   └── book.py           # 书籍数据模型
├── config/
│   ├── __init__.py
│   └── settings.py       # 配置管理
├── utils/
│   ├── __init__.py
│   └── helpers.py        # 工具函数
├── requirements.txt      # 依赖包
└── .env.example         # 环境变量示例
```

## 错误处理

服务包含完整的错误处理机制：

- 输入验证错误
- API调用错误
- 网络连接错误
- 配置验证错误
- 全局异常处理

## 开发说明

- 支持 FastAPI 自动文档生成（调试模式下）
- 完整的日志记录
- 配置验证和错误提示
- CORS跨域支持
- 依赖注入模式

## 许可证

MIT License