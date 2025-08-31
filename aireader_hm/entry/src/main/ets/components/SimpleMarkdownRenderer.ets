import { MarkdownElement, MarkdownUtils } from '../utils/MarkdownUtils'

@Component
export struct SimpleMarkdownRenderer {
  @Prop content: string
  
  build() {
    Column() {
      // 简单的Markdown处理：直接显示文本，不做复杂解析
      Text(this.content)
        .fontSize(16)
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}