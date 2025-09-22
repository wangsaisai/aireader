
    import { promptAction } from '@kit.ArkUI'

    @CustomDialog
    export struct FeedbackDialog {
      controller?: CustomDialogController
      messageId: string = ''
      onSubmit: (messageId: string, reasons: string[], details: string) => void = () => {}
      @State selectedReasons: string[] = []
      @State otherReason: string = ''
      private reasons: string[] = ["内容不准确", "回答不相关", "包含有害信息", "格式有问题"]

      build() {
        Column() {
          Text("问题反馈")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 15 })

          // 预设原因
          ForEach(this.reasons, (reason: string) => {
            Row() {
              Toggle({ type: ToggleType.Checkbox, isOn: this.selectedReasons.includes(reason) })
                .onChange((isOn) => {
                  if (isOn) {
                    this.selectedReasons.push(reason)
                  } else {
                    const index = this.selectedReasons.indexOf(reason)
                    if (index > -1) {
                      this.selectedReasons.splice(index, 1)
                    }
                  }
                })
              Text(reason).margin({ left: 8 })
            }
            .width('100%')
            .margin({ bottom: 10 })
          }, (item: string) => item)

          // 其他原因输入框
          TextInput({ placeholder: '请输入其他问题（可选）', text: this.otherReason })
            .onChange((value) => {
              this.otherReason = value
            })
            .margin({ top: 10 })

          // 操作按钮
          Row() {
            Button('取消')
              .onClick(() => {
                if (this.controller) {
                  this.controller.close()
                }
              })
            Button('提交')
              .margin({ left: 10 })
              .onClick(() => {
                if (this.selectedReasons.length === 0 && !this.otherReason.trim()) {
                  promptAction.showToast({ message: '请至少选择一个问题或填写说明' })
                  return
                }
                this.onSubmit(this.messageId, this.selectedReasons, this.otherReason)
                if (this.controller) {
                  this.controller.close()
                }
              })
          }
          .margin({ top: 20 })
        }
        .padding(20)
        .width('90%')
      }
    }
    