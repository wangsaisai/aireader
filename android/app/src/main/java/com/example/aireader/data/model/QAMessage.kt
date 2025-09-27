package com.example.aireader.data.model

import java.util.UUID

data class QAMessage(
    val id: String = UUID.randomUUID().toString(),
    val content: String,
    val type: MessageType,
    val timestamp: Long = System.currentTimeMillis()
)

enum class MessageType {
    QUESTION, ANSWER
}
