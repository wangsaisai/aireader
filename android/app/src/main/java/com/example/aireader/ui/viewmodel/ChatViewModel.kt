package com.example.aireader.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.aireader.data.model.*
import com.example.aireader.domain.repository.ChatRepository
import com.example.aireader.R
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.*

data class Prompt(
    val title: Int,
    val prompt: Int
)

class ChatViewModel(private val repository: ChatRepository) : ViewModel() {

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
                repository.getCurrentSessionId().firstOrNull()?.let { currentId ->
                    _currentSession.value = sessions.find { it.id == currentId }
                }
            }
        }
    }

    fun createNewSession(title: String, bookName: String? = null) {
        viewModelScope.launch {
            val newSession = ClientChatSession(title = bookName ?: title, bookName = bookName)
            val updatedSessions = listOf(newSession) + _sessions.value
            _sessions.value = updatedSessions
            _currentSession.value = newSession
            repository.saveSessions(updatedSessions)
            repository.saveCurrentSessionId(newSession.id)
        }
    }

    fun switchSession(sessionId: String) {
        viewModelScope.launch {
            _currentSession.value = _sessions.value.find { it.id == sessionId }
            repository.saveCurrentSessionId(sessionId)
        }
    }

    fun deleteSession(sessionId: String) {
        viewModelScope.launch {
            val updatedSessions = _sessions.value.filterNot { it.id == sessionId }
            _sessions.value = updatedSessions
            if (_currentSession.value?.id == sessionId) {
                val newCurrent = updatedSessions.firstOrNull()
                _currentSession.value = newCurrent
                repository.saveCurrentSessionId(newCurrent?.id ?: "")
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
                            if (bookInfo.isFound == true) {
                                val bookInfoMessage = QAMessage(
                                    content = formatBookInfo(bookInfo),
                                    type = MessageType.ANSWER
                                )
                                updateCurrentSessionBookInfo(bookInfo)
                                addMessageToCurrentSession(bookInfoMessage)
                            } else {
                                val notFoundMessage = QAMessage(
                                    content = bookInfo.notFoundReason ?: "Book not found, and no reason was provided.",
                                    type = MessageType.ANSWER
                                )
                                addMessageToCurrentSession(notFoundMessage)
                            }
                            loadPromptSuggestions()
                        }
                        .onFailure {
                            val errorMessage = QAMessage(content = it.message ?: "Error", type = MessageType.ANSWER)
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
                            val errorMessage = QAMessage(content = it.message ?: "Error", type = MessageType.ANSWER)
                            addMessageToCurrentSession(errorMessage)
                        }
                }
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
            val updatedSession = session.copy(bookInfo = bookInfo, bookName = bookInfo.title, title = "📚 ${bookInfo.title ?: "Unknown Title"}")
            updateSessionInList(updatedSession)
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
            Title: ${bookInfo.title ?: "Unknown"}
            Author: ${bookInfo.author ?: "Unknown"}
            Publisher: ${bookInfo.publisher ?: "Unknown"}
            Year: ${bookInfo.year ?: "Unknown"}

            Description:
            ${bookInfo.description ?: "No description available."}
        """.trimIndent()
    }

    private fun loadPromptSuggestions() {
        val prompts = listOf(
            Prompt(R.string.prompt_title_core_insights, R.string.prompt_prompt_core_insights),
            Prompt(R.string.prompt_title_key_concepts, R.string.prompt_prompt_key_concepts),
            Prompt(R.string.prompt_title_quotes, R.string.prompt_prompt_quotes),
            Prompt(R.string.prompt_title_reviews, R.string.prompt_prompt_reviews),
            Prompt(R.string.prompt_title_reading_strategies, R.string.prompt_prompt_reading_strategies),
            Prompt(R.string.prompt_title_target_audience, R.string.prompt_prompt_target_audience),
            Prompt(R.string.prompt_title_generate_report, R.string.prompt_prompt_generate_report)
        )
        _promptSuggestions.value = prompts
    }

    fun processPrompt(prompt: Prompt) {
        val promptText = repository.getString(prompt.prompt)
        processMessage(promptText)
    }
}

class ChatViewModelFactory(private val repository: ChatRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(ChatViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return ChatViewModel(repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}