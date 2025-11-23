class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;

  ChatMessage({
    this.id = '',
    required this.senderId,
    required this.receiverId,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
    this.attachmentUrl,
  }) : this.timestamp = timestamp ?? DateTime.now();
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Ensure both ids are strings
    String senderId = json['sender_id']?.toString() ?? '';
    String receiverId = json['receiver_id']?.toString() ?? '';

    if (senderId.isEmpty) {
      print('Warning: Empty senderId in ChatMessage.fromJson');
    }
    if (receiverId.isEmpty) {
      print('Warning: Empty receiverId in ChatMessage.fromJson');
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: senderId,
      receiverId: receiverId,
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
      'attachment_url': attachmentUrl,
    };
  }
}
