import router from '@ohos.router'
import { QAMessage } from '../model/QAMessage'
import { ApiService } from '../services/ApiService'
import { BookInfo } from '../model/BookInfo'
import { QAComponent } from '../components/QAComponent'
import { LoadingComponent } from '../components/LoadingComponent'

@Entry
@Component
struct QAPage {
  @State messages: QAMessage[] = []
  @State currentQuestion: string = ''
  @State isLoading: boolean = false
  @State bookName: string = ''
  @State bookInfo: BookInfo | null = null

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object> | null
    if (params) {
      this.bookName = (params.bookName as string) || ''
      this.bookInfo = (params.bookInfo as BookInfo) || null
    }
  }

  async sendMessage() {
    if (!this.currentQuestion.trim()) {
      return
    }

    const question = this.currentQuestion.trim()
    this.currentQuestion = ''
    
    this.messages.push(new QAMessage(question, 'question'))
    this.isLoading = true
    
    try {
      const answer = await ApiService.askQuestion(this.bookName, question)
      this.messages.push(new QAMessage(answer, 'answer'))
    } catch (error) {
      this.messages.push(new QAMessage('抱歉，获取回答失败：' + error.message, 'answer'))
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .margin({ right: 8 })
        
        Text(`《${this.bookName}》问答`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Button('返回')
          .fontSize(14)
          .onClick(() => {
            router.back()
          })
      }
      .width('100%')
      .margin({ bottom: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      
      List() {
        ForEach(this.messages, (message: QAMessage) => {
          ListItem() {
            QAComponent({ message: message })
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      
      if (this.isLoading) {
        LoadingComponent()
      }
      
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
          .enabled(!this.isLoading && this.currentQuestion.trim().length > 0)
          .onClick(() => {
            this.sendMessage()
          })
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}