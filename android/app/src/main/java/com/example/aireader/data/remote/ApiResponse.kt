package com.example.aireader.data.remote

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ApiResponse<T>(
    val success: Boolean,
    val data: T?,
    val error: String?,
    val message: String?
)

@JsonClass(generateAdapter = true)
data class QAData(
    val answer: String
)

@JsonClass(generateAdapter = true)
data class ReportData(
    val report: String
)
