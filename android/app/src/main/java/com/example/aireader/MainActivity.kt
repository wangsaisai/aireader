package com.example.aireader

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.activity.viewModels
import com.example.aireader.data.remote.ApiService
import com.example.aireader.data.repository.ChatRepositoryImpl
import com.example.aireader.domain.repository.ChatRepository
import com.example.aireader.ui.screens.ChatScreen
import com.example.aireader.ui.theme.AIReaderTheme
import com.example.aireader.ui.viewmodel.ChatViewModel
import com.example.aireader.ui.viewmodel.ChatViewModelFactory

class MainActivity : ComponentActivity() {

    private val repository: ChatRepository by lazy {
        ChatRepositoryImpl(
            apiService = ApiService.api,
            context = applicationContext
        )
    }

    private val viewModel: ChatViewModel by viewModels {
        ChatViewModelFactory(repository)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AIReaderTheme {
                ChatScreen(viewModel = viewModel)
            }
        }
    }
}
