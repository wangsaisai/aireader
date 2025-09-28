package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class BookInfo(
    val title: String? = null,
    val author: String? = null,
    val publisher: String? = null,
    val year: String? = null,
    val isbn: String? = null,
    val description: String? = null,
    val summary: String? = null,
    @Json(name = "is_found") val isFound: Boolean? = null,
    @Json(name = "not_found_reason") val notFoundReason: String? = null
)
