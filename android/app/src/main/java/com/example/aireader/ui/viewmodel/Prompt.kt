package com.example.aireader.ui.viewmodel

import androidx.annotation.StringRes
import com.example.aireader.R

sealed class Prompt(
    @StringRes val title: Int,
    @StringRes val prompt: Int
) {
    object CoreInsights : Prompt(R.string.prompt_title_core_insights, R.string.prompt_prompt_core_insights)
    object KeyConcepts : Prompt(R.string.prompt_title_key_concepts, R.string.prompt_prompt_key_concepts)
    object Quotes : Prompt(R.string.prompt_title_quotes, R.string.prompt_prompt_quotes)
    object Reviews : Prompt(R.string.prompt_title_reviews, R.string.prompt_prompt_reviews)
    object ReadingStrategies : Prompt(R.string.prompt_title_reading_strategies, R.string.prompt_prompt_reading_strategies)
    object TargetAudience : Prompt(R.string.prompt_title_target_audience, R.string.prompt_prompt_target_audience)
    object GenerateReport : Prompt(R.string.prompt_title_generate_report, R.string.prompt_prompt_generate_report)
}
