export interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
}

export interface ChatRequest {
  bookName: string
  messages: ChatMessage[]
  question: string
}