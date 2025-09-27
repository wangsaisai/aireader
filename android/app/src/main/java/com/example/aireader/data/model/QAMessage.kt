package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class QAMessage(
    @Json(name = "role") val role: Role,
    @Json(name = "parts") val parts: List<Part>,
    @Json(name = "timestamp") val timestamp: Long = System.currentTimeMillis()
)

enum class Role {
    @Json(name = "user")
    USER,
    @Json(name = "model")
    MODEL,
    @Json(name = "error")
    ERROR
}

@JsonClass(generateAdapter = true)
data class Part(
    @Json(name = "text") val text: String
)
