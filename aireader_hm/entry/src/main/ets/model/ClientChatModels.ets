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
  createSession: (title: string, bookName?: string) => Promise<ClientChatSession>
  switchSession: (sessionId: string) => Promise<boolean>
  deleteSession: (sessionId: string) => Promise<boolean>
  getCurrentSession: () => ClientChatSession | null
  addMessageToCurrentSession: (message: QAMessage) => Promise<void>
  getChatHistoryForAPI: (sessionId: string) => ChatMessage[]
}