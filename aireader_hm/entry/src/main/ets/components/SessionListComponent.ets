import { ClientChatSession } from '../model/ClientChatModels'
import { LoadingComponent } from './LoadingComponent'

export interface SessionItemParams {
  session: ClientChatSession
  isSelected: boolean
  onSelect: () => void
  onDelete: () => void
}

@Component
export struct SessionListComponent {
  @Prop sessions: ClientChatSession[]
  @Prop currentSessionId?: string
  @State isLoading: boolean = false
  
  private onSessionSelect?: (session: ClientChatSession) => void
  private onSessionDelete?: (sessionId: string) => void
  private onNewSession?: () => void
  
  aboutToAppear() {
    // 可以在这里设置回调函数
  }
  
  build() {
    Column() {
      // 顶部标题和新建按钮
      Row() {
        Text('对话会话')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        Button('新建会话')
          .fontSize(14)
          .height(32)
          .onClick(() => {
            if (this.onNewSession) {
              this.onNewSession()
            }
          })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 会话列表
      if (this.isLoading) {
        LoadingComponent()
          .margin({ top: 20 })
      } else if (this.sessions.length === 0) {
        Text('暂无会话')
          .fontSize(14)
          .fontColor('#666')
          .textAlign(TextAlign.Center)
          .margin({ top: 20 })
      } else {
        List() {
          ForEach(this.sessions, (session: ClientChatSession) => {
            ListItem() {
              this.SessionItem({ 
                session: session, 
                isSelected: session.id === this.currentSessionId,
                onSelect: () => {
                  if (this.onSessionSelect) {
                    this.onSessionSelect(session)
                  }
                },
                onDelete: () => {
                  if (this.onSessionDelete) {
                    this.onSessionDelete(session.id)
                  }
                }
              } as SessionItemParams)
            }
          })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
  
  @Builder SessionItem(params: SessionItemParams) {
    Column() {
      // 会话项
      Row() {
        Column() {
          // 会话标题
          Text(params.session.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
          
          // 书籍名称
          if (params.session.bookName) {
            Text(params.session.bookName)
              .fontSize(12)
              .fontColor('#666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ top: 2 })
          }
          
          // 消息数量和时间
          Row() {
            Text(`${params.session.messages.length} 条消息`)
              .fontSize(11)
              .fontColor('#999')
            
            Blank()
            
            Text(this.formatTime(params.session.updatedAt))
              .fontSize(11)
              .fontColor('#999')
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        // 删除按钮
        if (!params.isSelected) {
          Button('删除')
            .fontSize(12)
            .height(24)
            .width(48)
            .backgroundColor('#ff4444')
            .onClick(() => {
              params.onDelete()
            })
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor(params.isSelected ? '#e6f3ff' : '#f5f5f5')
      .borderRadius(8)
      .border({
        width: 1,
        color: params.isSelected ? '#007aff' : '#ddd'
      })
    }
    .width('100%')
    .margin({ bottom: 8 })
    .onClick(() => {
      params.onSelect()
    })
  }
  
  private formatTime(time: Date): string {
    try {
      const now = new Date()
      const diff = now.getTime() - time.getTime()
      
      // 一天内显示时间
      if (diff < 24 * 60 * 60 * 1000) {
        return time.toLocaleTimeString('zh-CN', { 
          hour: '2-digit', 
          minute: '2-digit' 
        })
      }
      // 一周内显示星期
      else if (diff < 7 * 24 * 60 * 60 * 1000) {
        const days = ['日', '一', '二', '三', '四', '五', '六']
        return `星期${days[time.getDay()]}`
      }
      // 更早显示日期
      else {
        return time.toLocaleDateString('zh-CN', {
          month: '2-digit',
          day: '2-digit'
        })
      }
    } catch (e) {
      return time.toString()
    }
  }
}