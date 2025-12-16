class Comment {
  final int id;
  final int plantInfoId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.plantInfoId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['id'].toString()),
      plantInfoId: int.parse(json['plant_info_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      username: json['username'] ?? 'Unknown',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
