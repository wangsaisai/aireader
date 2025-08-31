import dataPreferences from '@ohos.data.preferences'
import { ClientChatSession } from '../model/ClientChatModels'
import { QAMessage } from '../model/QAMessage'
import { BookInfo } from '../model/BookInfo'

// 定义序列化会话数据的接口
interface SerializedSession {
  id: string
  title: string
  bookName?: string
  bookInfo?: Object
  messages: SerializedMessage[]
  createdAt: string
  updatedAt: string
  isActive: boolean
}

interface SerializedMessage {
  content: string
  type: 'question' | 'answer'
  timestamp?: string
}

export class StorageManager {
  private static instance: StorageManager
  private dataStore: dataPreferences.Preferences | null = null
  private readonly STORE_NAME = 'chat_sessions_store'
  private readonly SESSIONS_KEY = 'chat_sessions'
  private readonly CURRENT_SESSION_KEY = 'current_session_id'
  
  private constructor() {}
  
  static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager()
    }
    return StorageManager.instance
  }
  
  async init(context: Context) {
    try {
      this.dataStore = await dataPreferences.getPreferences(context, this.STORE_NAME)
      console.log('StorageManager initialized successfully')
    } catch (error) {
      console.error('Failed to initialize StorageManager:', error)
    }
  }
  
  private ensureInitialized(): boolean {
    if (!this.dataStore) {
      console.error('StorageManager not initialized')
      return false
    }
    return true
  }
  
  // 保存会话列表
  async saveSessions(sessions: ClientChatSession[]): Promise<boolean> {
    if (!this.ensureInitialized()) return false
    
    try {
      // 序列化会话数据
      const serializedSessions: SerializedSession[] = sessions.map(session => {
        const serializedSession: SerializedSession = {
          id: session.id,
          title: session.title,
          bookName: session.bookName,
          bookInfo: session.bookInfo,
          messages: session.messages.map(msg => {
            const serializedMsg: SerializedMessage = {
              content: msg.content,
              type: msg.type,
              timestamp: msg.timestamp ? msg.timestamp.toString() : undefined
            }
            return serializedMsg
          }),
          createdAt: session.createdAt.getTime().toString(),
          updatedAt: session.updatedAt.getTime().toString(),
          isActive: session.isActive
        }
        return serializedSession
      })
      
      await this.dataStore!.put(this.SESSIONS_KEY, JSON.stringify(serializedSessions))
      await this.dataStore!.flush()
      console.log('Sessions saved successfully')
      return true
    } catch (error) {
      console.error('Failed to save sessions:', error)
      return false
    }
  }
  
  // 加载会话列表
  async loadSessions(): Promise<ClientChatSession[]> {
    if (!this.ensureInitialized()) return []
    
    try {
      const sessionsData = await this.dataStore!.get(this.SESSIONS_KEY, '[]')
      const serializedSessions: SerializedSession[] = JSON.parse(sessionsData as string)
      
      if (!Array.isArray(serializedSessions)) {
        console.warn('Invalid sessions data format')
        return []
      }
      
      // 反序列化会话数据
      const sessions: ClientChatSession[] = serializedSessions.map((sessionData: SerializedSession) => {
        const messages = (sessionData.messages || []).map((msg: SerializedMessage) => {
          const qaMessage = new QAMessage(msg.content, msg.type)
          if (msg.timestamp) {
            qaMessage.timestamp = parseInt(msg.timestamp)
          }
          return qaMessage
        })
        
        const session: ClientChatSession = {
          id: sessionData.id,
          title: sessionData.title,
          bookName: sessionData.bookName,
          bookInfo: sessionData.bookInfo,
          messages: messages,
          createdAt: new Date(parseInt(sessionData.createdAt)),
          updatedAt: new Date(parseInt(sessionData.updatedAt)),
          isActive: sessionData.isActive
        }
        return session
      })
      
      console.log(`Loaded ${sessions.length} sessions`)
      return sessions
    } catch (error) {
      console.error('Failed to load sessions:', error)
      return []
    }
  }
  
  // 保存当前会话ID
  async saveCurrentSessionId(sessionId: string): Promise<boolean> {
    if (!this.ensureInitialized()) return false
    
    try {
      await this.dataStore!.put(this.CURRENT_SESSION_KEY, sessionId)
      await this.dataStore!.flush()
      console.log('Current session ID saved successfully')
      return true
    } catch (error) {
      console.error('Failed to save current session ID:', error)
      return false
    }
  }
  
  // 加载当前会话ID
  async loadCurrentSessionId(): Promise<string> {
    if (!this.ensureInitialized()) return ''
    
    try {
      const sessionId = await this.dataStore!.get(this.CURRENT_SESSION_KEY, '')
      console.log('Current session ID loaded:', sessionId)
      return sessionId as string
    } catch (error) {
      console.error('Failed to load current session ID:', error)
      return ''
    }
  }
  
  // 清除所有数据
  async clearAllData(): Promise<boolean> {
    if (!this.ensureInitialized()) return false
    
    try {
      await this.dataStore!.delete(this.SESSIONS_KEY)
      await this.dataStore!.delete(this.CURRENT_SESSION_KEY)
      await this.dataStore!.flush()
      console.log('All data cleared successfully')
      return true
    } catch (error) {
      console.error('Failed to clear data:', error)
      return false
    }
  }
  
  // 检查是否有数据
  async hasData(): Promise<boolean> {
    if (!this.ensureInitialized()) return false
    
    try {
      const sessionsData = await this.dataStore!.get(this.SESSIONS_KEY, '[]')
      const sessions: SerializedSession[] = JSON.parse(sessionsData as string)
      return Array.isArray(sessions) && sessions.length > 0
    } catch (error) {
      console.error('Failed to check data existence:', error)
      return false
    }
  }
}