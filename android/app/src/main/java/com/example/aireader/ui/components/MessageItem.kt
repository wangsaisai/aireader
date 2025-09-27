package com.example.aireader.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.example.aireader.data.model.QAMessage
import com.example.aireader.data.model.Role

@Composable
fun MessageItem(message: QAMessage) {
    val isUser = message.role == Role.USER
    val alignment = if (isUser) Alignment.CenterEnd else Alignment.CenterStart
    val backgroundColor = when (message.role) {
        Role.USER -> MaterialTheme.colorScheme.primaryContainer
        Role.MODEL -> MaterialTheme.colorScheme.secondaryContainer
        Role.ERROR -> MaterialTheme.colorScheme.errorContainer
    }
    val textColor = when (message.role) {
        Role.USER -> MaterialTheme.colorScheme.onPrimaryContainer
        Role.MODEL -> MaterialTheme.colorScheme.onSecondaryContainer
        Role.ERROR -> MaterialTheme.colorScheme.onErrorContainer
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp, horizontal = 8.dp),
        contentAlignment = alignment
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.8f)
                .clip(RoundedCornerShape(16.dp))
                .background(backgroundColor)
                .padding(12.dp)
        ) {
            Text(
                text = message.parts.joinToString { it.text },
                color = textColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
