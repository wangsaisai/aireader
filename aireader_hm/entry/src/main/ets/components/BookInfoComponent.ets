import { BookInfo } from '../model/BookInfo'

@Component
export struct BookInfoComponent {
  @Prop bookInfo: BookInfo
  
  build() {
    Column() {
      Text('书籍信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
      
      if (this.bookInfo.title) {
        Text(`书名: ${this.bookInfo.title}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.author) {
        Text(`作者: ${this.bookInfo.author}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.publisher) {
        Text(`出版社: ${this.bookInfo.publisher}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.year) {
        Text(`出版年份: ${this.bookInfo.year}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.isbn) {
        Text(`ISBN: ${this.bookInfo.isbn}`)
          .fontSize(16)
          .margin({ bottom: 8 })
      }
      
      if (this.bookInfo.description) {
        Text('简介:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 8 })
        
        Text(this.bookInfo.description)
          .fontSize(14)
          .lineHeight(20)
          .margin({ bottom: 15 })
      }
      
      if (this.bookInfo.summary) {
        Text('内容概述:')
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