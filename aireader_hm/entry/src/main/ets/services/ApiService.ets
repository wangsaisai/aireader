import http from '@ohos.net.http'
import { BookInfo, BookInfoData } from '../model/BookInfo'
import { ChatRequest, ChatMessage as ChatMessageModel } from '../model/ChatModels'
import { ComplaintData, LikeData } from '../model/Complaint'

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
        throw new Error(result.message || result.error || `${$r('app.string.error_get_book_info_failed')}`)
      }
    } catch (error) {
      // Catch all errors, including network and logical ones from the server.
      const err = error as Error
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`)
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
        throw new Error(result.message || result.error || `${$r('app.string.error_get_answer_failed')}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`)
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
        throw new Error(result.message || result.error || `${$r('app.string.error_get_answer_failed')}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`)
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
        throw new Error(result.message || result.error || `${$r('app.string.error_generate_report_failed')}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`)
    }
  }

  static async deleteSession(sessionId: string): Promise<boolean> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/chat/session/${sessionId}`,
        {
          method: http.RequestMethod.DELETE,
          header: { 'Content-Type': 'application/json' }
        }
      )
      httpRequest.destroy()

      const result = JSON.parse(response.result as string) as ApiResponse
      if (result.success) {
        return true
      } else {
        throw new Error(result.message || result.error || `${$r('app.string.error_delete_session_failed')}`)
      }
    } catch (error) {
      const err = error as Error
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`)
    }
  }

  static async submitComplaint(complaintData: ComplaintData): Promise<boolean> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/complaint`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: complaintData
        }
      );
      httpRequest.destroy();

      const result = JSON.parse(response.result as string) as ApiResponse;
      if (result.success) {
        return true;
      } else {
        throw new Error(result.message || result.error || `${$r('app.string.error_submit_complaint_failed')}`);
      }
    } catch (error) {
      const err = error as Error;
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`);
    }
  }

  static async submitLike(likeData: LikeData): Promise<boolean> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${ApiService.BASE_URL}/api/like`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: likeData
        }
      );
      httpRequest.destroy();

      const result = JSON.parse(response.result as string) as ApiResponse;
      if (result.success) {
        return true;
      } else {
        throw new Error(result.message || result.error || `${$r('app.string.error_like_failed')}`);
      }
    } catch (error) {
      const err = error as Error;
      throw new Error(err.message || `${$r('app.string.error_network_request_failed')}`);
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
          return `${$r('app.string.error_api_auth_failed')}`
        case 404:
          return `${$r('app.string.error_resource_not_found')}`
        case 500:
          return `${$r('app.string.error_server_internal_error')}`
        default:
          return `${$r('app.string.error_network_request_failed_default')}`
      }
    }
    return `${$r('app.string.error_network_request_failed_default')}`
  }
}