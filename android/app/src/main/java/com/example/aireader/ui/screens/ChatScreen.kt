package com.example.aireader.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.aireader.data.model.ClientChatSession
import com.example.aireader.data.model.MessageType
import com.example.aireader.data.model.QAMessage
import com.example.aireader.ui.components.MessageItem
import com.example.aireader.ui.viewmodel.ChatViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    val sessions by viewModel.sessions.collectAsState()
    val currentSession by viewModel.currentSession.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            SessionListComponent(
                sessions = sessions,
                currentSessionId = currentSession?.id ?: "",
                onSessionSelect = { session ->
                    viewModel.switchSession(session.id)
                    scope.launch { drawerState.close() }
                },
                onNewSession = {
                    viewModel.createNewSession("New Chat")
                    scope.launch { drawerState.close() }
                },
                onSessionDelete = { sessionId ->
                    viewModel.deleteSession(sessionId)
                }
            )
        }
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            text = currentSession?.title ?: "AI Reader",
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "Menu")
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.createNewSession("New Chat") }) {
                            Icon(Icons.Default.Add, contentDescription = "New Session")
                        }
                    }
                )
            }
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                val listState = rememberLazyListState()
                LaunchedEffect(currentSession?.messages?.size) {
                    currentSession?.messages?.size?.let {
                        if (it > 0) listState.animateScrollToItem(it - 1)
                    }
                }

                LazyColumn(
                    state = listState,
                    modifier = Modifier.weight(1f),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    items(currentSession?.messages ?: emptyList()) { message ->
                        MessageItem(message = message)
                    }
                }

                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.CenterHorizontally))
                }

                var text by remember { mutableStateOf("") }
                ChatInput(
                    text = text,
                    onTextChange = { text = it },
                    onSendMessage = {
                        viewModel.processMessage(text)
                        text = ""
                    },
                    enabled = !isLoading,
                    placeholder = if (currentSession?.bookInfo == null) "Enter a book title..." else "Ask a question..."
                )
            }
        }
    }
}

@Composable
fun ChatInput(
    text: String,
    onTextChange: (String) -> Unit,
    onSendMessage: () -> Unit,
    enabled: Boolean,
    placeholder: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextField(
            value = text,
            onValueChange = onTextChange,
            modifier = Modifier.weight(1f),
            placeholder = { Text(placeholder) },
            enabled = enabled
        )
        Spacer(modifier = Modifier.width(8.dp))
        Button(onClick = onSendMessage, enabled = enabled && text.isNotBlank()) {
            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = "Send")
        }
    }
}

@Composable
fun SessionListComponent(
    sessions: List<ClientChatSession>,
    currentSessionId: String,
    onSessionSelect: (ClientChatSession) -> Unit,
    onNewSession: () -> Unit,
    onSessionDelete: (String) -> Unit
) {
    ModalDrawerSheet {
        Text("Sessions", modifier = Modifier.padding(16.dp), style = MaterialTheme.typography.titleMedium)
        Divider()
        LazyColumn {
            items(sessions) { session ->
                NavigationDrawerItem(
                    label = { Text(session.title) },
                    selected = session.id == currentSessionId,
                    onClick = { onSessionSelect(session) }
                )
            }
        }
    }
}
