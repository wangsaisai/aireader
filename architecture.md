# AI读书项目架构文档

## 1. 系统总体架构

### 1.1 架构概览
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  HarmonyOS App │◄──►│   Backend API   │◄──►│  Google Gemini  │
│   (ArkTS/eTS)  │    │   (Python)      │    │      API        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Device   │    │   Cloud Server   │    │   AI Service    │
│  (Mobile/Pad)   │    │   (Compute)      │    │   (Inference)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1.2 技术栈选择

#### 前端技术栈
- **开发平台**: HarmonyOS 4.0+
- **开发语言**: ArkTS
- **UI框架**: ArkUI
- **网络库**: @ohos.net.http
- **数据格式**: JSON

#### 后端技术栈
- **开发语言**: Python 3.8+
- **Web框架**: FastAPI
- **AI集成**: Google Generative AI (genai)
- **HTTP客户端**: httpx
- **数据验证**: Pydantic
- **异步处理**: asyncio

## 2. 后端架构设计

### 2.1 目录结构
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
└── requirements.txt     # 依赖包
```

### 2.2 核心组件设计

#### 2.2.1 API层 (api/)
```python
# 路由设计
POST /api/book/info      # 获取书籍信息
POST /api/book/qa        # 书籍问答
GET  /api/health         # 健康检查
```

#### 2.2.2 服务层 (services/)
```python
class GeminiService:
    """Google Gemini API服务封装"""
    - generate_book_info(book_name: str) -> BookInfo
    - answer_question(book_name: str, question: str) -> str
    - handle_api_errors() -> ErrorHandling

class BookService:
    """书籍业务逻辑处理"""
    - validate_book_name(book_name: str) -> bool
    - format_book_response(gemini_response: str) -> BookInfo
    - cache_book_info(book_name: str, info: BookInfo) -> None
```

#### 2.2.3 数据模型 (models/)
```python
class BookInfo(BaseModel):
    """书籍信息数据模型"""
    title: str
    author: Optional[str] = None
    publisher: Optional[str] = None
    year: Optional[str] = None
    isbn: Optional[str] = None
    description: Optional[str] = None
    summary: Optional[str] = None

class QARequest(BaseModel):
    """问答请求数据模型"""
    book_name: str
    question: str

class QAResponse(BaseModel):
    """问答响应数据模型"""
    answer: str
```

### 2.3 数据流设计
```
Request Flow:
Client Request → FastAPI Router → Service Layer → Gemini API → Response Processing → Client

Error Handling Flow:
API Error → Service Error Handler → HTTP Exception → Client Error Response
```

## 3. 鸿蒙应用架构设计

### 3.1 目录结构
```
harmony-app/
├── entry/
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/
│   │   │   │   ├── entryability/
│   │   │   │   │   └── EntryAbility.ets
│   │   │   │   ├── pages/
│   │   │   │   │   ├── Index.ets          # 主页面
│   │   │   │   │   ├── BookInfoPage.ets   # 书籍信息页
│   │   │   │   │   └── QAPage.ets         # 问答页面
│   │   │   │   ├── model/
│   │   │   │   │   ├── BookInfo.ets       # 书籍信息模型
│   │   │   │   │   └── QAMessage.ets      # 问答消息模型
│   │   │   │   ├── services/
│   │   │   │   │   └── ApiService.ets     # 网络服务
│   │   │   │   ├── utils/
│   │   │   │   │   └── Logger.ets         # 日志工具
│   │   │   │   └── components/
│   │   │   │       ├── BookInfoComponent.ets
│   │   │   │       ├── QAComponent.ets
│   │   │   │       └── LoadingComponent.ets
│   │   │   └── resources/
│   │   │       ├── base/
│   │   │       │   ├── element/
│   │   │       │   ├── media/
│   │   │   │   └── profile/
│   │   │       └── rawfile/
```

### 3.2 页面架构设计

#### 3.2.1 主页面 (Index.ets)
```typescript
@Entry
@Component
struct Index {
  @State bookName: string = ''
  @State isLoading: boolean = false
  @State bookInfo: BookInfo | null = null
  
  build() {
    Column() {
      // 标题
      Text('AI读书助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      // 书籍输入区域
      TextInput({ placeholder: '请输入书籍名称' })
        .width('100%')
        .height(40)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.bookName = value
        })
      
      // 查询按钮
      Button('查询书籍信息')
        .width('100%')
        .height(50)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.queryBookInfo()
        })
      
      // 加载状态
      if (this.isLoading) {
        LoadingComponent()
      }
      
      // 书籍信息展示
      if (this.bookInfo) {
        BookInfoComponent({ bookInfo: this.bookInfo })
        Button('开始问答')
          .width('100%')
          .height(50)
          .margin({ top: 20 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/QAPage',
              params: { bookName: this.bookName }
            })
          })
      }
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}
```

#### 3.2.2 问答页面 (QAPage.ets)
```typescript
@Entry
@Component
struct QAPage {
  @State messages: QAMessage[] = []
  @State currentQuestion: string = ''
  @State isLoading: boolean = false
  private bookName: string = router.getParams()?.['bookName'] || ''
  
