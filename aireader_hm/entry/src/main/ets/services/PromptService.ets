// aireader_hm/entry/src/main/ets/services/PromptService.ets
import { PromptSuggestion } from '../model/Prompt';

export class PromptService {
  static getBookAnalysisPrompts(): PromptSuggestion[] {
    return [
      {
        id: '1',
        title: '核心洞见与主要观点',
        prompt: '请深入分析并提炼这本书最核心、最具原创性的深刻洞见和关键论断。'
      },
      {
        id: '2',
        title: '关键概念与理论框架',
        prompt: '请识别并透彻解释书中反复出现的关键概念、术语或理论模型。'
      },
      {
        id: '3',
        title: '名言警句/精彩摘录',
        prompt: '请精选书中能体现核心思想、语言精辟、发人深省的名言警句或经典段落。'
      },
      {
        id: '4',
        title: '评价、争议与影响',
        prompt: '请总结本书在学术界、评论界的主流评价（包含赞誉和批评），并分析其深远影响。'
      },
      {
        id: '5',
        title: '阅读策略与建议',
        prompt: '请为渴望深度理解本书的读者提供具体的阅读方法建议和辅助阅读材料。'
      },
      {
        id: '6',
        title: '目标读者与同类书比较',
        prompt: '请描绘本书最适合的读者群体，并与同类书籍进行对比分析，突出其独特性。'
      },
      {
        id: '7',
        title: '生成详细书籍报告',
        prompt: '生成一份关于这本书的详细报告。'
      }
    ];
  }
}
