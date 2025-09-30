package com.example.aireader.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.aireader.R
import com.example.aireader.data.model.ClientChatSession
import com.example.aireader.ui.components.MessageItem
import com.example.aireader.ui.viewmodel.ChatViewModel
import com.example.aireader.ui.viewmodel.Prompt
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun ChatScreen(viewModel: ChatViewModel) {
    val sessions by viewModel.sessions.collectAsState()
    val currentSession by viewModel.currentSession.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val promptSuggestions by viewModel.promptSuggestions.collectAsState()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    var sessionToDeleteId by remember { mutableStateOf<String?>(null) }

    if (sessionToDeleteId != null) {
        AlertDialog(
            onDismissRequest = { sessionToDeleteId = null },
            title = { Text(stringResource(id = R.string.delete_session_confirmation_title)) },
            text = { Text(stringResource(id = R.string.delete_session_confirmation_text)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        sessionToDeleteId?.let { viewModel.deleteSession(it) }
                        sessionToDeleteId = null
                    }
                ) {
                    Text(stringResource(id = R.string.delete_session_confirm_button))
                }
            },
            dismissButton = {
                TextButton(onClick = { sessionToDeleteId = null }) {
                    Text(stringResource(id = R.string.delete_session_cancel_button))
                }
            }
        )
    }

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
                onSessionDelete = { sessionId ->
                    sessionToDeleteId = sessionId
                }
            )
        }
    ) {
        Scaffold(
            topBar = {
                val newChatTitle = stringResource(id = R.string.new_chat_title)
                TopAppBar(
                    title = {
                        Text(
                            text = currentSession?.title ?: stringResource(id = R.string.app_name),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = stringResource(id = R.string.menu_description))
                        }
                    },
                    actions = {
                        IconButton(onClick = { viewModel.createNewSession(newChatTitle) }) {
                            Icon(Icons.Default.Add, contentDescription = stringResource(id = R.string.new_session_description))
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

                if (promptSuggestions.isNotEmpty() && currentSession?.bookInfo != null) {
                    PromptSuggestions(
                        suggestions = promptSuggestions,
                        onSuggestionClick = { prompt ->
                            viewModel.processPrompt(prompt)
                        }
                    )
                }

                var text by remember { mutableStateOf("") }
                val placeholderText = if (currentSession?.bookInfo == null) stringResource(id = R.string.enter_book_title_placeholder) else stringResource(id = R.string.ask_question_placeholder)
                ChatInput(
                    text = text,
                    onTextChange = { text = it },
                    onSendMessage = {
                        viewModel.processMessage(text)
                        text = ""
                    },
                    enabled = !isLoading,
                    placeholder = placeholderText
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
            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = stringResource(id = R.string.send_button_description))
        }
    }
}

@Composable
fun SessionListComponent(
    sessions: List<ClientChatSession>,
    currentSessionId: String,
    onSessionSelect: (ClientChatSession) -> Unit,
    onSessionDelete: (String) -> Unit
) {
    ModalDrawerSheet(modifier = Modifier.widthIn(max = 320.dp)) {
        Text(stringResource(id = R.string.sessions_title), modifier = Modifier.padding(16.dp), style = MaterialTheme.typography.titleMedium)
        HorizontalDivider()
        LazyColumn {
            items(sessions) { session ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    NavigationDrawerItem(
                        label = { Text(session.title) },
                        selected = session.id == currentSessionId,
                        onClick = { onSessionSelect(session) },
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = { onSessionDelete(session.id) }) {
                        Icon(Icons.Default.Delete, contentDescription = stringResource(id = R.string.delete_session_description))
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun PromptSuggestions(
    suggestions: List<Prompt>,
    onSuggestionClick: (Prompt) -> Unit
) {
    FlowRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        suggestions.forEach { suggestion ->
            Button(
                onClick = { onSuggestionClick(suggestion) },
                modifier = Modifier.padding(bottom = 8.dp)
            ) {
                Text(stringResource(id = suggestion.title))
            }
        }
    }
}
