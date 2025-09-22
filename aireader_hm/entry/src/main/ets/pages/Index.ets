import { BookInfo, BookInfoData } from '../model/BookInfo'
import { QAMessage } from '../model/QAMessage'
import { ChatRequest } from '../model/ChatModels'
import { ClientChatSession } from '../model/ClientChatModels'
import { ApiService } from '../services/ApiService'
import { ClientSessionManager } from '../services/ClientSessionManager'
import { QAComponent } from '../components/QAComponent'
import { LoadingComponent } from '../components/LoadingComponent'
import { SessionListComponent } from '../components/SessionListComponent'
import { PromptSuggestion } from '../model/Prompt'
import { PromptService } from '../services/PromptService'
import { PromptSuggestions } from '../components/PromptSuggestions'
import { FeedbackDialog } from '../components/FeedbackDialog'
import { promptAction } from '@kit.ArkUI'
import { ComplaintData } from '../model/Complaint'

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

  private dialogController: CustomDialogController | null = null

  async aboutToAppear() {
    try {
      await this.sessionManager.ensureInitialized()
      await this.sessionManager.ensureDefaultSession()
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
      this.messages = [...currentSession.messages]
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
    const userQuestions = this.messages.filter(m => m.type === 'question').length
    if (this.bookInfo && userQuestions >= 1) {
      this.promptSuggestions = PromptService.getBookAnalysisPrompts()
      this.showPromptSuggestions = true
    } else {
      this.showPromptSuggestions = false
    }
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
    this.showPromptSuggestions = false
    const input = this.currentInput.trim()
    this.currentInput = ''
    const userMessage = new QAMessage(input, 'question')
    await this.sessionManager.addMessageToCurrentSession(userMessage)
    this.loadCurrentSession()
    this.isLoading = true
    try {
      if (!this.bookInfo) {
        const fullBookInfo = await ApiService.getBookInfo(input)
        if (fullBookInfo.is_found) {
          this.bookInfo = fullBookInfo
          await this.sessionManager.updateCurrentSessionBookInfo(this.bookInfo.title, this.bookInfo)
          const bookInfoText = `📚 《${this.bookInfo.title}》\n\n` +
            `作者：${this.bookInfo.author || '未知'}\n` +
            `出版社：${this.bookInfo.publisher || '未知'}\n` +
            `出版年份：${this.bookInfo.year || '未知'}\n\n` +
            `简介：\n${this.bookInfo.description || '暂无简介'}`
          const bookInfoMessage = new QAMessage(bookInfoText, 'answer')
          await this.sessionManager.addMessageToCurrentSession(bookInfoMessage)
        } else {
          this.bookInfo = null
          await this.sessionManager.clearCurrentSessionBookInfo()
          const notFoundMessage = new QAMessage(fullBookInfo.not_found_reason, 'answer')
          await this.sessionManager.addMessageToCurrentSession(notFoundMessage)
        }
        this.loadCurrentSession()
      } else {
        const chatHistory = this.sessionManager.getCurrentChatHistoryForAPI()
        const answer = await ApiService.chatWithHistory({
          bookName: this.bookInfo.title,
          messages: chatHistory,
          question: input
        })
        const answerMessage = new QAMessage(answer, 'answer')
        await this.sessionManager.addMessageToCurrentSession(answerMessage)
        this.loadCurrentSession()
      }
    } catch (error) {
      const errorMessage = new QAMessage(error.message, 'answer')
      this.bookInfo = null
      await this.sessionManager.clearCurrentSessionBookInfo()
      await this.sessionManager.addMessageToCurrentSession(errorMessage)
      this.loadCurrentSession()
    } finally {
      this.isLoading = false
      this.updateSessionsFromManager()
      if (this.bookInfo) {
        this.promptSuggestions = PromptService.getBookAnalysisPrompts()
        this.showPromptSuggestions = true
      }
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      }, 100)
    }
  }

  handleFeedback = (messageId: string, feedback: 'like' | 'dislike') => {
    if (feedback === 'like') {
      promptAction.showToast({ message: '感谢您的反馈！' })
    } else {
      this.dialogController = new CustomDialogController({
        builder: FeedbackDialog({
          messageId: messageId,
          onSubmit: this.handleSubmitFeedback
        }),
        autoCancel: true,
        alignment: DialogAlignment.Center
      })
      this.dialogController.open()
    }
  }

  handleSubmitFeedback = async (messageId: string, reasons: string[], details: string) => {
    try {
      const complaint: ComplaintData = {
        message_id: messageId,
        session_id: this.currentSessionId,
        reasons: reasons,
        details: details
      }
      await ApiService.submitComplaint(complaint)
      promptAction.showToast({ message: '反馈已提交，感谢！' })
    } catch (error) {
      promptAction.showToast({ message: `提交失败: ${error.message}` })
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
          }
          .width(32)
          .height(32)
          .backgroundColor($r('app.color.secondary_button_bg'))
          .onClick(() => {
            this.showSessionList = !this.showSessionList
          })
          Text('AI读书助手')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button() {
            Text('+')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_button_text'))
          }
          .width(32)
          .height(32)
          .backgroundColor($r('app.color.primary_button_bg'))
          .borderRadius(16)
          .onClick(async () => {
            await this.createNewSession()
          })
        }
        .width('100%')
        .margin({ bottom: 16 })
        if (this.currentSessionId) {
          Row() {
            Text(this.getCurrentSessionTitle())
              .fontSize(14)
              .fontColor($r('app.color.secondary_text'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })
          .padding({ left: 8, right: 8 })
        }
        Scroll(this.scroller) {
          Column() {
            ForEach(this.messages, (message: QAMessage) => {
              QAComponent({
                message: message,
                onFeedback: this.handleFeedback
              })
            }, (item: QAMessage) => item.id)
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        if (this.isLoading) {
          LoadingComponent()
            .margin({ bottom: 8 })
        }
        if (this.showPromptSuggestions && this.bookInfo) {
          PromptSuggestions({
            suggestions: this.promptSuggestions,
            onSuggestionClick: (suggestion: PromptSuggestion) => {
              this.handleSuggestionClick(suggestion)
            }
          })
        }
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
      if (this.showSessionList) {
        Row() {
          Column() {
            SessionListComponent({
              sessions: this.sessions,
              currentSessionId: this.currentSessionId,
              isLoading: false,
              onSessionSelect: (session: ClientChatSession) => {
                this.switchSession(session)
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
                    action: () => {
                      this.deleteSession(sessionId)
                    }
                  }
                })
              },
              onNewSession: () => {
                this.createNewSession()
              }
            })
          }
          .width('80%')
          .height('100%')
          .backgroundColor($r('app.color.session_list_bg'))
          .shadow({
            radius: 10,
            color: $r('app.color.session_list_shadow'),
            offsetX: 2,
            offsetY: 0
          })
          Blank()
            .layoutWeight(1)
            .backgroundColor($r('app.color.mask_bg'))
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
    if (suggestion.id === '7') {
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
    const userMessage = new QAMessage(`正在为《${bookTitle}》生成详细报告...`, 'question');
    await this.sessionManager.addMessageToCurrentSession(userMessage);
    this.loadCurrentSession();
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
