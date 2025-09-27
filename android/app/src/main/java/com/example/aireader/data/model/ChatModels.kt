package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ChatSession(
    @Json(name = "sessionId") val sessionId: String,
    @Json(name = "history") val history: MutableList<QAMessage>
)
