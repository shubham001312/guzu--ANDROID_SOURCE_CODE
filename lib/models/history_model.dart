class HistoryEntry {
  final int? id;
  final String url;
  final String title;
  final DateTime visitedAt;

  HistoryEntry({
    this.id,
    required this.url,
    required this.title,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'visitedAt': visitedAt.millisecondsSinceEpoch,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(map['visitedAt'] as int),
    );
  }
}
