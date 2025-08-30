# AI读书项目需求说明书

## 项目概述

开发一个AI驱动的读书助手项目，包含后端服务和鸿蒙移动应用。用户可以通过应用提供书籍信息，获取书籍详细信息，并与AI进行书籍相关的问答。

## 系统架构

### 1. 后端服务
- **技术栈**: Python + FastAPI/Flask
- **AI模型**: Google Gemini
- **主要功能**: 
  - 接收书籍信息查询请求
  - 调用Google Gemini API获取书籍相关信息
  - 处理用户关于书籍的问答请求
  - 返回结构化的JSON响应

### 2. 鸿蒙应用
- **开发平台**: HarmonyOS
- **开发语言**: ArkTS/eTS
- **主要功能**:
  - 用户界面：书籍信息输入
  - 显示书籍详细信息
  - 问答交互界面
  - 与后端服务通信

## 功能需求

### 2.1 后端服务功能

#### 2.1.1 书籍信息查询
- **接口**: `POST /api/book/info`
- **输入**: 书籍名称（字符串）
- **输出**: 书籍详细信息（JSON格式）
  - 书名
  - 作者
  - 出版社
  - 出版年份
  - ISBN
  - 简介
  - 主要内容概述

#### 2.1.2 书籍问答
- **接口**: `POST /api/book/qa`
- **输入**: 
  - 书籍名称（字符串）
  - 用户问题（字符串）
- **输出**: AI回答（字符串）

#### 2.1.3 AI集成
- 集成Google Gemini API
- 处理API调用和错误处理
- 管理API密钥和配额

### 2.2 鸿蒙应用功能

#### 2.2.1 主界面
- 书籍名称输入框
- 查询按钮
- 书籍信息展示区域
- 问答输入框
- 发送按钮
- 问答历史记录显示

#### 2.2.2 书籍信息展示
- 结构化显示书籍详细信息
- 支持滚动查看长内容
- 清晰的信息布局

#### 2.2.3 问答交互
- 实时显示用户问题和AI回答
- 支持多轮对话
- 问答历史记录保存（仅当前会话）

## 技术要求

### 3.1 后端技术要求
- Python 3.8+
- FastAPI 或 Flask 框架
- Google Gemini API SDK
- HTTP/HTTPS 支持
- JSON 数据格式
- CORS 支持（用于跨域请求）

### 3.2 鸿蒙应用技术要求
- HarmonyOS 3.0+
- ArkTS/eTS 开发语言
- Stage 模型开发
- 网络请求能力
- UI 组件开发
- JSON 数据解析

## 接口规范

### 4.1 书籍信息查询接口
```
POST /api/book/info
Content-Type: application/json

Request:
{
  "book_name": "string"
}

Response:
{
  "success": true,
  "data": {
    "title": "string",
    "author": "string",
    "publisher": "string",
    "year": "string",
    "isbn": "string",
    "description": "string",
    "summary": "string"
  },
  "error": null
}
```

### 4.2 书籍问答接口
```
POST /api/book/qa
Content-Type: application/json

Request:
{
  "book_name": "string",
  "question": "string"
}

Response:
{
  "success": true,
  "data": {
    "answer": "string"
  },
  "error": null
}
```

## 数据流

1. 用户在鸿蒙应用中输入书籍名称
2. 应用发送请求到后端服务
3. 后端调用Google Gemini API获取书籍信息
4. 后端返回书籍详细信息给应用
5. 用户在应用中查看书籍信息并提问
6. 应用发送问答请求到后端
7. 后端调用Gemini API生成回答
8. 后端返回回答给应用显示

## 非功能需求

### 5.1 性能要求
- API响应时间 < 3秒
- 应用启动时间 < 2秒
- 支持并发用户数 > 10

### 5.2 可用性要求
- 后端服务可用性 > 95%
- 应用崩溃率 < 1%

### 5.3 安全要求
- API密钥安全存储
- HTTPS加密传输
- 输入数据验证

## 开发限制

### 6.1 范围限制
- 不包含用户注册/登录功能
- 不包含数据库存储
- 不包含用户数据持久化
- 不包含书籍推荐系统
- 不包含社交功能

### 6.2 Demo版本特性
- 基础功能实现
- 简洁的用户界面
- 核心AI交互功能
- 错误处理和提示

## 部署要求

### 7.1 后端部署
- 云服务器或本地开发环境
- Python环境配置
- Google Gemini API密钥配置
- 防火墙端口配置

### 7.2 应用部署
- HarmonyOS开发者账号
- 应用签名配置
- 测试设备或模拟器

## 测试策略

### 8.1 单元测试
- 后端API接口测试
- AI响应质量测试
- 应用UI组件测试

### 8.2 集成测试
- 端到端功能测试
- 网络请求测试
- 错误场景测试

## 风险评估

### 9.1 技术风险
- Google Gemini API限制
- 网络连接稳定性
- HarmonyOS开发复杂性

### 9.2 缓解措施
- API调用重试机制
- 网络错误处理
- 简化UI设计

## 项目里程碑

1. **第1周**: 后端服务开发完成
2. **第2周**: 鸿蒙应用基础界面完成
3. **第3周**: 应用功能集成完成
4. **第4周**: 测试和优化完成

## 附录

### A. 参考资源
- Google Gemini API文档
- HarmonyOS开发者文档
- FastAPI/Flask框架文档

### B. 开发环境
- Python开发工具
- DevEco Studio
- HarmonyOS SDK