import 'package:flutter/material.dart';
import '../core/ad_blocker.dart';
import '../core/proxy_manager.dart';

enum SearchEngine { google, duckduckgo, bing, brave }

class BrowserProvider extends ChangeNotifier {
  final AdBlocker _adBlocker = AdBlocker();
  final ProxyManager _proxyManager = ProxyManager();

  AdBlocker get adBlocker => _adBlocker;
  ProxyManager get proxyManager => _proxyManager;

  // ── Ad Blocking ──
  bool get adBlockEnabled => _adBlocker.enabled;

  void setAdBlockEnabled(bool enabled) {
    _adBlocker.enabled = enabled;
    notifyListeners();
  }

  // ── Proxy / VPN ──
  bool get proxyEnabled => _proxyManager.enabled;
  bool get proxyConfigured => _proxyManager.isConfigured;

  Future<void> toggleProxy() async {
    await _proxyManager.toggle();
    notifyListeners();
  }

  void configureProxy({
    required String host,
    required int port,
    ProxyType type = ProxyType.socks5,
    String username = '',
    String password = '',
  }) {
    _proxyManager.configure(
      host: host,
      port: port,
      type: type,
      username: username,
      password: password,
    );
    notifyListeners();
  }

  Future<void> enableProxy() async {
    await _proxyManager.enable();
    notifyListeners();
  }

  Future<void> disableProxy() async {
    await _proxyManager.disable();
    notifyListeners();
  }

  // ── Desktop Mode ──
  bool _desktopMode = false;
  bool get desktopMode => _desktopMode;

  void setDesktopMode(bool enabled) {
    _desktopMode = enabled;
    notifyListeners();
  }

  // ── JavaScript ──
  bool _javaScriptEnabled = true;
  bool get javaScriptEnabled => _javaScriptEnabled;

  void setJavaScriptEnabled(bool enabled) {
    _javaScriptEnabled = enabled;
    notifyListeners();
  }

  // ── Search Engine ──
  SearchEngine _searchEngine = SearchEngine.google;
  SearchEngine get searchEngine => _searchEngine;

  void setSearchEngine(SearchEngine engine) {
    _searchEngine = engine;
    notifyListeners();
  }

  String get searchUrl {
    switch (_searchEngine) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/?q=';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=';
      case SearchEngine.brave:
        return 'https://search.brave.com/search?q=';
    }
  }

  String get searchEngineLabel {
    switch (_searchEngine) {
      case SearchEngine.google:
        return 'Google';
      case SearchEngine.duckduckgo:
        return 'DuckDuckGo';
      case SearchEngine.bing:
        return 'Bing';
      case SearchEngine.brave:
        return 'Brave';
    }
  }

  /// Convert user input to a URL or search query
  String resolveInput(String input) {
    input = input.trim();
    if (input.isEmpty) return 'about:blank';

    // Check if it's already a URL
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }

    // Check if it looks like a domain
    if (input.contains('.') &&
        !input.contains(' ') &&
        RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z]{2,})+').hasMatch(input)) {
      return 'https://$input';
    }

    // Treat as search query
    return '$searchUrl${Uri.encodeComponent(input)}';
  }

  // ── Homepage URL ──
  String get homepageUrl => searchUrl.replaceAll(RegExp(r'\?.*'), '');
}
