-- Final Database Schema for AI Book Assistant

-- 1. Books Table
-- Stores core information about books, including AI-generated introductions and reports.
CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    input_title VARCHAR(255),
    author VARCHAR(255),
    introduction TEXT, -- AI-generated book introduction
    report TEXT, -- AI-generated book report
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(title, author)
);

CREATE INDEX idx_books_title_author ON books (title, author);

-- 2. Q&A Messages Table
-- Logs the full request and response payloads for user Q&A interactions.
CREATE TABLE qa_messages (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    request_payload JSONB NOT NULL, -- Stores the complete /chat request body
    response_payload JSONB NOT NULL, -- Stores the complete /chat response body
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_qa_messages_title_author ON qa_messages (title, author);

-- 3. Feedback Table
-- Stores user feedback (likes/dislikes) with the full request payload.
CREATE TYPE feedback_type AS ENUM ('like', 'dislike');

CREATE TABLE feedback (
    id SERIAL PRIMARY KEY,
    request_payload JSONB NOT NULL, -- Stores the complete /feedback request body
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. API Request Logs Table
-- Records detailed information for every API request to the backend.
CREATE TABLE api_request_logs (
    id SERIAL PRIMARY KEY,
    method VARCHAR(10) NOT NULL,
    path VARCHAR(255) NOT NULL,
    request_body JSONB, -- Stores the request body (nullable for GET requests)
    status_code INTEGER NOT NULL,
    response_body JSONB, -- Stores the response body
    response_time_ms INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_logs_path_status ON api_request_logs (path, status_code);
