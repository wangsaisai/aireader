export class MarkdownUtils {
  static parseMarkdown(text: string): Array<MarkdownElement> {
    const elements: MarkdownElement[] = []
    const lines = text.split('\n')
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]
      const trimmed = line.trim()
      
      if (trimmed === '') {
        elements.push(new MarkdownElement('paragraph', ''))
        continue
      }
      
      if (trimmed.startsWith('# ')) {
        elements.push(new MarkdownElement('h1', trimmed.substring(2)))
      } else if (trimmed.startsWith('## ')) {
        elements.push(new MarkdownElement('h2', trimmed.substring(3)))
      } else if (trimmed.startsWith('### ')) {
        elements.push(new MarkdownElement('h3', trimmed.substring(4)))
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        elements.push(new MarkdownElement('li', trimmed.substring(2)))
      } else if (trimmed.startsWith('1. ')) {
        elements.push(new MarkdownElement('li', trimmed.substring(3), true))
      } else if (trimmed.startsWith('```')) {
        const codeBlock = MarkdownUtils.extractCodeBlock(lines, i)
        elements.push(new MarkdownElement('code', codeBlock.content))
        i += codeBlock.linesSkipped
      } else if (trimmed.startsWith('> ')) {
        elements.push(new MarkdownElement('quote', trimmed.substring(2)))
      } else if (trimmed.includes('**') || trimmed.includes('*')) {
        elements.push(new MarkdownElement('paragraph', MarkdownUtils.parseInlineFormatting(trimmed)))
      } else {
        elements.push(new MarkdownElement('paragraph', line))
      }
    }
    
    return elements
  }
  
  private static extractCodeBlock(lines: string[], startIndex: number): CodeBlockResult {
    let content = ''
    let linesSkipped = 0
    
    for (let i = startIndex + 1; i < lines.length; i++) {
      const line = lines[i]
      if (line.trim().startsWith('```')) {
        linesSkipped = i - startIndex
        break
      }
      content += line + '\n'
    }
    
    return { content: content.trim(), linesSkipped }
  }
  
  private static parseInlineFormatting(text: string): string {
    return text
      .replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
      .replace(/\*(.*?)\*/g, '<i>$1</i>')
      .replace(/`(.*?)`/g, '<code>$1</code>')
  }
}

export class MarkdownElement {
  type: 'h1' | 'h2' | 'h3' | 'paragraph' | 'li' | 'code' | 'quote'
  content: string
  isOrdered?: boolean
  
  constructor(type: MarkdownElementType, content: string, isOrdered?: boolean) {
    this.type = type
    this.content = content
    this.isOrdered = isOrdered
  }
}

interface CodeBlockResult {
  content: string
  linesSkipped: number
}

type MarkdownElementType = 'h1' | 'h2' | 'h3' | 'paragraph' | 'li' | 'code' | 'quote'