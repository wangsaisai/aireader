package com.example.aireader.data.network

import com.example.aireader.data.model.QAMessage
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class AskRequest(
    @Json(name = "question") val question: String,
    @Json(name = "history") val history: List<QAMessage>
)

@JsonClass(generateAdapter = true)
data class AskResponse(
    @Json(name = "answer") val answer: String
)

@JsonClass(generateAdapter = true)
data class BookInfoRequest(
    @Json(name = "book_title") val bookTitle: String
)
