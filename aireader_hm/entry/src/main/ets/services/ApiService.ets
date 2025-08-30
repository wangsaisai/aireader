import http from '@ohos.net.http'
import { BookInfo, BookInfoData } from '../model/BookInfo'

export class ApiService {
  private static readonly BASE_URL = 'http://localhost:8000'
  
  static async getBookInfo(bookName: string): Promise<BookInfo> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/book/info`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            book_name: bookName
          }
        }
      )
      
      httpRequest.destroy()
      
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ApiResponse
        if (result.success && result.data) {
          return new BookInfo(result.data as BookInfoData)
        } else {
          throw new Error(result.error || '获取书籍信息失败')
        }
      } else {
        throw new Error(`HTTP错误: ${response.responseCode}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(`网络请求失败: ${err.message}`)
    }
  }
  
  static async askQuestion(bookName: string, question: string): Promise<string> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/book/qa`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            book_name: bookName,
            question: question
          }
        }
      )
      
      httpRequest.destroy()
      
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as ApiResponse
        if (result.success && result.data) {
          const qaData = result.data as QAData
          return qaData.answer
        } else {
          throw new Error(result.error || '获取回答失败')
        }
      } else {
        throw new Error(`HTTP错误: ${response.responseCode}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(`网络请求失败: ${err.message}`)
    }
  }
}

export interface ApiResponse {
  success: boolean
  data?: Object | QAData
  error?: string
}

export interface QAData {
  answer: string
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