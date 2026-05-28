class Bookmark {
  final int? id;
  final String url;
  final String title;
  final String? faviconUrl;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.url,
    required this.title,
    this.faviconUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'faviconUrl': faviconUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      faviconUrl: map['faviconUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
