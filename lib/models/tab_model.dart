import 'dart:typed_data';

class BrowserTab {
  final String id;
  String url;
  String title;
  String? faviconUrl;
  final bool isIncognito;
  Uint8List? screenshot;
  bool isLoading;
  double progress;
  bool canGoBack;
  bool canGoForward;

  BrowserTab({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.faviconUrl,
    this.isIncognito = false,
    this.screenshot,
    this.isLoading = false,
    this.progress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  BrowserTab copyWith({
    String? url,
    String? title,
    String? faviconUrl,
    Uint8List? screenshot,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      isIncognito: isIncognito,
      screenshot: screenshot ?? this.screenshot,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
    );
  }
}
