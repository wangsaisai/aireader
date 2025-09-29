package com.example.aireader.ui.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.aireader.R
import com.example.aireader.data.model.*
import com.example.aireader.domain.repository.ChatRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.*

class ChatViewModel(
    private val repository: ChatRepository,
    private val context: Context
    ) : ViewModel() {

    private val _sessions = MutableStateFlow<List<ClientChatSession>>(emptyList())
    val sessions: StateFlow<List<ClientChatSession>> = _sessions.asStateFlow()

    private val _currentSession = MutableStateFlow<ClientChatSession?>(null)
    val currentSession: StateFlow<ClientChatSession?> = _currentSession.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _promptSuggestions = MutableStateFlow<List<Prompt>>(emptyList())
    val promptSuggestions: StateFlow<List<Prompt>> = _promptSuggestions.asStateFlow()


    init {
        viewModelScope.launch {
            repository.getSessions().collect { sessions ->
                _sessions.value = sessions
                if (sessions.isNotEmpty()) {
                    repository.getCurrentSessionId().firstOrNull()?.let { currentId ->
                        val sessionToSelect = sessions.find { it.id == currentId } ?: sessions.first()
                        _currentSession.value = sessionToSelect
                        updatePromptSuggestions(sessionToSelect)
                    }
                } else {
                    // Create a default session if none exist
                    createNewSession(context.getString(R.string.new_chat_title))
                }
            }
        }
    }

    fun createNewSession(title: String, bookName: String? = null) {
        viewModelScope.launch {
            val newSession = ClientChatSession(title = bookName ?: title, bookName = bookName)
            val updatedSessions = listOf(newSession) + _sessions.value
            _sessions.value = updatedSessions
            switchSession(newSession.id)
        }
    }

    fun switchSession(sessionId: String) {
        viewModelScope.launch {
            val newSession = _sessions.value.find { it.id == sessionId }
            _currentSession.value = newSession
            repository.saveCurrentSessionId(sessionId)
            updatePromptSuggestions(newSession)
        }
    }

    fun deleteSession(sessionId: String) {
        viewModelScope.launch {
            val updatedSessions = _sessions.value.filterNot { it.id == sessionId }
            _sessions.value = updatedSessions
            if (_currentSession.value?.id == sessionId) {
                val newCurrent = updatedSessions.firstOrNull()
                switchSession(newCurrent?.id ?: "")
            }
            repository.saveSessions(updatedSessions)
        }
    }

    fun processMessage(input: String) {
        if (input.isBlank()) return

        val userMessage = QAMessage(content = input, type = MessageType.QUESTION)
        addMessageToCurrentSession(userMessage)

        _isLoading.value = true
        viewModelScope.launch {
            val current = _currentSession.value
            if (current != null) {
                if (current.bookInfo == null) {
                    // Get book info
                    repository.getBookInfo(input)
                        .onSuccess { bookInfo ->
                            if (bookInfo.isFound ?: false) {
                                val bookInfoMessage = QAMessage(
                                    content = formatBookInfo(bookInfo),
                                    type = MessageType.ANSWER
                                )
                                updateCurrentSessionBookInfo(bookInfo)
                                addMessageToCurrentSession(bookInfoMessage)
                            } else {
                                val notFoundMessage = QAMessage(
                                    content = bookInfo.notFoundReason ?: "",
                                    type = MessageType.ANSWER
                                )
                                addMessageToCurrentSession(notFoundMessage)
                            }
                        }
                        .onFailure {
                            val errorMessage = QAMessage(content = it.message ?: context.getString(R.string.default_error_message), type = MessageType.ANSWER)
                            addMessageToCurrentSession(errorMessage)
                        }
                } else {
                    // Chat with history
                    val chatHistory = current.messages
                        .filter { it.type == MessageType.QUESTION || it.type == MessageType.ANSWER }
                        .map { ChatMessage(role = if (it.type == MessageType.QUESTION) "user" else "assistant", content = it.content) }

                    val request = ChatRequest(
                        bookName = current.bookName ?: "",
                        messages = chatHistory,
                        question = input
                    )

                    repository.chatWithHistory(request)
                        .onSuccess { answer ->
                            val answerMessage = QAMessage(content = answer, type = MessageType.ANSWER)
                            addMessageToCurrentSession(answerMessage)
                        }
                        .onFailure {
                            val errorMessage = QAMessage(content = it.message ?: context.getString(R.string.default_error_message), type = MessageType.ANSWER)
                            addMessageToCurrentSession(errorMessage)
                        }
                }
            }
            _isLoading.value = false
        }
    }

    fun processPrompt(prompt: Prompt) {
        when (prompt) {
            is Prompt.GenerateReport -> generateReport()
            else -> processMessage(context.getString(prompt.prompt))
        }
    }

    private fun generateReport() {
        val current = _currentSession.value ?: return
        val bookInfo = current.bookInfo ?: return

        val userMessage = QAMessage(content = context.getString(R.string.generating_report_message), type = MessageType.QUESTION)
        addMessageToCurrentSession(userMessage)

        _isLoading.value = true
        viewModelScope.launch {
            repository.generateDetailedReport(bookInfo.title ?: "", bookInfo.author)
                .onSuccess { report ->
                    val reportMessage = QAMessage(content = report, type = MessageType.ANSWER)
                    addMessageToCurrentSession(reportMessage)
                }
                .onFailure {
                    val errorMessage = QAMessage(content = it.message ?: context.getString(R.string.default_error_message), type = MessageType.ANSWER)
                    addMessageToCurrentSession(errorMessage)
                }
            _isLoading.value = false
        }
    }

    private fun addMessageToCurrentSession(message: QAMessage) {
        _currentSession.value?.let { session ->
            val updatedMessages = session.messages + message
            val updatedSession = session.copy(messages = updatedMessages.toMutableList(), updatedAt = System.currentTimeMillis())
            updateSessionInList(updatedSession)
        }
    }

    private fun updateCurrentSessionBookInfo(bookInfo: BookInfo) {
        _currentSession.value?.let { session ->
            val updatedSession = session.copy(bookInfo = bookInfo, bookName = bookInfo.title, title = "📚 ${bookInfo.title}")
            updateSessionInList(updatedSession)
            updatePromptSuggestions(updatedSession)
        }
    }

    private fun updateSessionInList(updatedSession: ClientChatSession) {
        val index = _sessions.value.indexOfFirst { it.id == updatedSession.id }
        if (index != -1) {
            val updatedList = _sessions.value.toMutableList()
            updatedList[index] = updatedSession
            _sessions.value = updatedList
            _currentSession.value = updatedSession
            viewModelScope.launch {
                repository.saveSessions(updatedList)
            }
        }
    }

    private fun formatBookInfo(bookInfo: BookInfo): String {
        return """
            ${context.getString(R.string.book_info_title)}: ${bookInfo.title ?: context.getString(R.string.book_info_unknown)}
            ${context.getString(R.string.book_info_author)}: ${bookInfo.author ?: context.getString(R.string.book_info_unknown)}
            ${context.getString(R.string.book_info_publisher)}: ${bookInfo.publisher ?: context.getString(R.string.book_info_unknown)}
            ${context.getString(R.string.book_info_year)}: ${bookInfo.year ?: context.getString(R.string.book_info_unknown)}

            ${context.getString(R.string.book_info_description)}:
            ${bookInfo.description}
        """.trimIndent()
    }

    private fun updatePromptSuggestions(session: ClientChatSession?) {
        _promptSuggestions.value = if (session?.bookInfo != null) {
            listOf(
                Prompt.CoreInsights,
                Prompt.KeyConcepts,
                Prompt.Quotes,
                Prompt.Reviews,
                Prompt.ReadingStrategies,
                Prompt.TargetAudience,
                Prompt.GenerateReport
            )
        } else {
            emptyList()
        }
    }
}

class ChatViewModelFactory(
    private val repository: ChatRepository,
    private val context: Context
    ) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(ChatViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return ChatViewModel(repository, context) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}