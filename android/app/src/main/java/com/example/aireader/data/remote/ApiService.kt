package com.example.aireader.data.remote

import com.example.aireader.data.model.BookInfo
import com.example.aireader.data.model.ChatRequest
import com.example.aireader.data.model.ComplaintData
import com.example.aireader.data.model.LikeData
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.POST
import retrofit2.http.Path

interface ApiService {
    @POST("/api/book/info")
    suspend fun getBookInfo(@Body body: Map<String, String>): ApiResponse<BookInfo>

    @POST("/api/chat/ask")
    suspend fun chatWithHistory(@Body request: ChatRequest): ApiResponse<QAData>

    @POST("/api/chat/generate_report")
    suspend fun generateDetailedReport(@Body body: Map<String, String?>): ApiResponse<ReportData>

    @DELETE("/api/chat/session/{sessionId}")
    suspend fun deleteSession(@Path("sessionId") sessionId: String): ApiResponse<Unit>

    @POST("/api/complaint")
    suspend fun submitComplaint(@Body complaintData: ComplaintData): ApiResponse<Unit>

    @POST("/api/like")
    suspend fun submitLike(@Body likeData: LikeData): ApiResponse<Unit>

    companion object {
        private const val BASE_URL = "http://34.176.0.152:8080"

        private val moshi = Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()

        private val retrofit = Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()

        val api: ApiService by lazy {
            retrofit.create(ApiService::class.java)
        }
    }
}
