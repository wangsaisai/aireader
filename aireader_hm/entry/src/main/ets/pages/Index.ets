import router from '@ohos.router'
import { BookInfo } from '../model/BookInfo'
import { ApiService } from '../services/ApiService'
import { BookInfoComponent } from '../components/BookInfoComponent'
import { LoadingComponent } from '../components/LoadingComponent'

@Entry
@Component
struct Index {
  @State bookName: string = ''
  @State isLoading: boolean = false
  @State bookInfo: BookInfo | null = null
  @State errorMessage: string = ''

  async queryBookInfo() {
    if (!this.bookName.trim()) {
      this.errorMessage = '请输入书籍名称'
      return
    }

    this.isLoading = true
    this.errorMessage = ''
    
    try {
      this.bookInfo = await ApiService.getBookInfo(this.bookName.trim())
    } catch (error) {
      this.errorMessage = error.message || '查询失败，请稍后重试'
      this.bookInfo = null
    } finally {
      this.isLoading = false
    }
  }

  navigateToQA() {
    if (this.bookInfo) {
      router.pushUrl({
        url: 'pages/QAPage',
        params: { 
          bookName: this.bookInfo.title,
          bookInfo: this.bookInfo 
        }
      })
    }
  }

  build() {
    Column() {
      Text('AI读书助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      TextInput({ placeholder: '请输入书籍名称' })
        .width('100%')
        .height(40)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.bookName = value
          this.errorMessage = ''
        })
      
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ bottom: 10 })
      }
      
      Button('查询书籍信息')
        .width('100%')
        .height(50)
        .margin({ bottom: 20 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.queryBookInfo()
        })
      
      if (this.isLoading) {
        LoadingComponent()
      }
      
      if (this.bookInfo) {
        Scroll() {
          BookInfoComponent({ bookInfo: this.bookInfo })
        }
        .layoutWeight(1)
        .width('100%')
        .margin({ bottom: 20 })
        
        Button('开始问答')
          .width('100%')
          .height(50)
          .onClick(() => {
            this.navigateToQA()
          })
      }
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}