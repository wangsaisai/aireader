package com.example.aireader.data.repository

import com.example.aireader.data.local.StorageManager
import com.example.aireader.data.model.BookInfo
import com.example.aireader.data.model.ChatSession
import com.example.aireader.data.network.ApiService
import com.example.aireader.data.network.AskRequest
import com.example.aireader.data.network.BookInfoRequest
import kotlinx.coroutines.flow.Flow

class AppRepository(
    private val apiService: ApiService,
    private val storageManager: StorageManager
) {

    suspend fun getBookInfo(title: String): BookInfo {
        return apiService.getBookInfo(BookInfoRequest(title))
    }

    suspend fun askQuestion(request: AskRequest): String {
        val response = apiService.askQuestion(request)
        return response.answer
    }

    val currentSessionFlow: Flow<ChatSession?> = storageManager.currentSessionFlow

    suspend fun saveSession(session: ChatSession) {
        storageManager.saveSession(session)
    }

    suspend fun clearCurrentSession() {
        storageManager.clearCurrentSession()
    }
}
