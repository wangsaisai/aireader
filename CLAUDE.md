# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project is an AI-powered book assistant with a HarmonyOS (ArkTS) frontend and a Python (FastAPI) backend. The backend communicates with the Google Gemini API to provide book information and answer questions.

-   **Frontend**: HarmonyOS application built with ArkTS and ArkUI.
-   **Backend**: Python service using FastAPI, Pydantic, and the Google Generative AI SDK.
-   **AI Service**: Google Gemini.

The application allows users to enter a book title, get detailed information about it, and then engage in a Q&A session about the book.

## Backend (Python/FastAPI)

### Architecture

The backend is a FastAPI application that serves as a proxy between the HarmonyOS app and the Google Gemini API. It handles requests for book information and Q&A.

-   **`main.py`**: Application entry point.
-   **`api/`**: Contains API routes (`routes.py`) and data schemas (`schemas.py`).
-   **`services/`**: Business logic, including `gemini_service.py` for interacting with the Gemini API and `book_service.py` for book-related logic.
-   **`config/`**: Configuration management.
-   **`requirements.txt`**: Python dependencies.

### Development Setup

1.  **Install dependencies**:
    ```bash
    cd backend
    pip install -r requirements.txt
    ```

2.  **Configure environment**:
    Copy `.env.example` to `.env` and add your `GOOGLE_API_KEY`.

3.  **Run the server**:
    ```bash
    cd backend
    uvicorn main:app --host 0.0.0.0 --port 8000
    ```

## HarmonyOS App (ArkTS)

### Architecture

The frontend is a native HarmonyOS application written in ArkTS. It features a unified chat interface for both querying book information and conducting Q&A sessions. It includes features like Markdown rendering for AI responses, multi-round conversation memory, and local data persistence using HarmonyOS's Preferences API.

-   **`entry/src/main/ets/pages/Index.ets`**: The main and only page of the application, handling the entire user interaction.
-   **`entry/src/main/ets/services/`**: Contains `ApiService.ets` for backend communication, `StorageManager.ets` for data persistence, and `ClientSessionManager.ets` for session management.
-   **`entry/src/main/ets/components/`**: Reusable UI components like `QAComponent.ets` and `MarkdownRenderer.ets`.
-   **`entry/src/main/ets/model/`**: Data models for the application.
-   **`hvigorfile.ts`**: Build script for the HarmonyOS app.
-   **`oh-package.json5`**: Project dependencies.

### Development Setup

-   The application is built using **DevEco Studio**.
-   Build and run the application through the IDE.

### Code Quality

The project uses a linter for ArkTS code. The configuration is in `aireader_hm/code-linter.json5`. The ruleset includes `@performance/recommended` and `@typescript-eslint/recommended`.

There are also scripts to check for specific code quality issues:

-   `aireader_hm/check_syntax.sh`: Checks for usage of `any` type, incorrect import paths, and async call correctness.
-   `aireader_hm/verify_types.sh`: Checks for untyped object literals and unsafe `JSON.parse` usage.

Run them from the root directory:
```bash
bash aireader_hm/check_syntax.sh
bash aireader_hm/verify_types.sh
```

## Common Tasks

### Adding a new API endpoint

1.  **Backend**:
    -   Add a new route in `backend/api/routes.py`.
    -   Add corresponding data schemas in `backend/api/schemas.py`.
    -   Implement the service logic in a relevant file under `backend/services/`.
2.  **Frontend**:
    -   Add a new method to `aireader_hm/entry/src/main/ets/services/ApiService.ets` to call the new endpoint.
    -   Update the UI in `aireader_hm/entry/src/main/ets/pages/Index.ets` to use the new service method.

### Modifying the UI

-   UI components are located in `aireader_hm/entry/src/main/ets/components/`.
-   The main page layout is in `aireader_hm/entry/src/main/ets/pages/Index.ets`.
-   Follow the ArkUI component patterns and state management (`@State`, `@Prop`) seen in the existing code.
