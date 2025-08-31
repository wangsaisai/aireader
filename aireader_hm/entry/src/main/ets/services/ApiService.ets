import http from '@ohos.net.http'
import { BookInfo, BookInfoData } from '../model/BookInfo'
import { ChatRequest, ChatMessage as ChatMessageModel } from '../model/ChatModels'

export class ApiService {
  private static readonly BASE_URL = 'http://34.176.0.152:8080'
  
  static async getBookInfo(bookName: string): Promise<BookInfo> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/book/info`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: { book_name: bookName }
        }
      )
      httpRequest.destroy()

      const result = JSON.parse(response.result as string) as ApiResponse
      if (result.success && result.data) {
        return new BookInfo(result.data as BookInfoData)
      } else {
        throw new Error(result.message || result.error || '获取书籍信息失败')
      }
    } catch (error) {
      // Catch all errors, including network and logical ones from the server.
      const err = error as Error
      throw new Error(err.message || '网络请求或处理失败')
    }
  }
  
  static async askQuestion(bookName: string, question: string): Promise<string> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/book/qa`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: { book_name: bookName, question: question }
        }
      )
      httpRequest.destroy()

      const result = JSON.parse(response.result as string) as ApiResponse
      if (result.success && result.data) {
        return (result.data as QAData).answer
      } else {
        throw new Error(result.message || result.error || '获取回答失败')
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || '网络请求或处理失败')
    }
  }
  
  // ===== 无状态对话API =====
  
  static async chatWithHistory(request: ChatRequest): Promise<string> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/chat/ask`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: {
            book_name: request.bookName,
            messages: request.messages,
            question: request.question
          }
        }
      )
      httpRequest.destroy()

      const result = JSON.parse(response.result as string) as ApiResponse
      if (result.success && result.data) {
        return (result.data as QAData).answer
      } else {
        throw new Error(result.message || result.error || '获取回答失败')
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || '网络请求或处理失败')
    }
  }
  static async generateDetailedReport(bookName: string, author: string | undefined): Promise<string> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/chat/generate_report`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: { book_name: bookName, author: author },
          readTimeout: 180000, // 设置3分钟超时
          connectTimeout: 5000
        }
      )
      httpRequest.destroy()

      const result = JSON.parse(response.result as string) as ApiResponse
      if (result.success && result.data) {
        return (result.data as ReportData).report
      } else {
        throw new Error(result.message || result.error || '生成详细报告失败')
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || '网络请求或处理失败')
    }
  }
}

export interface ApiResponse {
  success: boolean
  data?: Object | QAData | ReportData
  error?: string
  message?: string
}


export interface QAData {
  answer: string
}

export interface ReportData {
  report: string
}

interface ErrorWithCode {
  code?: number
}

export class ErrorHandler {
  static handleApiError(error: Error): string {
    const errorCode = (error as ErrorWithCode).code
    if (errorCode) {
      switch (errorCode) {
        case 401:
          return 'API认证失败'
        case 404:
          return '请求的资源不存在'
        case 500:
          return '服务器内部错误'
        default:
          return '网络请求失败'
      }
    }
    return '网络请求失败'
  }
}