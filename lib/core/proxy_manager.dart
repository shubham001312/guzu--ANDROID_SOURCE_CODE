import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Proxy configuration types
enum ProxyType { http, socks5 }

/// Manages proxy/VPN routing for WebView traffic.
class ProxyManager {
  static final ProxyManager _instance = ProxyManager._internal();
  factory ProxyManager() => _instance;
  ProxyManager._internal();

  bool _enabled = false;
  bool get enabled => _enabled;

  String _host = '';
  int _port = 1080;
  ProxyType _type = ProxyType.socks5;
  String _username = '';
  String _password = '';

  String get host => _host;
  int get port => _port;
  ProxyType get type => _type;
  String get username => _username;
  String get password => _password;

  /// Configure the proxy server details
  void configure({
    required String host,
    required int port,
    ProxyType type = ProxyType.socks5,
    String username = '',
    String password = '',
  }) {
    _host = host;
    _port = port;
    _type = type;
    _username = username;
    _password = password;
  }

  /// Enable proxy routing
  Future<void> enable() async {
    if (_host.isEmpty) return;

    _enabled = true;

    final proxyController = ProxyController.instance();

    String proxyUrl;
    if (_username.isNotEmpty && _password.isNotEmpty) {
      proxyUrl = '$_username:$_password@$_host:$_port';
    } else {
      proxyUrl = '$_host:$_port';
    }

    final proxyRule = ProxyRule(
      url: proxyUrl,
    );

    await proxyController.setProxyOverride(
      settings: ProxySettings(
        proxyRules: [proxyRule],
        bypassRules: ['localhost', '127.0.0.1', '10.0.0.0/8'],
      ),
    );
  }

  /// Disable proxy routing
  Future<void> disable() async {
    _enabled = false;
    final proxyController = ProxyController.instance();
    await proxyController.clearProxyOverride();
  }

  /// Toggle proxy on/off
  Future<void> toggle() async {
    if (_enabled) {
      await disable();
    } else {
      await enable();
    }
  }

  /// Check if proxy is configured (has host set)
  bool get isConfigured => _host.isNotEmpty;

  /// Get display string for current proxy
  String get displayString {
    if (!isConfigured) return 'Not configured';
    final typeStr = _type == ProxyType.socks5 ? 'SOCKS5' : 'HTTP';
    return '$typeStr://$_host:$_port';
  }
}
