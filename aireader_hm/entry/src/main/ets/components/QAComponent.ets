import { QAMessage } from '../model/QAMessage'

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
            .backgroundColor($r('app.color.question_bubble_bg'))
            .borderRadius(15)
            .foregroundColor($r('app.color.question_bubble_text'))
        }
        .alignItems(HorizontalAlign.End)
        .width('80%')
      } else {
        Column() {
          Column() {
            Text(this.message.content)
              .fontSize(16)
              .foregroundColor($r('app.color.answer_bubble_text'))
          }
          .padding(12)
          .backgroundColor($r('app.color.answer_bubble_bg'))
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