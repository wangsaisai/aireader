import { BookInfo, BookInfoData } from '../model/BookInfo'
import { QAMessage } from '../model/QAMessage'
import { ChatRequest, ChatMessage as ChatMessageModel } from '../model/ChatModels'
import { ClientChatSession } from '../model/ClientChatModels'
import { ApiService } from '../services/ApiService'
import { ClientSessionManager } from '../services/ClientSessionManager'
import { QAComponent } from '../components/QAComponent'
import { LoadingComponent } from '../components/LoadingComponent'
import { SessionListComponent } from '../components/SessionListComponent'

@Entry
@Component
struct Index {
  @State bookInfo: BookInfo | null = null
  @State isLoading: boolean = false
  @State messages: QAMessage[] = []
  @State currentInput: string = ''
  @State sessions: ClientChatSession[] = []
  @State currentSessionId: string = ''
  @State showSessionList: boolean = false
  
  private sessionManager: ClientSessionManager = new ClientSessionManager()
  private scroller: Scroller = new Scroller()
  private textInputController: TextInputController = new TextInputController()

  aboutToAppear() {
    this.sessionManager.loadSessions()
    this.updateSessionsFromManager()
    this.loadCurrentSession()
  }

  updateSessionsFromManager() {
    this.sessions = this.sessionManager.getAllSessions()
    this.currentSessionId = this.sessionManager.getCurrentSession()?.id || ''
  }

  loadCurrentSession() {
    const currentSession = this.sessionManager.getCurrentSession()
    if (currentSession) {
      this.messages = currentSession.messages
      this.bookInfo = currentSession.bookName ? new BookInfo(currentSession.bookInfo as BookInfoData) : null
    } else {
      this.messages = []
      this.bookInfo = null
    }
  }

  createNewSession(title?: string, bookName?: string) {
    const sessionTitle = title || '新对话'
    const session = this.sessionManager.createSession(sessionTitle, bookName)
    
    this.updateSessionsFromManager()
    this.loadCurrentSession()
    this.showSessionList = false
    
    return session
  }

