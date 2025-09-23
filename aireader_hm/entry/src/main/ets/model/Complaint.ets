
    export interface ComplaintData {
  message_id: string;
  session_id?: string;
  reasons: string[];
  details?: string;
  book_name: string;
  message_content: string;
}

export interface LikeData {
  message_id: string;
  session_id?: string;
  book_name: string;
  message_content: string;
}
    