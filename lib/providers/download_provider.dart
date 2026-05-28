import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/download_model.dart';
import '../core/download_handler.dart';

class DownloadProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final DownloadHandler _handler = DownloadHandler();
  List<DownloadItem> _downloads = [];
  bool _loaded = false;

  List<DownloadItem> get downloads => _downloads;
  DownloadHandler get handler => _handler;

  Future<void> load() async {
    if (_loaded) return;
    _downloads = await _db.getDownloads();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _downloads = await _db.getDownloads();
    notifyListeners();
  }

  Future<void> startDownload(String url, {String? fileName}) async {
    await _handler.startDownload(
      url: url,
      customFileName: fileName,
      onProgress: (item) {
        _updateInList(item);
        notifyListeners();
      },
      onComplete: (item) async {
        _updateInList(item);
        // Persist the final state
        final existingIdx = _downloads.indexWhere((d) => d.url == item.url);
        if (existingIdx != -1 && _downloads[existingIdx].id != null) {
          await _db.updateDownload(item);
        }
        notifyListeners();
      },
      onError: (item) async {
        _updateInList(item);
        final existingIdx = _downloads.indexWhere((d) => d.url == item.url);
        if (existingIdx != -1 && _downloads[existingIdx].id != null) {
          await _db.updateDownload(item);
        }
        notifyListeners();
      },
    );

    // Insert into DB after starting
    final idx = _downloads.indexWhere((d) => d.url == url);
    if (idx != -1) {
      final id = await _db.insertDownload(_downloads[idx]);
      // We can't update the id directly since it's final, but the record is in DB
      await reload();
    }
  }

  void _updateInList(DownloadItem item) {
    final idx = _downloads.indexWhere((d) => d.url == item.url);
    if (idx != -1) {
      _downloads[idx] = item;
    } else {
      _downloads.insert(0, item);
    }
  }

  void cancelDownload(String url) {
    _handler.cancelDownload(url);
    final idx = _downloads.indexWhere((d) => d.url == url);
    if (idx != -1) {
      _downloads[idx].status = DownloadStatus.cancelled;
      notifyListeners();
    }
  }

  Future<void> retryDownload(String url) async {
    final idx = _downloads.indexWhere((d) => d.url == url);
    if (idx != -1) {
      _downloads.removeAt(idx);
      notifyListeners();
      await startDownload(url);
    }
  }

  Future<void> deleteRecord(int id) async {
    await _db.deleteDownload(id);
    await reload();
  }

  Future<void> clearAll() async {
    await _db.clearDownloads();
    _downloads.clear();
    notifyListeners();
  }

  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.downloading).toList();

  List<DownloadItem> get completedDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.completed).toList();
}
