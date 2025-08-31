// aireader_hm/entry/src/main/ets/components/PromptSuggestions.ets
import { PromptSuggestion } from '../model/Prompt';

@Component
export struct PromptSuggestions {
  @Prop suggestions: PromptSuggestion[];
  onSuggestionClick: (suggestion: PromptSuggestion) => void = (suggestion: PromptSuggestion) => {};


  build() {
    Column() {
      Text('您可以尝试以下问题：')
        .fontSize(14)
        .fontColor('#999')
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.suggestions, (item: PromptSuggestion) => {
          Text(item.title)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#f0f0f0')
            .borderRadius(16)
            .fontSize(12)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              if (this.onSuggestionClick) {
                this.onSuggestionClick(item);
              }
            })
        })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .margin({ bottom: 10 })
  }
}
