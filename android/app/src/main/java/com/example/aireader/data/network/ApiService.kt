package com.example.aireader.data.network

import com.example.aireader.data.model.BookInfo
import retrofit2.http.Body
import retrofit2.http.POST

interface ApiService {

    @POST("/book-info")
    suspend fun getBookInfo(@Body request: BookInfoRequest): BookInfo

    @POST("/ask")
    suspend fun askQuestion(@Body request: AskRequest): AskResponse

}
