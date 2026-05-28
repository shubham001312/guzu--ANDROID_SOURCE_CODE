import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';
import '../providers/browser_provider.dart';
import '../providers/history_provider.dart';
import '../providers/download_provider.dart';
import '../core/ad_blocker.dart';
import '../models/tab_model.dart';

/// Wraps a single InAppWebView instance for one tab.
class WebViewTab extends StatefulWidget {
  final BrowserTab tab;
  final Function(ScrollDirection) onScrollDirectionChanged;

  const WebViewTab({
    super.key,
    required this.tab,
    required this.onScrollDirectionChanged,
  });

  @override
  State<WebViewTab> createState() => WebViewTabState();
}

class WebViewTabState extends State<WebViewTab> {
  InAppWebViewController? _webViewController;
  double _lastScrollY = 0;
  bool _pageFinishedOnce = false;

  InAppWebViewController? get controller => _webViewController;

  Future<void> loadUrl(String url) async {
    if (_webViewController == null) return;
    await _webViewController!.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  Future<void> reload() async {
    await _webViewController?.reload();
  }

  Future<void> goBack() async {
    if (await _webViewController?.canGoBack() ?? false) {
      await _webViewController?.goBack();
    }
  }

  Future<void> goForward() async {
    if (await _webViewController?.canGoForward() ?? false) {
      await _webViewController?.goForward();
    }
  }

  Future<void> stopLoading() async {
    await _webViewController?.stopLoading();
  }

  Future<void> findInPage(String query) async {
    await _webViewController?.findAllAsync(find: query);
  }

  Future<void> clearFindInPage() async {
    await _webViewController?.clearMatches();
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final tabProvider = context.read<TabProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final downloadProvider = context.read<DownloadProvider>();
    final adBlocker = AdBlocker();

    final userAgent = browserProvider.desktopMode
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        : 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

    return InAppWebView(
      initialUrlRequest: widget.tab.url != 'about:blank' && widget.tab.url.isNotEmpty
          ? URLRequest(url: WebUri(widget.tab.url))
          : null,
      initialSettings: InAppWebViewSettings(
        // Core settings
        javaScriptEnabled: browserProvider.javaScriptEnabled,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheEnabled: !widget.tab.isIncognito,
        clearCache: widget.tab.isIncognito,
        incognito: widget.tab.isIncognito,

        // User Agent
        userAgent: userAgent,

        // Performance
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,

        // Media
        mediaPlaybackRequiresUserGesture: true,
        allowsInlineMediaPlayback: true,

        // Security
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        thirdPartyCookiesEnabled: !widget.tab.isIncognito,

        // Content blockers
        contentBlockers: adBlocker.getContentBlockers(),

        // Allow file access
        allowFileAccess: true,
        allowContentAccess: true,

        // Scroll
        verticalScrollBarEnabled: false,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        final urlStr = url?.toString() ?? '';
        tabProvider.updateTab(
          widget.tab.id,
          url: urlStr,
          isLoading: true,
          progress: 0.0,
        );
      },
      onProgressChanged: (controller, progress) {
        tabProvider.updateTab(
          widget.tab.id,
          progress: progress / 100.0,
          isLoading: progress < 100,
        );
      },
      onLoadStop: (controller, url) async {
        final urlStr = url?.toString() ?? '';
        final title = await controller.getTitle() ?? '';
        final canGoBack = await controller.canGoBack();
        final canGoForward = await controller.canGoForward();

        tabProvider.updateTab(
          widget.tab.id,
          url: urlStr,
          title: title.isNotEmpty ? title : urlStr,
          isLoading: false,
          progress: 1.0,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );

        // Save to history (skip incognito and blank pages)
        if (!widget.tab.isIncognito &&
            urlStr.isNotEmpty &&
            urlStr != 'about:blank') {
          await historyProvider.addEntry(urlStr, title.isNotEmpty ? title : urlStr);
        }

        // Capture screenshot for tab switcher
        if (!_pageFinishedOnce) {
          _pageFinishedOnce = true;
        }
        try {
          final screenshot = await controller.takeScreenshot(
            screenshotConfiguration: ScreenshotConfiguration(
              compressFormat: CompressFormat.JPEG,
              quality: 30,
            ),
          );
          if (screenshot != null) {
            tabProvider.updateScreenshot(widget.tab.id, screenshot);
          }
        } catch (_) {}
      },
      onTitleChanged: (controller, title) {
        if (title != null && title.isNotEmpty) {
          tabProvider.updateTab(widget.tab.id, title: title);
        }
      },
      onScrollChanged: (controller, x, y) {
        final delta = y - _lastScrollY;
        if (delta > 10) {
          widget.onScrollDirectionChanged(ScrollDirection.forward); // scrolling down
        } else if (delta < -10) {
          widget.onScrollDirectionChanged(ScrollDirection.reverse); // scrolling up
        }
        _lastScrollY = y.toDouble();
      },
      onDownloadStartRequest: (controller, request) async {
        final url = request.url.toString();
        final fileName = request.suggestedFilename ?? '';
        await downloadProvider.startDownload(url, fileName: fileName.isNotEmpty ? fileName : null);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${fileName.isNotEmpty ? fileName : "file"}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onReceivedError: (controller, request, error) {
        tabProvider.updateTab(
          widget.tab.id,
          isLoading: false,
        );
      },
      onCreateWindow: (controller, createWindowAction) async {
        // Open new window requests in a new tab
        final url = createWindowAction.request.url?.toString() ?? '';
        if (url.isNotEmpty) {
          tabProvider.addTab(url: url);
        }
        return false;
      },
      onConsoleMessage: (controller, consoleMessage) {
        // Silently consume console messages
      },
    );
  }

  @override
  void dispose() {
    // Clear incognito data
    if (widget.tab.isIncognito) {
      _webViewController?.clearCache();
      CookieManager.instance().deleteAllCookies();
    }
    super.dispose();
  }
}
