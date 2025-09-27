package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ComplaintData(
    @Json(name = "message_id") val messageId: String,
    @Json(name = "session_id") val sessionId: String?,
    val reasons: List<String>,
    val details: String?,
    @Json(name = "book_name") val bookName: String,
    @Json(name = "message_content") val messageContent: String
)

@JsonClass(generateAdapter = true)
data class LikeData(
    @Json(name = "message_id") val messageId: String,
    @Json(name = "session_id") val sessionId: String?,
    @Json(name = "book_name") val bookName: String,
    @Json(name = "message_content") val messageContent: String
)
