package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ChatMessage(
    val role: String,
    val content: String
)

@JsonClass(generateAdapter = true)
data class ChatRequest(
    @Json(name = "book_name") val bookName: String,
    val messages: List<ChatMessage>,
    val question: String
)
