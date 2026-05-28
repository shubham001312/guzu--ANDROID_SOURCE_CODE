import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';
import '../providers/browser_provider.dart';
import '../providers/bookmark_provider.dart';
import '../core/ad_blocker.dart';

class BrowserMenu extends StatelessWidget {
  final VoidCallback onNewTab;
  final VoidCallback onNewIncognitoTab;
  final VoidCallback onBookmarks;
  final VoidCallback onHistory;
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  final VoidCallback onShare;
  final VoidCallback onFindInPage;
  final VoidCallback? onReload;

  const BrowserMenu({
    super.key,
    required this.onNewTab,
    required this.onNewIncognitoTab,
    required this.onBookmarks,
    required this.onHistory,
    required this.onDownloads,
    required this.onSettings,
    required this.onShare,
    required this.onFindInPage,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final tabProvider = context.watch<TabProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();
    final activeTab = tabProvider.activeTab;
    final currentUrl = activeTab?.url ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Quick action row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAction(
                  icon: Icons.add_rounded,
                  label: 'New Tab',
                  onTap: () {
                    Navigator.pop(context);
                    onNewTab();
                  },
                ),
                _QuickAction(
                  icon: Icons.visibility_off_rounded,
                  label: 'Incognito',
                  color: AppTheme.incognitoAccent,
                  onTap: () {
                    Navigator.pop(context);
                    onNewIncognitoTab();
                  },
                ),
                FutureBuilder<bool>(
                  future: currentUrl.isNotEmpty && currentUrl != 'about:blank'
                      ? bookmarkProvider.isBookmarked(currentUrl)
                      : Future.value(false),
                  builder: (context, snapshot) {
                    final isBookmarked = snapshot.data ?? false;
                    return _QuickAction(
                      icon: isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: isBookmarked ? 'Saved' : 'Save',
                      color: isBookmarked ? AppTheme.accent : null,
                      onTap: () async {
                        if (currentUrl.isNotEmpty &&
                            currentUrl != 'about:blank') {
                          await bookmarkProvider.toggleBookmark(
                            currentUrl,
                            activeTab?.title ?? currentUrl,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
                _QuickAction(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    onShare();
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Toggle switches
          _ToggleTile(
            icon: Icons.shield_rounded,
            title: 'Ad & Tracker Blocker',
            subtitle: '${AdBlocker().blockedDomainCount} domains blocked',
            value: browserProvider.adBlockEnabled,
            activeColor: AppTheme.accent,
            onChanged: (v) => browserProvider.setAdBlockEnabled(v),
          ),
          _ToggleTile(
            icon: Icons.vpn_lock_rounded,
            title: 'Proxy / VPN',
            subtitle: browserProvider.proxyConfigured
                ? browserProvider.proxyManager.displayString
                : 'Not configured',
            value: browserProvider.proxyEnabled,
            activeColor: AppTheme.success,
            onChanged: (v) async {
              if (!browserProvider.proxyConfigured && v) {
                Navigator.pop(context);
                onSettings();
                return;
              }
              await browserProvider.toggleProxy();
            },
          ),
          _ToggleTile(
            icon: Icons.desktop_windows_rounded,
            title: 'Desktop Mode',
            value: browserProvider.desktopMode,
            activeColor: AppTheme.info,
            onChanged: (v) => browserProvider.setDesktopMode(v),
          ),

          const Divider(),

          // Menu items
          _MenuItem(
            icon: Icons.bookmark_border_rounded,
            title: 'Bookmarks',
            onTap: () {
              Navigator.pop(context);
              onBookmarks();
            },
          ),
          _MenuItem(
            icon: Icons.history_rounded,
            title: 'History',
            onTap: () {
              Navigator.pop(context);
              onHistory();
            },
          ),
          _MenuItem(
            icon: Icons.download_rounded,
            title: 'Downloads',
            onTap: () {
              Navigator.pop(context);
              onDownloads();
            },
          ),
          _MenuItem(
            icon: Icons.search_rounded,
            title: 'Find in Page',
            onTap: () {
              Navigator.pop(context);
              onFindInPage();
            },
          ),
          _MenuItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              onSettings();
            },
          ),

          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}



class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.textSecondary).withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(
        icon,
        size: 20,
        color: value ? activeColor : AppTheme.textTertiary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            )
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
