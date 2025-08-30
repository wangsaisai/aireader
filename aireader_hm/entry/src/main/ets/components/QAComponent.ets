import { QAMessage } from '../model/QAMessage'

@Component
export struct QAComponent {
  @Prop message: QAMessage
  
  build() {
    Row() {
      if (this.message.type === 'question') {
        Column() {
          Text('用户')
            .fontSize(12)
            .margin({ bottom: 5 })
          
          Text(this.message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#007AFF')
            .borderRadius(15)
            .foregroundColor(Color.White)
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.End)
        .width('100%')
      } else {
        Column() {
          Text('AI助手')
            .fontSize(12)
            .margin({ bottom: 5 })
          
          Text(this.message.content)
            .fontSize(16)
            .padding(12)
            .backgroundColor('#E5E5EA')
            .borderRadius(15)
            .maxLines(10)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .margin({ bottom: 15 })
  }
}