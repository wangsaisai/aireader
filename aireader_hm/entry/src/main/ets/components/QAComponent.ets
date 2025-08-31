import { QAMessage } from '../model/QAMessage'
import { MarkdownRenderer } from './MarkdownRenderer'

@Component
export struct QAComponent {
  @Prop message: QAMessage
  
  build() {
    Row() {
      if (this.message.type === 'question') {
        Column() {
          Text(this.message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#007AFF')
            .borderRadius(15)
            .foregroundColor(Color.White)
        }
        .alignItems(HorizontalAlign.End)
        .width('80%')
      } else {
        Column() {
          Column() {
            MarkdownRenderer({ content: this.message.content })
          }
          .padding(12)
          .backgroundColor('#E5E5EA')
          .borderRadius(15)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('80%')
      }
    }
    .margin({ bottom: 15 })
    .width('100%')
    .justifyContent(this.message.type === 'question' ? FlexAlign.End : FlexAlign.Start)
  }
}