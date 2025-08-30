export class QAMessage {
  content: string = ''
  type: 'question' | 'answer' = 'question'
  timestamp: number = Date.now()
  
  constructor(content: string, type: 'question' | 'answer') {
    this.content = content
    this.type = type
  }
}