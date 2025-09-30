#!/bin/bash

# API Verification Script
#
# This script tests all endpoints of the AI Book Assistant backend.
# It continues execution even if some tests fail and provides a summary at the end.
#
# Prerequisites:
# - curl: Should be pre-installed on most systems.
# - jq: A command-line JSON processor. Install with 'sudo apt-get install jq' or 'brew install jq'.

# --- Configuration ---
BASE_URL="http://34.176.0.152:8080"
LOG_FILE="api_verification_$(date +%Y%m%d_%H%M%S).log"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters for summary
TOTAL_TESTS=0
FAILED_TESTS=0

# --- Helper Function ---
# Usage: check_api <endpoint_name> <curl_command>
check_api() {
    local endpoint_name="$1"
    shift
    local curl_cmd="$@"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    printf "Testing %-30s ... " "$endpoint_name"

    # Execute curl and capture response and http code.
    response=$(eval "$curl_cmd -w 'DELIMITER%{http_code}' -s")
    http_code=$(echo "$response" | sed -n 's/.*DELIMITER//p')
    body=$(echo "$response" | sed 's/DELIMITER.*//')

    local test_failed=0

    if [ "$http_code" -ne 200 ]; then
        printf "${RED}FAIL${NC} (HTTP %s)\n" "$http_code"
        echo "   Response: $body"
        test_failed=1
    elif ! echo "$body" | jq -e '.success == true' > /dev/null; then
        printf "${RED}FAIL${NC} ('success' field is not true or missing)\n"
        echo "   Response: $body"
        test_failed=1
    else
        printf "${GREEN}PASS${NC}\n"
    fi

    if [ "$test_failed" -eq 1 ]; then
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# --- Main Execution ---

# Redirect stdout to a log file and also print to the console
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "Starting API verification for $BASE_URL..."
echo "Log file: $LOG_FILE"
echo "================================================="

# 1. Health Check
check_api "GET /api/health" "curl -X GET $BASE_URL/api/health"

# 2. Get Book Info
check_api "POST /api/book/info" "curl -X POST '$BASE_URL/api/book/info' -H 'Content-Type: application/json' -d '{\"book_name\": \"三体\"}'"

# 3. Book Q&A
check_api "POST /api/book/qa" "curl -X POST '$BASE_URL/api/book/qa' -H 'Content-Type: application/json' -d '{\"book_name\": \"三体\", \"question\": \"书中的主角是谁？\"}'"

# 4. Generate Report
check_api "POST /api/chat/generate_report" "curl -X POST '$BASE_URL/api/chat/generate_report' -H 'Content-Type: application/json' -d '{\"book_name\": \"三体\", \"author\": \"刘慈欣\"}'"

# 5. Chat with History
CHAT_PAYLOAD='{"book_name": "三体", "messages": [{"role": "user", "content": "这本书主要讲了什么？"}, {"role": "assistant", "content": "《三体》是刘慈欣创作的系列长篇科幻小说..."}], "question": "三体文明在哪个星系？"}'
check_api "POST /api/chat/ask" "curl -X POST '$BASE_URL/api/chat/ask' -H 'Content-Type: application/json' -d '$CHAT_PAYLOAD'"

# 6. Get Cache Stats
check_api "GET /api/cache/stats" "curl -X GET '$BASE_URL/api/cache/stats'"

# 7. Clear Cache
check_api "POST /api/cache/clear" "curl -X POST '$BASE_URL/api/cache/clear'"

# 8. Submit Complaint
COMPLAINT_PAYLOAD='{"message_id": "msg_001", "session_id": "sess_abc", "book_name": "三体", "message_content": "回答不准确。", "reasons": ["inaccurate"], "details": "AI说三体人是和平主义者"}'
check_api "POST /api/complaint" "curl -X POST '$BASE_URL/api/complaint' -H 'Content-Type: application/json' -d '$COMPLAINT_PAYLOAD'"

# 9. Submit Like
LIKE_PAYLOAD='{"message_id": "msg_002", "session_id": "sess_abc", "book_name": "三体", "message_content": "这个总结非常到位！"}'
check_api "POST /api/like" "curl -X POST '$BASE_URL/api/like' -H 'Content-Type: application/json' -d '$LIKE_PAYLOAD'"

echo "================================================="
echo "API verification complete."
echo ""
echo "--- Summary ---"
PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo "================================================="

# Exit with a non-zero status code if any test failed
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
