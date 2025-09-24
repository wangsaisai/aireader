// aireader_hm/entry/src/main/ets/services/PromptService.ets
import { PromptSuggestion } from '../model/Prompt';

export class PromptService {
  static getBookAnalysisPrompts(): PromptSuggestion[] {
    return [
      {
        id: '1',
        title: $r('app.string.prompt_title_core_insights'),
        prompt: $r('app.string.prompt_prompt_core_insights')
      },
      {
        id: '2',
        title: $r('app.string.prompt_title_key_concepts'),
        prompt: $r('app.string.prompt_prompt_key_concepts')
      },
      {
        id: '3',
        title: $r('app.string.prompt_title_quotes'),
        prompt: $r('app.string.prompt_prompt_quotes')
      },
      {
        id: '4',
        title: $r('app.string.prompt_title_reviews'),
        prompt: $r('app.string.prompt_prompt_reviews')
      },
      {
        id: '5',
        title: $r('app.string.prompt_title_reading_strategies'),
        prompt: $r('app.string.prompt_prompt_reading_strategies')
      },
      {
        id: '6',
        title: $r('app.string.prompt_title_target_audience'),
        prompt: $r('app.string.prompt_prompt_target_audience')
      },
      {
        id: '7',
        title: $r('app.string.prompt_title_generate_report'),
        prompt: $r('app.string.prompt_prompt_generate_report')
      }
    ];
  }
}
