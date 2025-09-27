package com.example.aireader.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.aireader.data.model.MessageType
import com.example.aireader.data.model.QAMessage

@Composable
fun MessageItem(message: QAMessage) {
    val alignment = if (message.type == MessageType.QUESTION) Alignment.CenterEnd else Alignment.CenterStart
    val colors = if (message.type == MessageType.QUESTION)
        CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
    else
        CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)

    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = alignment) {
        Card(
            modifier = Modifier
                .padding(vertical = 4.dp)
                .widthIn(max = 300.dp),
            colors = colors
        ) {
            Text(
                text = message.content,
                modifier = Modifier.padding(12.dp)
            )
        }
    }
}
