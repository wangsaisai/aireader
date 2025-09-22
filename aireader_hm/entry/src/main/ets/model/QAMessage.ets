export class QAMessage {
  id: string;
  content: string = '';
  type: 'question' | 'answer' = 'question';
  timestamp: number = Date.now();

  constructor(content: string, type: 'question' | 'answer') {
    this.id = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    this.content = content;
    this.type = type;
  }
}