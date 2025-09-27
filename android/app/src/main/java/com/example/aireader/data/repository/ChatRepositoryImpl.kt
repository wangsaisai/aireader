package com.example.aireader.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.aireader.data.model.BookInfo
import com.example.aireader.data.model.ChatRequest
import com.example.aireader.data.model.ClientChatSession
import com.example.aireader.data.model.ComplaintData
import com.example.aireader.data.model.LikeData
import com.example.aireader.data.remote.ApiService
import com.example.aireader.domain.repository.ChatRepository
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.io.IOException

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "sessions")

class ChatRepositoryImpl(
    private val apiService: ApiService,
    private val context: Context
) : ChatRepository {

    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()
    private val sessionListAdapter = moshi.adapter<List<ClientChatSession>>(
        Types.newParameterizedType(List::class.java, ClientChatSession::class.java)
    )

    private object PreferencesKeys {
        val SESSIONS = stringPreferencesKey("sessions_list")
        val CURRENT_SESSION_ID = stringPreferencesKey("current_session_id")
    }

    override suspend fun getBookInfo(bookName: String): Result<BookInfo> {
        return try {
            val response = apiService.getBookInfo(mapOf("book_name" to bookName))
            if (response.success && response.data != null) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun chatWithHistory(request: ChatRequest): Result<String> {
        return try {
            val response = apiService.chatWithHistory(request)
            if (response.success && response.data != null) {
                Result.success(response.data.answer)
            } else {
                Result.failure(Exception(response.message ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun generateDetailedReport(bookName: String, author: String?): Result<String> {
        return try {
            val response = apiService.generateDetailedReport(mapOf("book_name" to bookName, "author" to author))
            if (response.success && response.data != null) {
                Result.success(response.data.report)
            } else {
                Result.failure(Exception(response.message ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun submitComplaint(complaintData: ComplaintData): Result<Unit> {
        return try {
            val response = apiService.submitComplaint(complaintData)
            if (response.success) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.message ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun submitLike(likeData: LikeData): Result<Unit> {
        return try {
            val response = apiService.submitLike(likeData)
            if (response.success) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.message ?: "Unknown error"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun getSessions(): Flow<List<ClientChatSession>> = context.dataStore.data.map { preferences ->
        val json = preferences[PreferencesKeys.SESSIONS]
        if (json != null) {
            sessionListAdapter.fromJson(json) ?: emptyList()
        } else {
            emptyList()
        }
    }

    override suspend fun saveSessions(sessions: List<ClientChatSession>) {
        context.dataStore.edit { preferences ->
            val json = sessionListAdapter.toJson(sessions)
            preferences[PreferencesKeys.SESSIONS] = json
        }
    }

    override fun getCurrentSessionId(): Flow<String> = context.dataStore.data.map { preferences ->
        preferences[PreferencesKeys.CURRENT_SESSION_ID] ?: ""
    }

    override suspend fun saveCurrentSessionId(sessionId: String) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.CURRENT_SESSION_ID] = sessionId
        }
    }
}
