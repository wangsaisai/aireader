import { MarkdownElement, MarkdownUtils } from '../utils/MarkdownUtils'

@Component
export struct MarkdownRenderer {
  @Prop content: string
  
  private elements: MarkdownElement[] = []
  
  aboutToAppear() {
    this.elements = MarkdownUtils.parseMarkdown(this.content)
  }
  
  build() {
    Column() {
      ForEach(this.elements, (element: MarkdownElement) => {
        this.renderElement(element)
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  renderElement(element: MarkdownElement) {
    if (element.type === 'h1') {
      Text(element.content)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 8 })
    } else if (element.type === 'h2') {
      Text(element.content)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 14, bottom: 6 })
    } else if (element.type === 'h3') {
      Text(element.content)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 12, bottom: 4 })
    } else if (element.type === 'paragraph') {
      if (element.content.includes('<b>') || element.content.includes('<i>') || element.content.includes('<code>')) {
        this.renderFormattedText(element.content)
      } else {
        Text(element.content)
          .fontSize(16)
          .lineHeight(22)
          .margin({ bottom: 8 })
      }
    } else if (element.type === 'li') {
      Row() {
        Text('• ')
          .fontSize(16)
          .margin({ right: 8 })
        Text(element.content)
          .fontSize(16)
          .lineHeight(22)
          .flexGrow(1)
      }
      .width('100%')
      .margin({ bottom: 4 })
      .alignItems(VerticalAlign.Top)
    } else if (element.type === 'code') {
      Column() {
        Text(element.content)
          .fontSize(14)
          .fontFamily('monospace')
          .backgroundColor('#f0f0f0')
          .padding(12)
          .borderRadius(6)
          .width('100%')
      }
      .margin({ top: 8, bottom: 8 })
    } else if (element.type === 'quote') {
      Column() {
        Text(element.content)
          .fontSize(16)
          .lineHeight(22)
          .padding({ left: 12 })
          .border({ width: { left: 4 }, color: { left: '#007AFF' } })
          .backgroundColor('#f8f9fa')
          .padding(12)
          .borderRadius(4)
      }
      .margin({ top: 8, bottom: 8 })
    }
  }
  
  @Builder
  renderFormattedText(text: string) {
    Row() {
      ForEach(this.parseFormattedText(text), (segment: TextSegment) => {
        if (segment.type === 'bold') {
          Text(segment.content)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .lineHeight(22)
        } else if (segment.type === 'italic') {
          Text(segment.content)
            .fontSize(16)
            .fontStyle(FontStyle.Italic)
            .lineHeight(22)
        } else if (segment.type === 'code') {
          Text(segment.content)
            .fontSize(14)
            .fontFamily('monospace')
            .backgroundColor('#f0f0f0')
            .padding(2)
            .borderRadius(3)
        } else {
          Text(segment.content)
            .fontSize(16)
            .lineHeight(22)
        }
      })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }
  
  parseFormattedText(text: string): TextSegment[] {
    const segments: TextSegment[] = []
    const regex = /(<b>.*?<\/b>|<i>.*?<\/i>|<code>.*?<\/code>|[^<]+)/g
    let match: RegExpExecArray | null
    
    while ((match = regex.exec(text)) !== null) {
      const content = match[1]
      
      if (content.startsWith('<b>') && content.endsWith('</b>')) {
        segments.push(new TextSegment('bold', content.slice(3, -4)))
      } else if (content.startsWith('<i>') && content.endsWith('</i>')) {
        segments.push(new TextSegment('italic', content.slice(3, -4)))
      } else if (content.startsWith('<code>') && content.endsWith('</code>')) {
        segments.push(new TextSegment('code', content.slice(6, -7)))
      } else {
        segments.push(new TextSegment('normal', content))
      }
    }
    
    return segments
  }
}

export class TextSegment {
  type: 'normal' | 'bold' | 'italic' | 'code'
  content: string
  
  constructor(type: TextSegmentType, content: string) {
    this.type = type
    this.content = content
  }
}

type TextSegmentType = 'normal' | 'bold' | 'italic' | 'code'