import { BookInfo, BookInfoData } from '../model/BookInfo'
import { QAMessage } from '../model/QAMessage'
import { ChatRequest, ChatMessage as ChatMessageModel } from '../model/ChatModels'
import { ClientChatSession } from '../model/ClientChatModels'
import { ApiService } from '../services/ApiService'
import { ClientSessionManager } from '../services/ClientSessionManager'
import { QAComponent } from '../components/QAComponent'
import { LoadingComponent } from '../components/LoadingComponent'
import { SessionListComponent } from '../components/SessionListComponent'
import { PromptSuggestion } from '../model/Prompt'
import { PromptService } from '../services/PromptService'
import { PromptSuggestions } from '../components/PromptSuggestions'

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
  @State showPromptSuggestions: boolean = false
  private promptSuggestions: PromptSuggestion[] = []
  
  private sessionManager: ClientSessionManager = new ClientSessionManager()
  private scroller: Scroller = new Scroller()
  private textInputController: TextInputController = new TextInputController()

  async aboutToAppear() {
    try {
      // 等待会话管理器初始化完成
      await this.sessionManager.ensureInitialized()
      // 确保有默认会话
      await this.sessionManager.ensureDefaultSession()
      // 更新界面
      this.updateSessionsFromManager()
      this.loadCurrentSession()
    } catch (error) {
      console.error('Failed to initialize session manager:', error)
    }
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

  async createNewSession(title?: string, bookName?: string) {
    const sessionTitle = title || '新对话'
    const session = await this.sessionManager.createSession(sessionTitle, bookName)

    this.updateSessionsFromManager()
    this.loadCurrentSession()
    this.showPromptSuggestions = false
    this.showSessionList = false

    return session
  }

  async switchSession(session: ClientChatSession) {
    await this.sessionManager.switchSession(session.id)
    this.updateSessionsFromManager()
    this.loadCurrentSession()
    this.showSessionList = false

    // 切换会话后，判断是否显示推荐问题
    // 只要有书本信息，并且至少有过一个问题（即书名查询），就显示推荐
    const userQuestions = this.messages.filter(m => m.type === 'question').length
    if (this.bookInfo && userQuestions >= 1) {
      this.promptSuggestions = PromptService.getBookAnalysisPrompts()
      this.showPromptSuggestions = true
    } else {
      this.showPromptSuggestions = false
    }

    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)
  }

  async deleteSession(sessionId: string) {
    await this.sessionManager.deleteSession(sessionId)
    this.updateSessionsFromManager()
    this.loadCurrentSession()
  }

  async processMessage() {
    if (!this.currentInput.trim()) {
      return
    }

    this.showPromptSuggestions = false // 用户发送新消息时，隐藏推荐
    const input = this.currentInput.trim()
    this.currentInput = ''

    // 添加用户消息到会话管理器
    const userMessage = new QAMessage(input, 'question')
    await this.sessionManager.addMessageToCurrentSession(userMessage)
    this.loadCurrentSession() // 重新加载消息以同步界面
    this.isLoading = true

    try {
      if (!this.bookInfo) {
        // First, get the complete BookInfo object from the API
        const fullBookInfo = await ApiService.getBookInfo(input)

        if (fullBookInfo.is_found) {
          // Book was found, proceed as before
          this.bookInfo = fullBookInfo

          // Update session with the found book info
          await this.sessionManager.updateCurrentSessionBookInfo(this.bookInfo.title, this.bookInfo)

          // Add book details to the chat
          const bookInfoText = `📚 《${this.bookInfo.title}》\n\n` +
            `作者：${this.bookInfo.author || '未知'}\n` +
            `出版社：${this.bookInfo.publisher || '未知'}\n` +
            `出版年份：${this.bookInfo.year || '未知'}\n\n` +
            `简介：\n${this.bookInfo.description || '暂无简介'}`
          const bookInfoMessage = new QAMessage(bookInfoText, 'answer')
          await this.sessionManager.addMessageToCurrentSession(bookInfoMessage)
          
        } else {
          // Book was not found, display the reason
          this.bookInfo = null // Ensure no book info is displayed
          await this.sessionManager.clearCurrentSessionBookInfo()
          
          const notFoundMessage = new QAMessage(fullBookInfo.not_found_reason, 'answer')
          await this.sessionManager.addMessageToCurrentSession(notFoundMessage)
        }
        
        this.loadCurrentSession() // Reload session to show new messages

      } else {
        // 后续问答：使用新的无状态API
        const chatHistory = this.sessionManager.getCurrentChatHistoryForAPI()
        const answer = await ApiService.chatWithHistory({
          bookName: this.bookInfo.title,
          messages: chatHistory,
          question: input
        })

        const answerMessage = new QAMessage(answer, 'answer')
        await this.sessionManager.addMessageToCurrentSession(answerMessage)
        this.loadCurrentSession() // 重新加载消息以同步界面
      }
    } catch (error) {
      // When book info fails, the raw LLM response is in error.message.
      // We display it directly.
      const errorMessage = new QAMessage(error.message, 'answer')
      // Ensure bookInfo is null so we don't show prompts or old info.
      this.bookInfo = null
      await this.sessionManager.clearCurrentSessionBookInfo()
      await this.sessionManager.addMessageToCurrentSession(errorMessage)
      this.loadCurrentSession() // 重新加载消息以同步界面
    } finally {
      this.isLoading = false
      // 更新会话列表
      this.updateSessionsFromManager()

      // 如果有书籍信息，则在每次回答后重新显示推荐问题
      if (this.bookInfo) {
        this.promptSuggestions = PromptService.getBookAnalysisPrompts()
        this.showPromptSuggestions = true
      }

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
          .onClick(async () => {
            await this.createNewSession()
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

        // 推荐问题区域
        if (this.showPromptSuggestions && this.bookInfo) {
          PromptSuggestions({
            suggestions: this.promptSuggestions,
            onSuggestionClick: (suggestion: PromptSuggestion) => {
              this.handleSuggestionClick(suggestion)
            }
          })
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
              onSessionSelect: async (session: ClientChatSession) => {
                await this.switchSession(session)
              },
              onSessionDelete: (sessionId: string) => {
                AlertDialog.show({
                  title: '确认删除',
                  message: '您确定要删除这个会话吗？此操作无法撤销。',
                  primaryButton: {
                    value: '取消',
                    action: () => {
                      console.info('取消删除')
                    }
                  },
                  secondaryButton: {
                    value: '删除',
                    fontColor: Color.Red,
                    action: async () => {
                      await this.deleteSession(sessionId)
                    }
                  }
                })
              },
              onNewSession: async () => {
                await this.createNewSession()
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

  async handleSuggestionClick(suggestion: PromptSuggestion) {
    if (suggestion.id === '7') { // 特殊处理“生成详细书籍报告”
      await this.generateDetailedReport();
    } else {
      this.currentInput = suggestion.prompt;
      await this.processMessage();
    }
  }

  async generateDetailedReport() {
    if (!this.bookInfo) {
      return;
    }

    this.showPromptSuggestions = false;
    const bookTitle = this.bookInfo.title;
    const bookAuthor = this.bookInfo.author;

    // 添加用户操作的提示
    const userMessage = new QAMessage(`正在为《${bookTitle}》生成详细报告...`, 'question');
    await this.sessionManager.addMessageToCurrentSession(userMessage);
    this.loadCurrentSession();

    // 提示用户耗时较久
    const systemMessage = new QAMessage("报告生成中，这可能需要几分钟时间，请耐心等待...", 'answer');
    await this.sessionManager.addMessageToCurrentSession(systemMessage);
    this.loadCurrentSession();

    this.isLoading = true;

    try {
      const report = await ApiService.generateDetailedReport(bookTitle, bookAuthor);
      const reportMessage = new QAMessage(report, 'answer');
      await this.sessionManager.addMessageToCurrentSession(reportMessage);
      this.loadCurrentSession();
    } catch (error) {
      const errorMessage = new QAMessage(`生成报告失败：${error.message}`, 'answer');
      await this.sessionManager.addMessageToCurrentSession(errorMessage);
      this.loadCurrentSession();
    } finally {
      this.isLoading = false;
      this.updateSessionsFromManager();
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 100);
    }
  }
}