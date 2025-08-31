import { ClientSessionManager } from '../services/ClientSessionManager'
import { QAMessage } from '../model/QAMessage'
import { LoadingComponent } from '../components/LoadingComponent'

@Entry
@Component
struct TestPersistencePage {
  @State testResults: string[] = []
  @State isRunning: boolean = false
  
  private sessionManager = new ClientSessionManager()
  
  async aboutToAppear() {
    await this.runTests()
  }
  
  async runTests() {
    this.isRunning = true
    this.testResults = []
    
    try {
      // 测试1：初始化会话管理器
      this.addTestResult('🔧 初始化会话管理器...')
      await this.sessionManager.ensureInitialized()
      this.addTestResult('✅ 会话管理器初始化成功')
      
      // 测试2：创建测试会话
      this.addTestResult('📝 创建测试会话...')
      const testSession = await this.sessionManager.createSession('📚 测试书籍', '测试书籍')
      this.addTestResult(`✅ 会话创建成功: ${testSession.title}`)
      
      // 测试3：添加测试消息
      this.addTestResult('💬 添加测试消息...')
      const questionMessage = new QAMessage('这本书讲了什么？', 'question')
      await this.sessionManager.addMessageToCurrentSession(questionMessage)
      
      const answerMessage = new QAMessage('这是一本关于测试的书籍', 'answer')
      await this.sessionManager.addMessageToCurrentSession(answerMessage)
      this.addTestResult('✅ 测试消息添加成功')
      
      // 测试4：获取会话列表
      this.addTestResult('📋 获取会话列表...')
      const sessions = this.sessionManager.getAllSessions()
      this.addTestResult(`✅ 当前会话数量: ${sessions.length}`)
      
      // 测试5：获取当前会话
      this.addTestResult('📖 获取当前会话...')
      const currentSession = this.sessionManager.getCurrentSession()
      if (currentSession) {
        this.addTestResult(`✅ 当前会话: ${currentSession.title}`)
        this.addTestResult(`✅ 消息数量: ${currentSession.messages.length}`)
      } else {
        this.addTestResult('❌ 获取当前会话失败')
      }
      
      // 测试6：切换会话
      if (sessions.length > 1) {
        this.addTestResult('🔄 测试切换会话...')
        const switchResult = await this.sessionManager.switchSession(sessions[0].id)
        if (switchResult) {
          this.addTestResult('✅ 会话切换成功')
        } else {
          this.addTestResult('❌ 会话切换失败')
        }
      }
      
      // 测试7：获取会话统计
      this.addTestResult('📊 获取会话统计...')
      const stats = this.sessionManager.getSessionStats()
      this.addTestResult(`✅ 会话总数: ${stats.total}`)
      this.addTestResult(`✅ 消息总数: ${stats.totalMessages}`)
      
      this.addTestResult('🎉 所有测试完成！')
      
    } catch (error) {
      this.addTestResult(`❌ 测试过程中发生错误: ${error.message}`)
      console.error('Test error:', error)
    } finally {
      this.isRunning = false
    }
  }
  
  addTestResult(result: string) {
    this.testResults.push(result)
    console.log(result)
  }
  
  build() {
    Column() {
      Text('持久化功能测试')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      if (this.isRunning) {
        Row() {
          LoadingComponent()
          Text('测试运行中...')
            .fontSize(16)
            .margin({ left: 10 })
        }
        .margin({ bottom: 20 })
      }
      
      Scroll() {
        Column() {
          ForEach(this.testResults, (result: string) => {
            Text(result)
              .fontSize(14)
              .margin({ bottom: 8 })
              .width('100%')
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
      }
      .layoutWeight(1)
      .width('100%')
      
      Button('重新运行测试')
        .width('100%')
        .height(40)
        .margin({ top: 20 })
        .onClick(() => {
          this.runTests()
        })
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}