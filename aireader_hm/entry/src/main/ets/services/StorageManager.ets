// 引入鸿蒙依赖
import preferences from '@ohos.data.preferences';

// 引入项目内模块
import { ClientChatSession } from '../model/ClientChatModels';
import { QAMessage } from '../model/QAMessage';
import { BookInfo } from '../model/BookInfo';

// 定义用于序列化的数据接口
interface SerializedSession {
  id: string;
  title: string;
  bookName?: string;
  bookInfo?: BookInfo;
  messages: QAMessage[];
  createdAt: string; // 使用ISO 8601字符串格式
  updatedAt: string; // 使用ISO 8601字符串格式
  isActive: boolean;
}

// 单例数据存储管理器
export class StorageManager {
  private static instance: StorageManager;
  private pref: preferences.Preferences | null = null;
  private readonly PREF_NAME = 'gemini_chat_preferences';

  private constructor() {}

  static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager();
    }
    return StorageManager.instance;
  }

  // 初始化
  async init(context: Context): Promise<boolean> {
    try {
      this.pref = await preferences.getPreferences(context, this.PREF_NAME);
      console.info('StorageManager initialized successfully');
      return true;
    } catch (e) {
      console.error('StorageManager failed to initialize:', e);
      return false;
    }
  }

  // 检查是否初始化
  private isInitialized(): boolean {
    if (!this.pref) {
      console.error('StorageManager not initialized');
      return false;
    }
    return true;
  }

  // 保存会话
  async saveSessions(sessions: ClientChatSession[]): Promise<boolean> {
    if (!this.isInitialized()) return false;
    try {
      const serializedSessions: SerializedSession[] = sessions.map((session: ClientChatSession): SerializedSession => {
        const serializedSession: SerializedSession = {
          id: session.id,
          title: session.title,
          bookName: session.bookName,
          bookInfo: session.bookInfo,
          messages: session.messages.map((msg: QAMessage) => {
            const newMsg = new QAMessage(msg.content, msg.type);
            newMsg.id = msg.id;
            newMsg.timestamp = msg.timestamp;
            return newMsg;
          }),
          createdAt: session.createdAt.toISOString(),
          updatedAt: session.updatedAt.toISOString(),
          isActive: session.isActive,
        };
        return serializedSession;
      });
      await this.pref!.put('chatSessions', JSON.stringify(serializedSessions));
      await this.pref!.flush();
      return true;
    } catch (e) {
      console.error('Failed to save sessions:', e);
      return false;
    }
  }

  // 加载会话
  async loadSessions(): Promise<ClientChatSession[]> {
    if (!this.isInitialized()) return [];
    try {
      const sessionsData = await this.pref!.get('chatSessions', '[]');
      const serializedSessions: SerializedSession[] = JSON.parse(sessionsData as string);

      if (!Array.isArray(serializedSessions)) {
        return [];
      }

      return serializedSessions.map((s: SerializedSession): ClientChatSession => {
        const session: ClientChatSession = {
          id: s.id,
          title: s.title,
          bookName: s.bookName,
          bookInfo: s.bookInfo,
          messages: s.messages,
          createdAt: new Date(s.createdAt),
          updatedAt: new Date(s.updatedAt),
          isActive: s.isActive,
        };
        return session;
      });
    } catch (e) {
      console.error('Failed to load sessions:', e);
      return [];
    }
  }

  // 保存当前会话ID
  async saveCurrentSessionId(id: string): Promise<boolean> {
    if (!this.isInitialized()) return false;
    try {
      await this.pref!.put('currentSessionId', id);
      await this.pref!.flush();
      return true;
    } catch (e) {
      console.error('Failed to save current session ID:', e);
      return false;
    }
  }

  // 加载当前会话ID
  async loadCurrentSessionId(): Promise<string> {
    if (!this.isInitialized()) return '';
    try {
      const id = await this.pref!.get('currentSessionId', '');
      return id as string;
    } catch (e) {
      console.error('Failed to load current session ID:', e);
      return '';
    }
  }
}
