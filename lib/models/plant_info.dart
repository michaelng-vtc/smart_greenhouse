class PlantInfo {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  PlantInfo({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) {
    return PlantInfo(
      id: int.parse(json['id'].toString()),
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
