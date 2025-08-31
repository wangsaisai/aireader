import { QAMessage } from './QAMessage'
import { ChatMessage } from './ChatModels'

export interface ClientChatSession {
  id: string
  title: string
  bookName?: string
  bookInfo?: Object
  messages: QAMessage[]
  createdAt: Date
  updatedAt: Date
  isActive: boolean
}

export interface ClientSessionManager {
  sessions: ClientChatSession[]
  currentSessionId: string
  createSession: (title: string, bookName?: string) => ClientChatSession
  switchSession: (sessionId: string) => void
  deleteSession: (sessionId: string) => void
  getCurrentSession: () => ClientChatSession | null
  addMessageToCurrentSession: (message: QAMessage) => void
  getChatHistoryForAPI: (sessionId: string) => ChatMessage[]
}