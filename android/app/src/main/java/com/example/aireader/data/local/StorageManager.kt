package com.example.aireader.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.aireader.data.model.ChatSession
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "sessions")

class StorageManager(private val context: Context) {

    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()
    private val sessionAdapter = moshi.adapter(ChatSession::class.java)

    companion object {
        private val CURRENT_SESSION_KEY = stringPreferencesKey("current_session")
    }

    val currentSessionFlow: Flow<ChatSession?> = context.dataStore.data
        .map { preferences ->
            preferences[CURRENT_SESSION_KEY]?.let { json ->
                sessionAdapter.fromJson(json)
            }
        }

    suspend fun saveSession(session: ChatSession) {
        context.dataStore.edit { preferences ->
            val json = sessionAdapter.toJson(session)
            preferences[CURRENT_SESSION_KEY] = json
        }
    }

    suspend fun clearCurrentSession() {
        context.dataStore.edit { preferences ->
            preferences.remove(CURRENT_SESSION_KEY)
        }
    }
}
