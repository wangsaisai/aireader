@Component
export struct LoadingComponent {
  build() {
    Row() {
      LoadingProgress()
        .width(24)
        .height(24)
      
      Text('加载中...')
        .fontSize(14)
        .margin({ left: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(50)
  }
}