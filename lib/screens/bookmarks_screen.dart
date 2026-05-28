import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/bookmark_provider.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<BookmarkProvider>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bookmarks = bookmarkProvider.bookmarks;

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
                  hintText: 'Search bookmarks...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (query) {
                  setState(() {}); // rebuild to trigger FutureBuilder
                },
              )
            : const Text('Bookmarks'),
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
        ],
      ),
      body: bookmarks.isEmpty
          ? _EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No bookmarks yet',
              subtitle: 'Save your favorite pages for quick access',
            )
          : _isSearching && _searchController.text.isNotEmpty
              ? FutureBuilder(
                  future: bookmarkProvider.search(_searchController.text),
                  builder: (context, snapshot) {
                    final results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return _EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results',
                        subtitle: 'Try a different search term',
                      );
                    }
                    return _BookmarkList(
                      bookmarks: results,
                      onTap: (url) => Navigator.pop(context, url),
                      onDelete: (id) => bookmarkProvider.removeBookmark(id),
                    );
                  },
                )
              : _BookmarkList(
                  bookmarks: bookmarks,
                  onTap: (url) => Navigator.pop(context, url),
                  onDelete: (id) => bookmarkProvider.removeBookmark(id),
                ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  final List bookmarks;
  final Function(String) onTap;
  final Function(int) onDelete;

  const _BookmarkList({
    required this.bookmarks,
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return Dismissible(
          key: Key('bookmark_${bookmark.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppTheme.error.withAlpha(30),
            child: const Icon(Icons.delete_rounded, color: AppTheme.error),
          ),
          onDismissed: (_) => onDelete(bookmark.id!),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(
                child: Text(
                  _extractDomain(bookmark.url).isNotEmpty
                      ? _extractDomain(bookmark.url)[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              bookmark.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _extractDomain(bookmark.url),
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onTap(bookmark.url),
          ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.textTertiary.withAlpha(80)),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
