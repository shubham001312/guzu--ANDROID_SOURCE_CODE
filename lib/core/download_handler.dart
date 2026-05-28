import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/download_model.dart';

/// Handles file downloads with progress tracking using Dio.
class DownloadHandler {
  static final DownloadHandler _instance = DownloadHandler._internal();
  factory DownloadHandler() => _instance;
  DownloadHandler._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
    followRedirects: true,
    maxRedirects: 5,
  ));

  final Map<String, CancelToken> _cancelTokens = {};

  /// Get the download directory path
  Future<String> get downloadDir async {
    // Try external storage first (visible in file manager)
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      final downloadPath = p.join(dir.path, 'Downloads');
      await Directory(downloadPath).create(recursive: true);
      return downloadPath;
    }
    // Fallback to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final downloadPath = p.join(appDir.path, 'Downloads');
    await Directory(downloadPath).create(recursive: true);
    return downloadPath;
  }

  /// Extract a filename from the URL or response headers
  String extractFileName(String url, {String? contentDisposition}) {
    if (contentDisposition != null) {
      final match =
          RegExp(r"""filename[^;=\n]*=(["']?)(.+?)\1(;|$)""")
              .firstMatch(contentDisposition);
      if (match != null) return match.group(2) ?? _fileNameFromUrl(url);
    }
    return _fileNameFromUrl(url);
  }

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final last = pathSegments.last;
        if (last.contains('.') && last.length < 256) return last;
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Start downloading a file
  Future<DownloadItem> startDownload({
    required String url,
    String? customFileName,
    required Function(DownloadItem) onProgress,
    required Function(DownloadItem) onComplete,
    required Function(DownloadItem) onError,
  }) async {
    final dirPath = await downloadDir;
    final fileName = customFileName ?? _fileNameFromUrl(url);
    final filePath = _getUniqueFilePath(dirPath, fileName);
    final cancelToken = CancelToken();

    final item = DownloadItem(
      url: url,
      fileName: p.basename(filePath),
      filePath: filePath,
      status: DownloadStatus.downloading,
    );

    _cancelTokens[url] = cancelToken;

    try {
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          item.downloadedBytes = received;
          if (total != -1) {
            item.totalBytes = total;
          }
          item.status = DownloadStatus.downloading;
          onProgress(item);
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': '*/*',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      item.status = DownloadStatus.completed;
      _cancelTokens.remove(url);
      onComplete(item);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        item.status = DownloadStatus.cancelled;
        item.errorMessage = 'Cancelled';
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = e.message ?? 'Download failed';
      }
      _cancelTokens.remove(url);
      onError(item);
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
      _cancelTokens.remove(url);
      onError(item);
    }

    return item;
  }

  /// Cancel an active download
  void cancelDownload(String url) {
    _cancelTokens[url]?.cancel('User cancelled');
    _cancelTokens.remove(url);
  }

  /// Ensure unique file name by appending (1), (2), etc.
  String _getUniqueFilePath(String dirPath, String fileName) {
    var filePath = p.join(dirPath, fileName);
    var file = File(filePath);
    var counter = 1;

    while (file.existsSync()) {
      final ext = p.extension(fileName);
      final nameWithoutExt = p.basenameWithoutExtension(fileName);
      filePath = p.join(dirPath, '${nameWithoutExt}_($counter)$ext');
      file = File(filePath);
      counter++;
    }

    return filePath;
  }
}
