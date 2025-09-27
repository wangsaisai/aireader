package com.example.aireader.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.aireader.data.model.Part
import com.example.aireader.data.model.QAMessage
import com.example.aireader.data.model.Role
import com.example.aireader.data.network.AskRequest
import com.example.aireader.data.repository.AppRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatViewModel(private val repository: AppRepository) : ViewModel(), ChatViewModelContract {

    private val _messages = MutableStateFlow<List<QAMessage>>(emptyList())
    override val messages: StateFlow<List<QAMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    override val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private var isFirstMessage = true

    override fun sendMessage(text: String) {
        val userMessage = QAMessage(Role.USER, listOf(Part(text)))
        _messages.value = _messages.value + userMessage

        _isLoading.value = true

        viewModelScope.launch {
            try {
                val responseText = if (isFirstMessage) {
                    isFirstMessage = false
                    val bookInfo = repository.getBookInfo(text)
                    "Here's information about the book **${bookInfo.title}**: \n\n${bookInfo.summary}"
                } else {
                    val history = _messages.value.dropLast(1) // Exclude the current user message for the request
                    repository.askQuestion(AskRequest(text, history))
                }
                val modelMessage = QAMessage(Role.MODEL, listOf(Part(responseText)))
                _messages.value = _messages.value + modelMessage
            } catch (e: Exception) {
                val errorMessage = QAMessage(Role.ERROR, listOf(Part("Error: ${e.message}")))
                _messages.value = _messages.value + errorMessage
            } finally {
                _isLoading.value = false
            }
        }
    }
}
