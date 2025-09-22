import { QAMessage } from '../model/QAMessage'

@Component
export struct QAComponent {
  @Prop message: QAMessage
  public onFeedback?: (messageId: string, feedback: 'like' | 'dislike') => void

  build() {
    Row() {
      if (this.message.type === 'question') {
        // 用户消息气泡
        Row() {
          Text(this.message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor($r('app.color.question_bubble_bg'))
            .borderRadius(15)
            .foregroundColor($r('app.color.question_bubble_text'))
        }
        .flexShrink(1)
        .margin({ left: '20%' })

      } else {
        // AI消息气泡
        Column() {
          Column() {
            // 使用Text渲染AI回复
            Text(this.message.content)
              .fontSize(16)
              .foregroundColor($r('app.color.answer_bubble_text'))
          }
          .padding(12)
          .backgroundColor($r('app.color.answer_bubble_bg'))
          .borderRadius(15)
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 点赞/点踩按钮
          if (this.onFeedback) {
            Row() {
              Text('👍')
                .fontSize(20)
                .onClick(() => {
                  if (this.onFeedback) {
                    this.onFeedback(this.message.id, 'like')
                  }
                })

              Text('👎')
                .fontSize(20)
                .margin({ left: 15 })
                .onClick(() => {
                  if (this.onFeedback) {
                    this.onFeedback(this.message.id, 'dislike')
                  }
                })
            }
            .margin({ top: 8 })
            .padding({ left: 5 })
            .visibility(this.message.content ? Visibility.Visible : Visibility.Hidden)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ right: '20%' })
      }
    }
    .margin({ bottom: 15 })
    .width('100%')
    .justifyContent(this.message.type === 'question' ? FlexAlign.End : FlexAlign.Start)
  }
}