  build() {
    Column() {
      // 标题
      Text(`《${this.bookName}》问答`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      // 对话历史
      List() {
        ForEach(this.messages, (message: QAMessage) => {
          QAComponent({ message: message })
        })
      }
      .layoutWeight(1)
      .width('100%')
      
      // 输入区域
      Row() {
        TextInput({ placeholder: '请输入问题' })
          .layoutWeight(1)
          .height(40)
          .margin({ right: 10 })
          .onChange((value: string) => {
            this.currentQuestion = value
          })
        
        Button('发送')
          .width(80)
          .height(40)
          .onClick(() => {
            this.sendMessage()
          })
      }
      .width('100%')
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}
```

### 3.3 组件设计

#### 3.3.1 书籍信息组件 (BookInfoComponent.ets)
```typescript
@Component
struct BookInfoComponent {
  @Prop bookInfo: BookInfo
  
  build() {
    Column() {
      Text('书籍信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
      
      // 书籍详情
      if (this.bookInfo.title) {
        Text(`书名: ${this.bookInfo.title}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.author) {
        Text(`作者: ${this.bookInfo.author}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.publisher) {
        Text(`出版社: ${this.bookInfo.publisher}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.description) {
        Text('简介:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 8 })
        
        Text(this.bookInfo.description)
          .fontSize(14)
          .lineHeight(20)
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#f5f5f5')
    .borderRadius(10)
  }
}
```

#### 3.3.2 问答组件 (QAComponent.ets)
```typescript
@Component
struct QAComponent {
  @Prop message: QAMessage
  
  build() {
    Row() {
      if (message.type === 'question') {
        // 用户问题靠右
        Column() {
          Text('用户')
            .fontSize(12)
            .margin({ bottom: 5 })
          
          Text(message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#007AFF')
            .borderRadius(15)
            .foregroundColor(Color.White)
        }
        .alignItems(HorizontalAlign.End)
        .width('100%')
      } else {
        // AI回答靠左
        Column() {
          Text('AI助手')
            .fontSize(12)
            .margin({ bottom: 5 })
          
          Text(message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#E5E5EA')
            .borderRadius(15)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .margin({ bottom: 15 })
  }
}
```

## 4. 网络通信架构

### 4.1 API服务封装
```typescript
// ApiService.ets
export class ApiService {
  private static readonly BASE_URL = 'http://your-backend-url:8000'
  
  static async getBookInfo(bookName: string): Promise<BookInfo> {
    const response = await http.createHttp().request(
      `${this.BASE_URL}/api/book/info`,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: {
          book_name: bookName
        }
      }
    )
    
    return JSON.parse(response.result as string).data
  }
  
  static async askQuestion(bookName: string, question: string): Promise<string> {
    const response = await http.createHttp().request(
      `${this.BASE_URL}/api/book/qa`,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: {
          book_name: bookName,
          question: question
        }
      }
    )
    
    return JSON.parse(response.result as string).data.answer
  }
}
```

### 4.2 错误处理机制
```typescript
// 错误处理封装
export class ErrorHandler {
  static handleApiError(error: BusinessError): string {
    switch (error.code) {
      case '401':
        return 'API认证失败'
      case '404':
        return '请求的资源不存在'
      case '500':
        return '服务器内部错误'
      default:
        return '网络请求失败'
    }
  }
}
```

## 5. 数据模型设计

### 5.1 后端数据模型
```python
# Pydantic模型
from pydantic import BaseModel, Optional
from typing import Optional

class BookInfo(BaseModel):
    title: str
    author: Optional[str] = None
    publisher: Optional[str] = None
    year: Optional[str] = None
    isbn: Optional[str] = None
    description: Optional[str] = None
    summary: Optional[str] = None

class QARequest(BaseModel):
    book_name: str
    question: str

class QAResponse(BaseModel):
    answer: str

class APIResponse(BaseModel):
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None
```

### 5.2 前端数据模型
```typescript
// BookInfo.ets
export class BookInfo {
  title: string = ''
  author: string = ''
  publisher: string = ''
  year: string = ''
  isbn: string = ''
  description: string = ''
  summary: string = ''
  
  constructor(data?: any) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// QAMessage.ets
export class QAMessage {
  content: string = ''
  type: 'question' | 'answer' = 'question'
  timestamp: number = Date.now()
  
  constructor(content: string, type: 'question' | 'answer') {
    this.content = content
    this.type = type
  }
}
```

## 6. 安全架构

### 6.1 API安全
- HTTPS加密传输
- API密钥管理
- 输入数据验证
- 请求频率限制

### 6.2 数据安全
- 敏感信息不存储
- 临时数据内存管理
- 网络传输加密

## 7. 性能优化

### 7.1 后端优化
- 异步请求处理
- 连接池管理
- 响应缓存策略
- 错误重试机制

### 7.2 前端优化
- 图片懒加载
- 列表虚拟滚动
- 状态管理优化
- 网络请求缓存

## 8. 部署架构

### 8.1 后端部署
```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    restart: unless-stopped
```

### 8.2 应用部署
- HarmonyOS应用商店发布
- 开发者证书签名
- 版本管理策略

## 9. 监控和日志

### 9.1 后端监控
- API请求监控
- 错误日志记录
- 性能指标收集
- 健康检查接口

### 9.2 应用监控
- 崩溃报告收集
- 用户行为分析
- 性能监控
- 网络状态监控

## 10. 扩展性考虑

### 10.1 水平扩展
- 后端服务容器化
- 负载均衡配置
- 数据库分片策略

### 10.2 功能扩展
- 用户系统预留接口
- 书籍推荐系统接口
- 多语言支持架构
- 离线功能支持