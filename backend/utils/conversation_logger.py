import os
from datetime import datetime

LOGS_DIR = "logs"
if not os.path.exists(LOGS_DIR):
    os.makedirs(LOGS_DIR)

def log_conversation(book_name: str, question: str, answer: str):
    """将用户问题和AI回答记录到文件中"""
    # 清理书名以创建有效的文件名
    safe_book_name = "".join(c for c in book_name if c.isalnum() or c in (' ', '.', '_')).rstrip()
    log_file = os.path.join(LOGS_DIR, f"{safe_book_name}.txt")
    
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    log_entry = (
        f"--- Conversation Log: {timestamp} ---\n"
        f"Book: {book_name}\n"
        f"User Question: {question}\n"
        f"AI Answer: {answer}\n"
        f"----------------------------------------\n\n"
    )
    
    try:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(log_entry)
    except IOError as e:
        print(f"Error writing to log file {log_file}: {e}")
