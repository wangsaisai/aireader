package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class BookInfo(
    val title: String = "",
    val author: String = "",
    val publisher: String = "",
    val year: String = "",
    val isbn: String = "",
    val description: String = "",
    val summary: String = "",
    @Json(name = "is_found") val isFound: Boolean = false,
    @Json(name = "not_found_reason") val notFoundReason: String = ""
)
