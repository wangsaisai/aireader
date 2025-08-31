import { ClientChatSession } from '../model/ClientChatModels'
import { QAMessage } from '../model/QAMessage'
import { ChatMessage } from '../model/ChatModels'
import { StorageManager } from './StorageManager'

export class ClientSessionManager {
  private sessions: ClientChatSession[] = []
  private currentSessionId: string = ''
  private storageManager: StorageManager
  private isInitialized: boolean = false
  private initializationPromise: Promise<void>
  
  constructor() {
    this.storageManager = StorageManager.getInstance()
    this.initializationPromise = this.initializeStorage()
  }
  
  // 初始化存储管理器
  private async initializeStorage() {
    try {
      // 获取上下文并初始化存储
      const context = this.getContext()
      if (context) {
        await this.storageManager.init(context)
      }
      this.isInitialized = true
      await this.loadSessions()
    } catch (error) {
      console.error('初始化存储失败:', error)
      // 如果存储初始化失败，稍后会创建默认会话
    }
  }
  
  // 获取上下文的方法
  private getContext(): Context | null {
    try {
      // 尝试获取上下文
      const context = getContext(this)
      return context as Context
    } catch (error) {
      console.warn('无法获取上下文:', error)
      return null
    }
  }
  
  // 从持久化存储加载会话
  private async loadSessions() {
    if (!this.isInitialized) {
      console.warn('StorageManager not initialized yet')
      return
    }
    
    try {
      // 从持久化存储加载会话数据
      const storedSessions = await this.storageManager.loadSessions()
      const storedCurrentId = await this.storageManager.loadCurrentSessionId()
      
      if (storedSessions && storedSessions.length > 0) {
        this.sessions = storedSessions
      } else {
        // 如果没有持久化数据，尝试从AppStorage加载（向后兼容）
        const appStorageSessions: ClientChatSession[] | null | undefined = AppStorage.Get('chatSessions')
        if (appStorageSessions && Array.isArray(appStorageSessions)) {
          this.sessions = appStorageSessions as ClientChatSession[]
          this.sessions.forEach(session => {
            session.createdAt = new Date(session.createdAt)
            session.updatedAt = new Date(session.updatedAt)
          })
        }
      }
      
      if (storedCurrentId) {
        this.currentSessionId = storedCurrentId
      } else {
        // 尝试从AppStorage加载当前会话ID
        const appStorageCurrentId: string | null | undefined = AppStorage.Get('currentSessionId')
        if (appStorageCurrentId && typeof appStorageCurrentId === 'string') {
          this.currentSessionId = appStorageCurrentId
        }
      }
      
      // 如果没有会话，创建一个默认会话
      if (this.sessions.length === 0) {
        // 注意：这里不能直接await，会导致循环依赖
        // 我们将在外面处理默认会话的创建
        console.log('No sessions found, will create default session')
      }
    } catch (error) {
      console.error('加载会话失败:', error)
      await this.createSession('新对话')
    }
  }
  
  // 保存会话到持久化存储
  private async saveSessions() {
    // 仍然保存到AppStorage以保持向后兼容
    try {
      AppStorage.Set('chatSessions', this.sessions)
      AppStorage.Set('currentSessionId', this.currentSessionId)
    } catch (error) {
      console.error('保存到AppStorage失败:', error)
    }
    
    // 保存到持久化存储
    if (!this.isInitialized) {
      console.warn('StorageManager not initialized, skipping persistent save')
      return
    }
    
    try {
      await this.storageManager.saveSessions(this.sessions)
      await this.storageManager.saveCurrentSessionId(this.currentSessionId)
    } catch (error) {
      console.error('保存到持久化存储失败:', error)
    }
  }
  
  // 创建新会话
  async createSession(title: string, bookName?: string): Promise<ClientChatSession> {
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
    await this.saveSessions()
    
    return newSession
  }
  
  // 切换会话
  async switchSession(sessionId: string): Promise<boolean> {
    const session = this.sessions.find(s => s.id === sessionId)
    if (session) {
      this.currentSessionId = sessionId
      await this.saveSessions()
      return true
    }
    return false
  }
  
  // 删除会话
  async deleteSession(sessionId: string): Promise<boolean> {
    const index = this.sessions.findIndex(s => s.id === sessionId)
    if (index !== -1) {
      this.sessions.splice(index, 1)
      
      // 如果删除的是当前会话，切换到第一个会话
      if (sessionId === this.currentSessionId) {
        if (this.sessions.length > 0) {
          this.currentSessionId = this.sessions[0].id
        } else {
          await this.createSession('新对话')
        }
      }
      
      await this.saveSessions()
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
  async addMessageToCurrentSession(message: QAMessage): Promise<void> {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.messages.push(message)
      currentSession.updatedAt = new Date()
      await this.saveSessions()
    }
  }
  
  // 清空当前会话消息
  async clearCurrentSessionMessages(): Promise<void> {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.messages = []
      currentSession.updatedAt = new Date()
      await this.saveSessions()
    }
  }
  
  // 更新会话书籍信息
  async updateCurrentSessionBookInfo(bookName: string, bookInfo: Object): Promise<void> {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.bookName = bookName
      currentSession.bookInfo = bookInfo
      // 使用书籍名称作为会话标题
      currentSession.title = `📚 ${bookName}`
      currentSession.updatedAt = new Date()
      await this.saveSessions()
    }
  }

  async clearCurrentSessionBookInfo(): Promise<void> {
    const currentSession = this.getCurrentSession()
    if (currentSession) {
      currentSession.bookName = undefined
      currentSession.bookInfo = undefined
      // Optionally reset title if it was based on the book name
      if (currentSession.title.startsWith('📚')) {
        currentSession.title = '新对话'
      }
      currentSession.updatedAt = new Date()
      await this.saveSessions()
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
  
  // 确保初始化完成
  async ensureInitialized(): Promise<void> {
    await this.initializationPromise
  }
  
  // 检查是否需要创建默认会话
  async ensureDefaultSession(): Promise<void> {
    if (this.sessions.length === 0) {
      await this.createSession('新对话')
    }
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