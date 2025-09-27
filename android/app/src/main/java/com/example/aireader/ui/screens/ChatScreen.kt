package com.example.aireader.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.aireader.ui.components.ChatInput
import com.example.aireader.ui.components.LoadingIndicator
import com.example.aireader.ui.components.MessageItem
import kotlinx.coroutines.flow.StateFlow
import androidx.compose.ui.res.stringResource
import com.example.aireader.R
import com.example.aireader.data.model.QAMessage




@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    val messages by viewModel.messages.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Scaffold(
                topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.app_bar_title)) }
            )
        },
        content = { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 8.dp)
                ) {
                    items(messages) { message ->
                        MessageItem(message = message)
                    }
                    if (isLoading) {
                        item {
                            LoadingIndicator()
                        }
                    }
                }
                ChatInput(
                    onSendMessage = { text -> viewModel.sendMessage(text) }
                )
            }
        }
    )
}
