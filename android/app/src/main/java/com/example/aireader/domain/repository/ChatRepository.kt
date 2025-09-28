package com.example.aireader.domain.repository

import com.example.aireader.data.model.BookInfo
import com.example.aireader.data.model.ChatRequest
import com.example.aireader.data.model.ClientChatSession
import com.example.aireader.data.model.ComplaintData
import com.example.aireader.data.model.LikeData
import kotlinx.coroutines.flow.Flow

interface ChatRepository {
    suspend fun getBookInfo(bookName: String): Result<BookInfo>
    suspend fun chatWithHistory(request: ChatRequest): Result<String>
    suspend fun generateDetailedReport(bookName: String, author: String?): Result<String>
    suspend fun submitComplaint(complaintData: ComplaintData): Result<Unit>
    suspend fun submitLike(likeData: LikeData): Result<Unit>

    fun getSessions(): Flow<List<ClientChatSession>>
    suspend fun saveSessions(sessions: List<ClientChatSession>)
    fun getCurrentSessionId(): Flow<String>
    suspend fun saveCurrentSessionId(sessionId: String)
    fun getString(resId: Int): String

}
