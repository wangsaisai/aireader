
    import { promptAction } from '@kit.ArkUI'

    @CustomDialog
    export struct FeedbackDialog {
      controller?: CustomDialogController
      messageId: string = ''
      onSubmit: (reasons: string[], details: string) => void | Promise<void> = () => {}
      @State selectedReasons: Resource[] = []
      @State otherReason: string = ''
      private reasons: Resource[] = [$r('app.string.feedback_reason_inaccurate'), $r('app.string.feedback_reason_irrelevant'), $r('app.string.feedback_reason_harmful'), $r('app.string.feedback_reason_format')]

      build() {
        Column() {
          Text($r('app.string.feedback_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 15 })

          // Predefined reasons
          ForEach(this.reasons, (reason: Resource) => {
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
          }, (item: Resource) => `${item.id}`)

          // Other reason input
          TextInput({ placeholder: $r('app.string.feedback_other_placeholder'), text: this.otherReason })
            .onChange((value) => {
              this.otherReason = value
            })
            .margin({ top: 10 })

          // Action buttons
          Row() {
            Button($r('app.string.cancel'))
              .onClick(() => {
                if (this.controller) {
                  this.controller.close()
                }
              })
            Button($r('app.string.submit'))
              .margin({ left: 10 })
              .onClick(async () => {
                if (this.selectedReasons.length === 0 && !this.otherReason.trim()) {
                  promptAction.showToast({ message: `${$r('app.string.feedback_prompt')}` })
                  return
                }
                const context = getContext(this)
                const resolvedReasons = await Promise.all(
                  this.selectedReasons.map(res => context.resourceManager.getStringValue(res))
                )
                await this.onSubmit(resolvedReasons, this.otherReason)
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
    