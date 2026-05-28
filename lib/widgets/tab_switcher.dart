import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';

class TabSwitcher extends StatelessWidget {
  final VoidCallback onNewTab;
  final VoidCallback onNewIncognitoTab;
  final VoidCallback onClose;

  const TabSwitcher({
    super.key,
    required this.onNewTab,
    required this.onNewIncognitoTab,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final tabs = tabProvider.tabs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
        title: Text(
          '${tabs.length} ${tabs.length == 1 ? 'Tab' : 'Tabs'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
            onSelected: (value) {
              if (value == 'close_all') {
                tabProvider.closeAllTabs();
                onClose();
              } else if (value == 'close_incognito') {
                tabProvider.closeIncognitoTabs();
                if (tabProvider.tabCount == 0) onClose();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'close_all',
                child: Text('Close All Tabs'),
              ),
              if (tabProvider.hasIncognitoTabs)
                const PopupMenuItem(
                  value: 'close_incognito',
                  child: Text('Close Incognito Tabs'),
                ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = index == tabProvider.activeIndex;

          return GestureDetector(
            onTap: () {
              tabProvider.switchToTab(index);
              onClose();
            },
            child: AnimatedContainer(
              duration: AppTheme.animNormal,
              decoration: BoxDecoration(
                color: tab.isIncognito ? AppTheme.incognito : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isActive ? AppTheme.accent : AppTheme.border,
                  width: isActive ? 2.0 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab header
                  Container(
                    padding: const EdgeInsets.only(left: 10, right: 4, top: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: tab.isIncognito
                          ? AppTheme.incognito.withAlpha(200)
                          : AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMd - 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (tab.isIncognito)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.visibility_off_rounded,
                              size: 14,
                              color: AppTheme.incognitoAccent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            tab.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: tab.isIncognito
                                  ? AppTheme.incognitoAccent
                                  : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textTertiary,
                            ),
                            onPressed: () {
                              tabProvider.closeTab(index);
                              if (tabProvider.tabCount == 0) onClose();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab preview
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppTheme.radiusMd - 1),
                      ),
                      child: tab.screenshot != null
                          ? Image.memory(
                              tab.screenshot!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: tab.isIncognito
                                  ? AppTheme.incognito
                                  : AppTheme.surfaceVariant,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab.isIncognito
                                          ? Icons.visibility_off_rounded
                                          : Icons.language_rounded,
                                      size: 32,
                                      color: AppTheme.textTertiary.withAlpha(100),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        _extractDomain(tab.url),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textTertiary.withAlpha(120),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms, delay: (index * 50).ms).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 250.ms,
                  delay: (index * 50).ms,
                  curve: Curves.easeOut,
                ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: _NewTabButton(
                  icon: Icons.add_rounded,
                  label: 'New Tab',
                  onTap: onNewTab,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NewTabButton(
                  icon: Icons.visibility_off_rounded,
                  label: 'Incognito',
                  color: AppTheme.incognitoAccent,
                  onTap: onNewIncognitoTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      if (url == 'about:blank' || url.isEmpty) return 'New Tab';
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

class _NewTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _NewTabButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return Material(
      color: c.withAlpha(20),
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
