import { BookInfo } from '../model/BookInfo'

@Component
export struct BookInfoComponent {
  @Prop bookInfo: BookInfo
  
  build() {
    Column() {
      Text($r('app.string.book_info'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
      
      if (this.bookInfo.title) {
        Text(`${$r('app.string.book_title')}: ${this.bookInfo.title}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.author) {
        Text(`${$r('app.string.book_author')}: ${this.bookInfo.author}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.publisher) {
        Text(`${$r('app.string.book_publisher')}: ${this.bookInfo.publisher}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.year) {
        Text(`${$r('app.string.book_year')}: ${this.bookInfo.year}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.isbn) {
        Text(`${$r('app.string.book_isbn')}: ${this.bookInfo.isbn}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.description) {
        Text(`${$r('app.string.book_description')}:`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 8 })
        
        Text(this.bookInfo.description)
          .fontSize(14)
          .lineHeight(20)
          .margin({ bottom: 15 })
      }
      
      if (this.bookInfo.summary) {
        Text(`${$r('app.string.book_summary')}:`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 8 })
        
        Text(this.bookInfo.summary)
          .fontSize(14)
          .lineHeight(20)
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#f5f5f5')
    .borderRadius(10)
  }
}