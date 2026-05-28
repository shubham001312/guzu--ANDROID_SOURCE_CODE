import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/history_model.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<HistoryEntry> _history = [];
  bool _loaded = false;

  List<HistoryEntry> get history => _history;

  Future<void> load() async {
    if (_loaded) return;
    _history = await _db.getHistory();
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _history = await _db.getHistory();
    notifyListeners();
  }

  Future<void> addEntry(String url, String title) async {
    if (url.isEmpty || url == 'about:blank') return;
    final entry = HistoryEntry(
      url: url,
      title: title.isEmpty ? url : title,
    );
    await _db.insertHistory(entry);
    await reload();
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteHistoryEntry(id);
    await reload();
  }

  Future<void> clearAll() async {
    await _db.clearHistory();
    _history.clear();
    notifyListeners();
  }

  Future<List<HistoryEntry>> search(String query) async {
    if (query.isEmpty) return _history;
    return await _db.searchHistory(query);
  }

  /// Group history entries by date labels
  Map<String, List<HistoryEntry>> get groupedHistory {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<HistoryEntry>> grouped = {};

    for (final entry in _history) {
      final entryDate = DateTime(
        entry.visitedAt.year,
        entry.visitedAt.month,
        entry.visitedAt.day,
      );

      String label;
      if (entryDate == today) {
        label = 'Today';
      } else if (entryDate == yesterday) {
        label = 'Yesterday';
      } else if (entryDate.isAfter(lastWeek)) {
        label = 'This Week';
      } else {
        label = 'Older';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(entry);
    }

    return grouped;
  }
}
