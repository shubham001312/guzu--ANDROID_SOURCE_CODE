import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/tab_model.dart';

class TabProvider extends ChangeNotifier {
  final List<BrowserTab> _tabs = [];
  int _activeIndex = 0;
  final _uuid = const Uuid();

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  int get tabCount => _tabs.length;

  BrowserTab? get activeTab {
    if (_tabs.isEmpty) return null;
    if (_activeIndex >= _tabs.length) _activeIndex = _tabs.length - 1;
    return _tabs[_activeIndex];
  }

  /// Initialize with a single tab
  void init() {
    if (_tabs.isEmpty) {
      addTab();
    }
  }

  /// Add a new tab
  String addTab({String url = '', bool isIncognito = false}) {
    final id = _uuid.v4();
    _tabs.add(BrowserTab(
      id: id,
      url: url.isEmpty ? 'about:blank' : url,
      title: url.isEmpty ? 'New Tab' : url,
      isIncognito: isIncognito,
    ));
    _activeIndex = _tabs.length - 1;
    notifyListeners();
    return id;
  }

  /// Close a tab by index
  void closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, replace it with a blank one
      _tabs[0] = BrowserTab(
        id: _uuid.v4(),
        url: 'about:blank',
        title: 'New Tab',
      );
      _activeIndex = 0;
      notifyListeners();
      return;
    }

    _tabs.removeAt(index);
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
    notifyListeners();
  }

  /// Close a tab by ID
  void closeTabById(String id) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) closeTab(index);
  }

  /// Switch to a tab by index
  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  /// Update tab info
  void updateTab(String id, {
    String? url,
    String? title,
    String? faviconUrl,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return;

    final tab = _tabs[index];
    if (url != null) tab.url = url;
    if (title != null && title.isNotEmpty) tab.title = title;
    if (faviconUrl != null) tab.faviconUrl = faviconUrl;
    if (isLoading != null) tab.isLoading = isLoading;
    if (progress != null) tab.progress = progress;
    if (canGoBack != null) tab.canGoBack = canGoBack;
    if (canGoForward != null) tab.canGoForward = canGoForward;
    notifyListeners();
  }

  /// Update tab screenshot for tab switcher
  void updateScreenshot(String id, dynamic screenshot) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return;
    _tabs[index].screenshot = screenshot;
    // Don't notify here to avoid rebuilding the webview
  }

  /// Close all incognito tabs
  void closeIncognitoTabs() {
    _tabs.removeWhere((tab) => tab.isIncognito);
    if (_tabs.isEmpty) {
      addTab();
    }
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  /// Close all tabs
  void closeAllTabs() {
    _tabs.clear();
    addTab();
    notifyListeners();
  }

  /// Check if any incognito tabs are open
  bool get hasIncognitoTabs => _tabs.any((tab) => tab.isIncognito);

  /// Get count of incognito tabs
  int get incognitoTabCount => _tabs.where((tab) => tab.isIncognito).length;
}
