import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/browser_provider.dart';
import '../core/proxy_manager.dart';
import '../database/database_helper.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        children: [
          // ── Search Engine ──
          _SectionHeader('Search Engine'),
          _RadioTile<SearchEngine>(
            title: 'Google',
            value: SearchEngine.google,
            groupValue: browserProvider.searchEngine,
            onChanged: (v) => browserProvider.setSearchEngine(v!),
          ),
          _RadioTile<SearchEngine>(
            title: 'DuckDuckGo',
            subtitle: 'Privacy-focused',
            value: SearchEngine.duckduckgo,
            groupValue: browserProvider.searchEngine,
            onChanged: (v) => browserProvider.setSearchEngine(v!),
          ),
          _RadioTile<SearchEngine>(
            title: 'Brave Search',
            subtitle: 'Independent index',
            value: SearchEngine.brave,
            groupValue: browserProvider.searchEngine,
            onChanged: (v) => browserProvider.setSearchEngine(v!),
          ),
          _RadioTile<SearchEngine>(
            title: 'Bing',
            value: SearchEngine.bing,
            groupValue: browserProvider.searchEngine,
            onChanged: (v) => browserProvider.setSearchEngine(v!),
          ),

          const Divider(height: 32),

          // ── Privacy & Security ──
          _SectionHeader('Privacy & Security'),
          _ToggleTile(
            icon: Icons.shield_rounded,
            title: 'Ad & Tracker Blocker',
            subtitle: 'Block ads, trackers, and crypto miners',
            value: browserProvider.adBlockEnabled,
            activeColor: AppTheme.accent,
            onChanged: (v) => browserProvider.setAdBlockEnabled(v),
          ),
          _ToggleTile(
            icon: Icons.code_rounded,
            title: 'JavaScript',
            subtitle: 'Some sites may not work without JavaScript',
            value: browserProvider.javaScriptEnabled,
            activeColor: AppTheme.info,
            onChanged: (v) => browserProvider.setJavaScriptEnabled(v),
          ),

          const Divider(height: 32),

          // ── Proxy / VPN ──
          _SectionHeader('Proxy / VPN'),
          _ToggleTile(
            icon: Icons.vpn_lock_rounded,
            title: 'Enable Proxy',
            subtitle: browserProvider.proxyConfigured
                ? browserProvider.proxyManager.displayString
                : 'Configure proxy server first',
            value: browserProvider.proxyEnabled,
            activeColor: AppTheme.success,
            onChanged: (v) async {
              if (!browserProvider.proxyConfigured && v) {
                _showProxyConfigDialog(context, browserProvider);
                return;
              }
              await browserProvider.toggleProxy();
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.settings_ethernet_rounded,
                size: 20, color: AppTheme.textSecondary),
            title: const Text('Configure Proxy Server',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            subtitle: Text(
              browserProvider.proxyConfigured
                  ? browserProvider.proxyManager.displayString
                  : 'Set proxy host, port, and type',
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textTertiary),
            onTap: () => _showProxyConfigDialog(context, browserProvider),
          ),

          const Divider(height: 32),

          // ── Data ──
          _SectionHeader('Data & Storage'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppTheme.error),
            title: const Text('Clear Browsing Data',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            subtitle: const Text('History, cookies, cache',
                style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            onTap: () => _showClearDataDialog(context),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: const Icon(Icons.cookie_rounded,
                size: 20, color: AppTheme.textSecondary),
            title: const Text('Clear Cookies',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            onTap: () async {
              await CookieManager.instance().deleteAllCookies();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cookies cleared')),
                );
              }
            },
          ),

          const Divider(height: 32),

          // ── About ──
          _SectionHeader('About'),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(Icons.info_outline_rounded,
                size: 20, color: AppTheme.textSecondary),
            title: Text('GUZU Browser',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            subtitle: Text('Version 1.0.0',
                style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showProxyConfigDialog(
      BuildContext context, BrowserProvider browserProvider) {
    final hostController =
        TextEditingController(text: browserProvider.proxyManager.host);
    final portController = TextEditingController(
        text: browserProvider.proxyManager.port.toString());
    final userController =
        TextEditingController(text: browserProvider.proxyManager.username);
    final passController =
        TextEditingController(text: browserProvider.proxyManager.password);
    ProxyType selectedType = browserProvider.proxyManager.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Proxy Configuration',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: _ProxyTypeChip(
                        label: 'SOCKS5',
                        selected: selectedType == ProxyType.socks5,
                        onTap: () => setDialogState(
                            () => selectedType = ProxyType.socks5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProxyTypeChip(
                        label: 'HTTP',
                        selected: selectedType == ProxyType.http,
                        onTap: () => setDialogState(
                            () => selectedType = ProxyType.http),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host / IP Address',
                    hintText: '192.168.1.1 or proxy.example.com',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '1080',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Username (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final host = hostController.text.trim();
                final port = int.tryParse(portController.text.trim()) ?? 1080;
                if (host.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Host is required')),
                  );
                  return;
                }
                browserProvider.configureProxy(
                  host: host,
                  port: port,
                  type: selectedType,
                  username: userController.text.trim(),
                  password: passController.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Proxy configured: ${selectedType == ProxyType.socks5 ? "SOCKS5" : "HTTP"}://$host:$port'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Browsing Data',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'This will clear all history, cookies, cached data, and local storage. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear cookies
              await CookieManager.instance().deleteAllCookies();
              // Clear database
              await DatabaseHelper().clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All browsing data cleared')),
                );
              }
            },
            child:
                const Text('Clear All', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon,
          size: 20, color: value ? activeColor : AppTheme.textTertiary),
      title: Text(title,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textTertiary))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        activeTrackColor: activeColor.withAlpha(80),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textTertiary))
          : null,
      trailing: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
      ),
      onTap: () => onChanged(value),
    );
  }
}

class _ProxyTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProxyTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withAlpha(30) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.accent : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
