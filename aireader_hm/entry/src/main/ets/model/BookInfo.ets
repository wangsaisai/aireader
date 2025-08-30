export class BookInfo {
  title: string = ''
  author: string = ''
  publisher: string = ''
  year: string = ''
  isbn: string = ''
  description: string = ''
  summary: string = ''
  
  constructor(data?: BookInfoData) {
    if (data) {
      this.title = data.title || ''
      this.author = data.author || ''
      this.publisher = data.publisher || ''
      this.year = data.year || ''
      this.isbn = data.isbn || ''
      this.description = data.description || ''
      this.summary = data.summary || ''
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
}