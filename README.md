# AIReader — AI 读书助手

> 基于 Google Gemini 的智能读书助手，支持书籍信息查询、多轮智能问答与会话历史管理。  
> An AI-powered book assistant built on Google Gemini, featuring book info lookup, multi-turn Q&A, and session history.

---

## 目录 / Table of Contents

- [项目概述 / Overview](#项目概述--overview)
- [功能特性 / Features](#功能特性--features)
- [系统架构 / Architecture](#系统架构--architecture)
- [技术栈 / Tech Stack](#技术栈--tech-stack)
- [目录结构 / Directory Structure](#目录结构--directory-structure)
- [快速开始 / Quick Start](#快速开始--quick-start)
  - [后端 / Backend](#后端--backend)
  - [HarmonyOS 应用](#harmonyos-应用)
  - [Android 应用](#android-应用)
- [API 文档 / API Reference](#api-文档--api-reference)
- [应用截图 / Screenshots](#应用截图--screenshots)
- [贡献指南 / Contributing](#贡献指南--contributing)
- [许可证 / License](#许可证--license)

---

## 项目概述 / Overview

AIReader 是一个跨平台的 AI 读书助手，帮助用户快速获取书籍信息并与 AI 进行深度交流。用户输入书名后，AI 会返回书籍详细介绍，并支持多轮对话问答，回答一切与该书相关的问题。

AIReader is a cross-platform AI book assistant. Users enter a book title to instantly get rich book information and then engage in multi-turn conversations with the AI about that book.

---

## 功能特性 / Features

| 功能 | 说明 |
|------|------|
| 📚 书籍信息查询 | 输入书名自动获取作者、出版社、ISBN、简介、内容概述 |
| 🤖 多轮智能问答 | 基于完整对话历史与 AI 进行连续问答 |
| 📝 一键生成书籍报告 | 获取书籍信息后，一键生成详细分析报告 |
| 💾 会话持久化 | 使用系统存储保存会话，重启后自动恢复 |
| 🎨 Markdown 渲染 | AI 回复支持标题、列表、代码块、粗体/斜体等富文本格式 |
| 👍 用户反馈 | 对 AI 回复进行「赞」/「踩」，并可提交详细举报 |
| 🌐 多语言支持 | 简体中文、繁体中文、英文 |
| 📱 双端应用 | HarmonyOS（ArkTS）与 Android（Kotlin + Compose）同步支持 |

---

## 系统架构 / Architecture

```
┌─────────────────────┐    HTTP/JSON    ┌──────────────────────┐    SDK    ┌─────────────────┐
│   HarmonyOS App     │ ◄─────────────► │   Backend (FastAPI)  │ ◄────────► │  Google Gemini  │
│   Android App       │                 │   Python 3.8+        │           │      API        │
└─────────────────────┘                 └──────────────────────┘           └─────────────────┘
        │                                          │
   ArkTS / Kotlin                        PostgreSQL Database
   ArkUI / Jetpack Compose               (Request Logging)
```

### 数据流 / Data Flow

```
1. 用户输入书名
2. App 发送 POST /api/book/info
3. 后端调用 Gemini API 获取书籍信息
4. 返回结构化 JSON 给 App 展示
5. 用户提问 → POST /api/chat/ask（含对话历史）
6. Gemini 基于上下文生成回答
7. App 渲染 Markdown 格式回复
```

---

## 技术栈 / Tech Stack

### 后端 / Backend
| 组件 | 版本 |
|------|------|
| Python | 3.8+ |
| FastAPI | 0.104.1 |
| Google Generative AI SDK | 0.8.3 |
| SQLAlchemy (async) | 2.0.23 |
| PostgreSQL (asyncpg) | 0.29.0 |
| Pydantic | 2.8.2 |
| Uvicorn | 0.24.0 |

### HarmonyOS 前端
| 组件 | 说明 |
|------|------|
| HarmonyOS | 4.0+ |
| ArkTS / ArkUI | 声明式 UI 框架 |
| @ohos.net.http | 网络请求 |
| Preferences API | 数据持久化 |

### Android 前端
| 组件 | 说明 |
|------|------|
| Kotlin | 主开发语言 |
| Jetpack Compose | 声明式 UI |
| Coroutines / Flow | 异步处理 |
| MVVM | 应用架构 |

---

## 目录结构 / Directory Structure

```
aireader/
├── backend/                  # Python FastAPI 后端
│   ├── main.py               # 应用入口
│   ├── api/
│   │   ├── routes.py         # API 路由
│   │   └── schemas.py        # 请求/响应数据模型
│   ├── services/
│   │   ├── gemini_service.py # Gemini AI 服务封装
│   │   └── book_service.py   # 书籍业务逻辑
│   ├── config/
│   │   └── settings.py       # 配置管理
│   ├── utils/
│   │   └── helpers.py        # 工具函数
│   ├── database.py           # 数据库连接
│   ├── models.py             # ORM 数据模型
│   ├── requirements.txt      # Python 依赖
│   └── .env.example          # 环境变量示例
│
├── aireader_hm/              # HarmonyOS 应用（ArkTS）
│   └── entry/src/main/ets/
│       ├── pages/
│       │   └── Index.ets     # 主页面
│       ├── components/
│       │   ├── QAComponent.ets          # 聊天消息组件
│       │   ├── MarkdownRenderer.ets     # Markdown 渲染器
│       │   ├── LoadingComponent.ets     # 加载动画组件
│       │   └── SessionListComponent.ets # 会话列表组件
│       ├── services/
│       │   ├── ApiService.ets           # 网络请求服务
│       │   ├── StorageManager.ets       # 数据持久化管理
│       │   └── ClientSessionManager.ets # 会话管理器
│       └── model/
│           ├── BookInfo.ets             # 书籍信息模型
│           ├── QAMessage.ets            # 消息模型
│           └── ChatModels.ets           # 对话记忆模型
│
├── android/                  # Android 应用（Kotlin + Compose）
├── resources/                # 应用截图等资源
├── architecture.md           # 详细架构文档
├── requirements.md           # 需求文档
└── README.md                 # 本文件
```

---

## 快速开始 / Quick Start

### 后端 / Backend

**前置条件 / Prerequisites**
- Python 3.8+
- PostgreSQL（可选，用于请求日志记录）
- Google Gemini API Key（[申请地址](https://aistudio.google.com/app/apikey)）

**安装步骤 / Installation**

```bash
# 1. 进入后端目录
cd backend

# 2. 安装依赖
pip install -r requirements.txt

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env，填入你的 GOOGLE_API_KEY 和数据库连接信息

# 4. 启动服务
uvicorn main:app --host 0.0.0.0 --port 8000
```

服务启动后访问 `http://localhost:8000` 确认运行状态。  
调试模式下可访问 `http://localhost:8000/docs` 查看交互式 API 文档。

**主要环境变量 / Key Environment Variables**

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `GOOGLE_API_KEY` | Google Gemini API 密钥 | `AIza...` |
| `GEMINI_MODEL` | 使用的模型 | `gemini-2.0-flash` |
| `HOST` | 服务器监听地址 | `0.0.0.0` |
| `PORT` | 服务器端口 | `8000` |
| `DEBUG` | 调试模式 | `false` |
| `DATABASE_URL` | PostgreSQL 连接串（可选） | `postgresql+asyncpg://...` |

---

### HarmonyOS 应用

**前置条件 / Prerequisites**
- DevEco Studio（最新版）
- HarmonyOS SDK 4.0+

**安装步骤 / Installation**

1. 使用 DevEco Studio 打开 `aireader_hm/` 目录。
2. 等待 Gradle / hvigor 同步完成。
3. 修改 `entry/src/main/ets/services/ApiService.ets` 中的 `BASE_URL`，指向你的后端地址。
4. 连接设备或启动模拟器，点击运行。

---

### Android 应用

**前置条件 / Prerequisites**
- Android Studio（最新版）
- Android SDK

**安装步骤 / Installation**

1. 使用 Android Studio 打开 `android/` 目录。
2. 等待 Gradle 同步完成。
3. 默认后端地址为 `http://10.0.2.2:8000`（模拟器访问本机 localhost）。如需修改，请更新应用中的 base URL 配置。
4. 运行到模拟器或真机。

---

## API 文档 / API Reference

所有接口返回统一格式：

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### `POST /api/book/info` — 获取书籍信息

```json
// 请求 Request
{
  "book_name": "三体",
  "author": "刘慈欣"  // 可选 optional
}

// 响应 Response
{
  "success": true,
  "data": {
    "title": "三体",
    "author": "刘慈欣",
    "publisher": "重庆出版社",
    "year": "2008",
    "isbn": "978-7-536-69293-0",
    "description": "...",
    "summary": "..."
  }
}
```

### `POST /api/chat/ask` — 多轮智能问答

```json
// 请求 Request
{
  "book_name": "三体",
  "question": "这本书的主要主题是什么？",
  "messages": [
    { "role": "user", "content": "你好" },
    { "role": "assistant", "content": "你好！有什么关于《三体》的问题？" }
  ]
}

// 响应 Response
{
  "success": true,
  "data": {
    "answer": "《三体》的核心主题是..."
  }
}
```

### `POST /api/chat/generate_report` — 一键生成书籍报告

```json
// 请求 Request
{ "book_name": "三体", "author": "刘慈欣" }

// 响应 Response
{ "success": true, "data": { "report": "# 《三体》深度分析报告\n..." } }
```

### `POST /api/like` — 点赞反馈

```json
{ "book_name": "三体", "message_content": "...", "like": true }
```

### `POST /api/complaint` — 举报/投诉

```json
{ "book_name": "三体", "message_content": "...", "reason": "内容不准确" }
```

### `GET /api/health` — 健康检查

```json
{ "success": true, "data": { "status": "healthy" } }
```

---

## 应用截图 / Screenshots

| 书籍查询 | 智能问答 | 会话列表 |
|:---:|:---:|:---:|
| ![书籍查询](resources/Screenshot_20250902213727747-图片裁剪-1260_2240.jpeg) | ![智能问答](resources/Screenshot_20250902213837147-图片裁剪-1260_2720.jpeg) | ![会话列表](resources/Screenshot_20250902214807109-图片裁剪-1260_2240.jpeg) |

---

## 贡献指南 / Contributing

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交变更：`git commit -m 'Add some feature'`
4. 推送分支：`git push origin feature/your-feature`
5. 提交 Pull Request

---

## 许可证 / License

本项目基于 [MIT License](LICENSE) 开源。
