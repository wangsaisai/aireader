import { BookInfo } from '../model/BookInfo'
import { QAMessage } from '../model/QAMessage'
import { ApiService } from '../services/ApiService'
import { QAComponent } from '../components/QAComponent'
import { LoadingComponent } from '../components/LoadingComponent'

@Entry
@Component
struct Index {
  @State bookInfo: BookInfo | null = null
  @State isLoading: boolean = false
  @State messages: QAMessage[] = []
  @State currentInput: string = ''
  private scroller: Scroller = new Scroller()
  private textInputController: TextInputController = new TextInputController()

  async processMessage() {
    if (!this.currentInput.trim()) {
      return
    }

    const input = this.currentInput.trim()
    this.currentInput = ''
    
    // 添加用户消息
    this.messages.push(new QAMessage(input, 'question'))
    this.isLoading = true
    
    try {
      if (!this.bookInfo) {
        // 首次问答：查询书籍信息
        this.bookInfo = await ApiService.getBookInfo(input)
        
        // 添加书籍信息到消息列表
        if (this.bookInfo) {
          const bookInfoText = `📚 《${this.bookInfo.title}》\n\n` +
            `作者：${this.bookInfo.author || '未知'}\n` +
            `出版社：${this.bookInfo.publisher || '未知'}\n` +
            `出版年份：${this.bookInfo.year || '未知'}\n` +
            `ISBN：${this.bookInfo.isbn || '未知'}\n\n` +
            `简介：\n${this.bookInfo.description || '暂无简介'}\n\n` +
            `内容概述：\n${this.bookInfo.summary || '暂无概述'}`
          
          this.messages.push(new QAMessage(bookInfoText, 'answer'))
        }
      } else {
        // 后续问答：针对书籍进行问答
        const answer = await ApiService.askQuestion(this.bookInfo.title, input)
        this.messages.push(new QAMessage(answer, 'answer'))
      }
    } catch (error) {
      this.messages.push(new QAMessage('抱歉，处理失败：' + error.message, 'answer'))
    } finally {
      this.isLoading = false
      // 延迟滚动到底部，确保内容已渲染
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      }, 100)
    }
  }

  build() {
    Column() {
      // 顶部标题
      Text('AI读书助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
      
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
  }
}