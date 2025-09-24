// aireader_hm/entry/src/main/ets/components/PromptSuggestions.ets
import { PromptSuggestion } from '../model/Prompt';

@Component
export struct PromptSuggestions {
  @Prop suggestions: PromptSuggestion[];
  onSuggestionClick: (suggestion: PromptSuggestion) => void = (suggestion: PromptSuggestion) => {};


  build() {
    Column() {
      Text($r('app.string.try_these_questions'))
        .fontSize(14)
        .fontColor($r('app.color.suggestion_text'))
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.suggestions, (item: PromptSuggestion) => {
          Text(item.title)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor($r('app.color.suggestion_bg'))
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
