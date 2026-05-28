enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadItem {
  final int? id;
  final String url;
  final String fileName;
  final String filePath;
  int totalBytes;
  int downloadedBytes;
  DownloadStatus status;
  final DateTime startedAt;
  String? errorMessage;

  DownloadItem({
    this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.queued,
    DateTime? startedAt,
    this.errorMessage,
  }) : startedAt = startedAt ?? DateTime.now();

  double get progressPercent {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get formattedSize {
    if (totalBytes <= 0) return 'Unknown';
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'filePath': filePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.index,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as int?,
      url: map['url'] as String,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String,
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int),
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
