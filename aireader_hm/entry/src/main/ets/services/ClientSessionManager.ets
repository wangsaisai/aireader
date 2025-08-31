import { ClientChatSession } from '../model/ClientChatModels'
import { QAMessage } from '../model/QAMessage'
import { ChatMessage } from '../model/ChatModels'

export class ClientSessionManager {
  private sessions: ClientChatSession[] = []
  private currentSessionId: string = ''
  
  constructor() {
    this.loadSessions()
  }
  
  // 从AppStorage加载会话
  loadSessions() {
    try {
      const storedSessions: ClientChatSession[] | null | undefined = AppStorage.Get('chatSessions')
      const storedCurrentId: string | null | undefined = AppStorage.Get('currentSessionId')
      
      if (storedSessions && Array.isArray(storedSessions)) {
        this.sessions = storedSessions as ClientChatSession[]
        // 转换日期字符串回Date对象
        this.sessions.forEach(session => {
          session.createdAt = new Date(session.createdAt)
          session.updatedAt = new Date(session.updatedAt)
        })
      }
      
      if (storedCurrentId && typeof storedCurrentId === 'string') {
        this.currentSessionId = storedCurrentId
      }
      
      // 如果没有会话，创建一个默认会话
      if (this.sessions.length === 0) {
        this.createSession('新对话')
      }
    } catch (error) {
      console.error('加载会话失败:', error)
      this.createSession('新对话')
    }
  }
  
  // 保存会话到AppStorage
  private saveSessions() {
    try {
      AppStorage.Set('chatSessions', this.sessions)
      AppStorage.Set('currentSessionId', this.currentSessionId)
    } catch (error) {
      console.error('保存会话失败:', error)
    }
  }
  
  // 创建新会话
  createSession(title: string, bookName?: string): ClientChatSession {
    // 如果有书籍名称，使用书籍名称作为标题
    const sessionTitle = bookName ? `📚 ${bookName}` : title
    const newSession: ClientChatSession = {
      id: this.generateId(),
      title: sessionTitle,
      bookName: bookName,
      messages: [],
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true
    }
    
    this.sessions.unshift(newSession)
    this.currentSessionId = newSession.id
    this.saveSessions()
    
    return newSession
  }
  
  // 切换会话
  switchSession(sessionId: string): boolean {
    const session = this.sessions.find(s => s.id === sessionId)
    if (session) {
      this.currentSessionId = sessionId
      this.saveSessions()
      return true
    }
    return false
  }
  
  // 删除会话
  deleteSession(sessionId: string): boolean {
    const index = this.sessions.findIndex(s => s.id === sessionId)
    if (index !== -1) {
      this.sessions.splice(index, 1)
      
      // 如果删除的是当前会话，切换到第一个会话
      if (sessionId === this.currentSessionId) {
        if (this.sessions.length > 0) {
          this.currentSessionId = this.sessions[0].id
        } else {
          this.createSession('新对话')
        }
      }
      
      this.saveSessions()
      return true
    }
    return false
  }
  
  // 获取当前会话
  getCurrentSession(): ClientChatSession | null {
    return this.sessions.find(s => s.id === this.currentSessionId) || null
  }
  
  // 获取所有会话
  getAllSessions(): ClientChatSession[] {
    return this.sessions
  }
  
  // 添加消息到当前会话
  addMessageToCurrentSession(message: QAMessage): void {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.messages.push(message)
      currentSession.updatedAt = new Date()
      this.saveSessions()
    }
  }
  
  // 清空当前会话消息
  clearCurrentSessionMessages(): void {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.messages = []
      currentSession.updatedAt = new Date()
      this.saveSessions()
    }
  }
  
  // 更新会话书籍信息
  updateCurrentSessionBookInfo(bookName: string, bookInfo: Object): void {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.bookName = bookName
      currentSession.bookInfo = bookInfo
      // 使用书籍名称作为会话标题
      currentSession.title = `📚 ${bookName}`
      currentSession.updatedAt = new Date()
      this.saveSessions()
    }
  }
  
  // 获取用于API的聊天历史
  getChatHistoryForAPI(sessionId: string): ChatMessage[] {
    const session = this.sessions.find(s => s.id === sessionId)
    if (!session) {
      return []
    }
    
    return session.messages.map((msg: QAMessage): ChatMessage => ({
      role: msg.type === 'question' ? 'user' : 'assistant',
      content: msg.content
    }))
  }
  
  // 获取当前会话的聊天历史
  getCurrentChatHistoryForAPI(): ChatMessage[] {
    return this.getChatHistoryForAPI(this.currentSessionId)
  }
  
  // 生成ID
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2)
  }
  
  // 获取会话统计
  getSessionStats(): SessionStats {
    const totalMessages = this.sessions.reduce((sum: number, session: ClientChatSession) => sum + session.messages.length, 0)
    return {
      total: this.sessions.length,
      totalMessages: totalMessages
    }
  }
}

export interface SessionStats {
  total: number
  totalMessages: number
}