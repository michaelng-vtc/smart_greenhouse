class ChatUser {
  final int id;
  final String username;

  ChatUser({required this.id, required this.username});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: int.parse(json['id'].toString()),
      username: json['username'],
    );
  }
}
