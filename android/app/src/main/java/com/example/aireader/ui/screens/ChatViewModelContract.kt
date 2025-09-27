package com.example.aireader.ui.screens

import com.example.aireader.data.model.QAMessage
import kotlinx.coroutines.flow.StateFlow

interface ChatViewModelContract {
    val messages: StateFlow<List<QAMessage>>
    val isLoading: StateFlow<Boolean>
    fun sendMessage(text: String)
}
