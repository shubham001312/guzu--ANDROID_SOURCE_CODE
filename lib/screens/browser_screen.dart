import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';
import '../providers/browser_provider.dart';
import '../widgets/url_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/browser_menu.dart';
import '../widgets/web_view_tab.dart';
import '../widgets/tab_switcher.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _barsVisible = true;
  bool _showTabSwitcher = false;
  bool _showFindInPage = false;
  final TextEditingController _findController = TextEditingController();

  // Key map to preserve WebView states across tab switches
  final Map<String, GlobalKey<WebViewTabState>> _webViewKeys = {};

  GlobalKey<WebViewTabState> _getKeyForTab(String tabId) {
    return _webViewKeys.putIfAbsent(tabId, () => GlobalKey<WebViewTabState>());
  }

  void _onScrollDirectionChanged(ScrollDirection direction) {
    if (direction == ScrollDirection.forward && _barsVisible) {
      setState(() => _barsVisible = false);
    } else if (direction == ScrollDirection.reverse && !_barsVisible) {
      setState(() => _barsVisible = true);
    }
  }

  void _navigateTo(String url) {
    final tabProvider = context.read<TabProvider>();
    final activeTab = tabProvider.activeTab;
    if (activeTab == null) return;

    final key = _getKeyForTab(activeTab.id);
    key.currentState?.loadUrl(url);
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BrowserMenu(
        onNewTab: _openNewTab,
        onNewIncognitoTab: _openNewIncognitoTab,
        onBookmarks: () => _openPage(const BookmarksScreen()),
        onHistory: () => _openPage(const HistoryScreen()),
        onDownloads: () => _openPage(const DownloadsScreen()),
        onSettings: () => _openPage(const SettingsScreen()),
        onShare: _shareCurrentPage,
        onFindInPage: () {
          setState(() => _showFindInPage = true);
        },
        onReload: () {
          final tabProvider = context.read<TabProvider>();
          final activeTab = tabProvider.activeTab;
          if (activeTab != null) {
            _getKeyForTab(activeTab.id).currentState?.reload();
          }
        },
      ),
    );
  }

  void _openNewTab() {
    final tabProvider = context.read<TabProvider>();
    tabProvider.addTab();
    setState(() {
      _showTabSwitcher = false;
      _barsVisible = true;
    });
  }

  void _openNewIncognitoTab() {
    final tabProvider = context.read<TabProvider>();
    tabProvider.addTab(isIncognito: true);
    setState(() {
      _showTabSwitcher = false;
      _barsVisible = true;
    });
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((result) {
      // If a URL was returned, navigate to it
      if (result != null && result is String) {
        _navigateTo(result);
      }
    });
  }

  void _shareCurrentPage() {
    final tabProvider = context.read<TabProvider>();
    final activeTab = tabProvider.activeTab;
    if (activeTab != null && activeTab.url != 'about:blank') {
      Share.share(activeTab.url);
    }
  }

  void _goHome() {
    final browserProvider = context.read<BrowserProvider>();
    _navigateTo(browserProvider.homepageUrl);
    setState(() => _barsVisible = true);
  }

  void _handleReloadOrStop() {
    final tabProvider = context.read<TabProvider>();
    final activeTab = tabProvider.activeTab;
    if (activeTab == null) return;

    final key = _getKeyForTab(activeTab.id);
    if (activeTab.isLoading) {
      key.currentState?.stopLoading();
    } else {
      key.currentState?.reload();
    }
  }

  @override
  void dispose() {
    _findController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTabSwitcher) {
      return TabSwitcher(
        onNewTab: _openNewTab,
        onNewIncognitoTab: _openNewIncognitoTab,
        onClose: () => setState(() => _showTabSwitcher = false),
      );
    }

    final tabProvider = context.watch<TabProvider>();
    final tabs = tabProvider.tabs;
    final activeIndex = tabProvider.activeIndex;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // URL Bar (top)
            UrlBar(
              isVisible: _barsVisible,
              onTap: () {},
              onSubmitted: _navigateTo,
              onMenuPressed: _handleReloadOrStop,
            ),

            // Find in Page bar
            if (_showFindInPage)
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.accent, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _findController,
                        autofocus: true,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Find in page...',
                          hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          filled: false,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final activeTab = tabProvider.activeTab;
                            if (activeTab != null) {
                              _getKeyForTab(activeTab.id).currentState?.findInPage(value);
                            }
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                      onPressed: () {
                        setState(() => _showFindInPage = false);
                        _findController.clear();
                        final activeTab = tabProvider.activeTab;
                        if (activeTab != null) {
                          _getKeyForTab(activeTab.id).currentState?.clearFindInPage();
                        }
                      },
                    ),
                  ],
                ),
              ),

            // WebView stack
            Expanded(
              child: IndexedStack(
                index: activeIndex,
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  return WebViewTab(
                    key: _getKeyForTab(tab.id),
                    tab: tab,
                    onScrollDirectionChanged: _onScrollDirectionChanged,
                  );
                }),
              ),
            ),

            // New Tab landing (show when about:blank)
            // This is handled inside the webview as an empty view

            // Bottom Navigation
            BottomNav(
              isVisible: _barsVisible,
              onBack: () {
                final activeTab = tabProvider.activeTab;
                if (activeTab != null) {
                  _getKeyForTab(activeTab.id).currentState?.goBack();
                }
              },
              onForward: () {
                final activeTab = tabProvider.activeTab;
                if (activeTab != null) {
                  _getKeyForTab(activeTab.id).currentState?.goForward();
                }
              },
              onTabsPressed: () => setState(() => _showTabSwitcher = true),
              onMenuPressed: _showMenu,
              onHomePressed: _goHome,
            ),
          ],
        ),
      ),
    );
  }
}
