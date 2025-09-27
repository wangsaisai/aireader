package com.example.aireader.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class BookInfo(
    @Json(name = "title") val title: String,
    @Json(name = "author") val author: String,
    @Json(name = "summary") val summary: String,
    @Json(name = "publication_year") val publicationYear: Int,
    @Json(name = "genres") val genres: List<String>
)
