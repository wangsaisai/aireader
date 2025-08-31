export class BookInfo {
  title: string = ''
  author: string = ''
  publisher: string = ''
  year: string = ''
  isbn: string = ''
  description: string = ''
  summary: string = ''
  is_found: boolean = false
  not_found_reason: string = ''

  
  constructor(data?: BookInfoData) {
    if (data) {
      this.title = data.title || ''
      this.author = data.author || ''
      this.publisher = data.publisher || ''
      this.year = data.year || ''
      this.isbn = data.isbn || ''
      this.description = data.description || ''
      this.summary = data.summary || ''
      this.is_found = data.is_found || false
      this.not_found_reason = data.not_found_reason || ''
    }
  }
}

export interface BookInfoData {
  title?: string
  author?: string
  publisher?: string
  year?: string
  isbn?: string
  description?: string
  summary?: string
  is_found?: boolean
  not_found_reason?: string
}