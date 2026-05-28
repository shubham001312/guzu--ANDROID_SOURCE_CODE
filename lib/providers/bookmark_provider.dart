import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/bookmark_model.dart';

class BookmarkProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Bookmark> _bookmarks = [];
  bool _loaded = false;

  List<Bookmark> get bookmarks => _bookmarks;

  Future<void> load() async {
    if (_loaded) return;
    _bookmarks = await _db.getBookmarks();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _bookmarks = await _db.getBookmarks();
    notifyListeners();
  }

  Future<void> addBookmark(String url, String title, {String? faviconUrl}) async {
    final bookmark = Bookmark(
      url: url,
      title: title.isEmpty ? url : title,
      faviconUrl: faviconUrl,
    );
    await _db.insertBookmark(bookmark);
    await reload();
  }

  Future<void> removeBookmark(int id) async {
    await _db.deleteBookmark(id);
    await reload();
  }

  Future<void> removeBookmarkByUrl(String url) async {
    await _db.deleteBookmarkByUrl(url);
    await reload();
  }

  Future<bool> isBookmarked(String url) async {
    return await _db.isBookmarked(url);
  }

  Future<void> toggleBookmark(String url, String title, {String? faviconUrl}) async {
    final exists = await isBookmarked(url);
    if (exists) {
      await removeBookmarkByUrl(url);
    } else {
      await addBookmark(url, title, faviconUrl: faviconUrl);
    }
  }

  Future<List<Bookmark>> search(String query) async {
    if (query.isEmpty) return _bookmarks;
    return await _db.searchBookmarks(query);
  }
}
