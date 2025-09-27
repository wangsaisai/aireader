package com.example.aireader.data.model

import java.util.UUID

data class ClientChatSession(
    val id: String = UUID.randomUUID().toString(),
    var title: String,
    var bookName: String? = null,
    var bookInfo: BookInfo? = null,
    val messages: MutableList<QAMessage> = mutableListOf(),
    val createdAt: Long = System.currentTimeMillis(),
    var updatedAt: Long = System.currentTimeMillis(),
    var isActive: Boolean = true
)
