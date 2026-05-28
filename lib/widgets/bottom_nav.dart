import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';

class BottomNav extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onTabsPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onHomePressed;

  const BottomNav({
    super.key,
    required this.isVisible,
    required this.onBack,
    required this.onForward,
    required this.onTabsPressed,
    required this.onMenuPressed,
    required this.onHomePressed,
  });

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final activeTab = tabProvider.activeTab;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1.5),
      duration: AppTheme.animNormal,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: AppTheme.animFast,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(240),
            border: const Border(
              top: BorderSide(color: AppTheme.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: onBack,
                    enabled: activeTab?.canGoBack ?? false,
                  ),
                  _NavButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onTap: onForward,
                    enabled: activeTab?.canGoForward ?? false,
                  ),
                  _NavButton(
                    icon: Icons.home_rounded,
                    onTap: onHomePressed,
                  ),
                  _TabCountButton(
                    count: tabProvider.tabCount,
                    hasIncognito: tabProvider.hasIncognitoTabs,
                    onTap: onTabsPressed,
                  ),
                  _NavButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: onMenuPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppTheme.textSecondary : AppTheme.textTertiary.withAlpha(80),
          ),
        ),
      ),
    );
  }
}

class _TabCountButton extends StatelessWidget {
  final int count;
  final bool hasIncognito;
  final VoidCallback onTap;

  const _TabCountButton({
    required this.count,
    required this.hasIncognito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasIncognito
                      ? AppTheme.incognitoAccent
                      : AppTheme.textSecondary,
                  width: 1.8,
                ),
              ),
              child: Center(
                child: Text(
                  count > 99 ? ':D' : count.toString(),
                  style: TextStyle(
                    color: hasIncognito
                        ? AppTheme.incognitoAccent
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
