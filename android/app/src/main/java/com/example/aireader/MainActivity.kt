package com.example.aireader

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.example.aireader.ui.theme.AIReaderTheme

import androidx.activity.viewModels
import com.example.aireader.data.local.StorageManager
import com.example.aireader.data.network.RetrofitClient
import com.example.aireader.data.repository.AppRepository
import com.example.aireader.ui.screens.ChatScreen
import com.example.aireader.ui.screens.ChatViewModel
import com.example.aireader.ui.screens.ChatViewModelFactory

class MainActivity : ComponentActivity() {

    private val repository by lazy {
        AppRepository(
            apiService = RetrofitClient.instance,
            storageManager = StorageManager(applicationContext)
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
