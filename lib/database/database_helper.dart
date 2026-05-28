import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bookmark_model.dart';
import '../models/history_model.dart';
import '../models/download_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'guzu_browser.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        faviconUrl TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        visitedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        totalBytes INTEGER DEFAULT 0,
        downloadedBytes INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        startedAt INTEGER NOT NULL,
        errorMessage TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_history_visitedAt ON history (visitedAt DESC)');
    await db.execute(
        'CREATE INDEX idx_bookmarks_createdAt ON bookmarks (createdAt DESC)');
  }

  // ── Bookmarks ──

  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', bookmark.toMap());
  }

  Future<List<Bookmark>> getBookmarks() async {
    final db = await database;
    final maps = await db.query('bookmarks', orderBy: 'createdAt DESC');
    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  Future<List<Bookmark>> searchBookmarks(String query) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'title LIKE ? OR url LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  Future<bool> isBookmarked(String url) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> deleteBookmark(int id) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBookmarkByUrl(String url) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'url = ?', whereArgs: [url]);
  }

  // ── History ──

  Future<int> insertHistory(HistoryEntry entry) async {
    final db = await database;
    return await db.insert('history', entry.toMap());
  }

  Future<List<HistoryEntry>> getHistory({int limit = 200}) async {
    final db = await database;
    final maps =
        await db.query('history', orderBy: 'visitedAt DESC', limit: limit);
    return maps.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  Future<List<HistoryEntry>> searchHistory(String query) async {
    final db = await database;
    final maps = await db.query(
      'history',
      where: 'title LIKE ? OR url LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'visitedAt DESC',
      limit: 100,
    );
    return maps.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('history');
  }

  Future<int> deleteHistoryEntry(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  // ── Downloads ──

  Future<int> insertDownload(DownloadItem item) async {
    final db = await database;
    return await db.insert('downloads', item.toMap());
  }

  Future<List<DownloadItem>> getDownloads() async {
    final db = await database;
    final maps = await db.query('downloads', orderBy: 'startedAt DESC');
    return maps.map((map) => DownloadItem.fromMap(map)).toList();
  }

  Future<int> updateDownload(DownloadItem item) async {
    final db = await database;
    return await db.update(
      'downloads',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    return await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearDownloads() async {
    final db = await database;
    return await db.delete('downloads');
  }

  // ── Clear All Data ──

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('bookmarks');
    await db.delete('history');
    await db.delete('downloads');
  }
}
