class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.parse(json['id'].toString()),
      senderId: int.parse(json['sender_id'].toString()),
      receiverId: int.parse(json['receiver_id'].toString()),
      senderName: json['sender_name'] ?? 'Unknown',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