  switchSession(session: ClientChatSession) {
    this.sessionManager.switchSession(session.id)
    this.updateSessionsFromManager()
    this.loadCurrentSession()
    this.showSessionList = false
    
    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)
  }

  deleteSession(sessionId: string) {
    this.sessionManager.deleteSession(sessionId)
    this.updateSessionsFromManager()
    this.loadCurrentSession()
  }

  async processMessage() {
    if (!this.currentInput.trim()) {
      return
    }

    const input = this.currentInput.trim()
    this.currentInput = ''
    
    // 添加用户消息到会话管理器
    const userMessage = new QAMessage(input, 'question')
    this.sessionManager.addMessageToCurrentSession(userMessage)
    this.loadCurrentSession() // 重新加载消息以同步界面
    this.isLoading = true
    
    try {
      if (!this.bookInfo) {
        // 首次问答：查询书籍信息
        this.bookInfo = await ApiService.getBookInfo(input)
        
        // 更新会话书籍信息
        if (this.bookInfo) {
          this.sessionManager.updateCurrentSessionBookInfo(this.bookInfo.title, this.bookInfo)
        }
        
        // 添加书籍信息到消息列表
        if (this.bookInfo) {
          const bookInfoText = `📚 《${this.bookInfo.title}》\n\n` +
            `作者：${this.bookInfo.author || '未知'}\n` +
            `出版社：${this.bookInfo.publisher || '未知'}\n` +
            `出版年份：${this.bookInfo.year || '未知'}\n` +
            `ISBN：${this.bookInfo.isbn || '未知'}\n\n` +
            `简介：\n${this.bookInfo.description || '暂无简介'}\n\n` +
            `内容概述：\n${this.bookInfo.summary || '暂无概述'}`
          
          const bookInfoMessage = new QAMessage(bookInfoText, 'answer')
          this.sessionManager.addMessageToCurrentSession(bookInfoMessage)
          this.loadCurrentSession() // 重新加载消息以同步界面
        }
      } else {
        // 后续问答：使用新的无状态API
        const chatHistory = this.sessionManager.getCurrentChatHistoryForAPI()
        const answer = await ApiService.chatWithHistory({
          bookName: this.bookInfo.title,
          messages: chatHistory,
          question: input
        })
        
        const answerMessage = new QAMessage(answer, 'answer')
        this.sessionManager.addMessageToCurrentSession(answerMessage)
        this.loadCurrentSession() // 重新加载消息以同步界面
      }
    } catch (error) {
      const errorMessage = new QAMessage('抱歉，处理失败：' + error.message, 'answer')
      this.sessionManager.addMessageToCurrentSession(errorMessage)
      this.loadCurrentSession() // 重新加载消息以同步界面
    } finally {
      this.isLoading = false
      // 更新会话列表
      this.updateSessionsFromManager()
      
      // 延迟滚动到底部，确保内容已渲染
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      }, 100)
    }
  }

  build() {
    Stack() {
      // 主界面
      Column() {
        // 顶部标题栏
        Row() {
          // 左侧会话列表图标按钮
          Button() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
          }
          .width(32)
          .height(32)
          .backgroundColor('#f0f0f0')
          .onClick(() => {
            this.showSessionList = !this.showSessionList
          })
          
          Text('AI读书助手')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          
          // 右侧新建会话按钮
          Button() {
            Text('+')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
          }
          .width(32)
          .height(32)
          .backgroundColor('#007aff')
          .borderRadius(16)
          .onClick(() => {
            this.createNewSession()
          })
        }
        .width('100%')
        .margin({ bottom: 16 })
        
        // 当前会话信息
        if (this.currentSessionId) {
          Row() {
            Text(this.getCurrentSessionTitle())
              .fontSize(14)
              .fontColor('#666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            
            if (this.bookInfo) {
              Text(`📚 ${this.bookInfo.title}`)
                .fontSize(12)
                .fontColor('#007aff')
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .margin({ bottom: 12 })
          .padding({ left: 8, right: 8 })
        }
        
        // 聊天内容区域
        Scroll(this.scroller) {
          Column() {
            ForEach(this.messages, (message: QAMessage) => {
              QAComponent({ message: message })
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        
        // 底部加载状态
        if (this.isLoading) {
          LoadingComponent()
            .margin({ bottom: 8 })
        }
        
        // 底部输入区域
        Row() {
          TextInput({ 
            placeholder: this.bookInfo ? '请输入关于这本书的问题' : '请输入书籍名称开始对话',
            controller: this.textInputController,
            text: this.currentInput
          })
            .layoutWeight(1)
            .height(40)
            .margin({ right: 10 })
            .enabled(!this.isLoading)
            .onChange((value: string) => {
              this.currentInput = value
            })
          
          Button('发送')
            .width(80)
            .height(40)
            .enabled(!this.isLoading && this.currentInput.trim().length > 0)
            .onClick(() => {
              this.processMessage()
            })
        }
        .width('100%')
        .margin({ top: 8, bottom: 20 })
      }
      .padding(20)
      .width('100%')
      .height('100%')
      
      // 会话列表侧边栏
      if (this.showSessionList) {
        Row() {
          // 会话列表（左侧）
          Column() {
            SessionListComponent({
              sessions: this.sessions,
              currentSessionId: this.currentSessionId,
              isLoading: false,
              onSessionSelect: (session: ClientChatSession) => {
                this.switchSession(session)
              },
              onSessionDelete: (sessionId: string) => {
                this.deleteSession(sessionId)
              },
              onNewSession: () => {
                this.createNewSession()
              }
            })
          }
          .width('80%')
          .height('100%')
          .backgroundColor('#fff')
          .shadow({
            radius: 10,
            color: 'rgba(0,0,0,0.1)',
            offsetX: 2,
            offsetY: 0
          })
          
          // 遮罩层
          Blank()
            .layoutWeight(1)
            .backgroundColor('rgba(0,0,0,0.3)')
            .onClick(() => {
              this.showSessionList = false
            })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
  
  private getCurrentSessionTitle(): string {
    if (!this.currentSessionId) {
      return '新对话'
    }
    
    const session = this.sessions.find(s => s.id === this.currentSessionId)
    return session ? session.title : '未知会话'
  }
}