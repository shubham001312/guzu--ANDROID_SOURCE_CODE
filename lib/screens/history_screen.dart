import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<HistoryProvider>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final grouped = historyProvider.groupedHistory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (query) => setState(() {}),
              )
            : const Text('History'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          if (!_isSearching)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearDialog(context, historyProvider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear All History'),
                ),
              ],
            ),
        ],
      ),
      body: historyProvider.history.isEmpty
          ? _EmptyState()
          : _isSearching && _searchController.text.isNotEmpty
              ? FutureBuilder(
                  future: historyProvider.search(_searchController.text),
                  builder: (context, snapshot) {
                    final results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: AppTheme.textTertiary.withAlpha(80)),
                            const SizedBox(height: 12),
                            const Text('No results',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return _HistoryList(
                      entries: results,
                      onTap: (url) => Navigator.pop(context, url),
                      onDelete: (id) => historyProvider.deleteEntry(id),
                    );
                  },
                )
              : _GroupedHistoryList(
                  grouped: grouped,
                  onTap: (url) => Navigator.pop(context, url),
                  onDelete: (id) => historyProvider.deleteEntry(id),
                ),
    );
  }

  void _showClearDialog(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete all browsing history.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _GroupedHistoryList extends StatelessWidget {
  final Map<String, List> grouped;
  final Function(String) onTap;
  final Function(int) onDelete;

  const _GroupedHistoryList({
    required this.grouped,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingSm,
              ),
              child: Text(
                group.key,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...group.value.asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              return _HistoryTile(
                entry: entry,
                index: index,
                onTap: () => onTap(entry.url),
                onDelete: () => onDelete(entry.id!),
              );
            }),
            if (groupIndex < groups.length - 1) const Divider(),
          ],
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List entries;
  final Function(String) onTap;
  final Function(int) onDelete;

  const _HistoryList({
    required this.entries,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryTile(
          entry: entry,
          index: index,
          onTap: () => onTap(entry.url),
          onDelete: () => onDelete(entry.id!),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final dynamic entry;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Dismissible(
      key: Key('history_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error.withAlpha(30),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: 2,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Center(
            child: Text(
              _extractDomain(entry.url).isNotEmpty
                  ? _extractDomain(entry.url)[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _extractDomain(entry.url),
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timeFormat.format(entry.visitedAt),
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
        onTap: onTap,
      ).animate().fadeIn(duration: 150.ms, delay: (index * 20).ms),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 64, color: AppTheme.textTertiary.withAlpha(80)),
          const SizedBox(height: AppTheme.spacingMd),
          const Text(
            'No browsing history',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pages you visit will appear here',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
