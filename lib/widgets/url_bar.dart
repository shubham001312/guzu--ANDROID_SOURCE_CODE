import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/tab_provider.dart';
import '../providers/browser_provider.dart';

/// A unified search/URL bar that hides on scroll down and shows on scroll up.
class UrlBar extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onTap;
  final Function(String) onSubmitted;
  final VoidCallback onMenuPressed;

  const UrlBar({
    super.key,
    required this.isVisible,
    required this.onTap,
    required this.onSubmitted,
    required this.onMenuPressed,
  });

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  bool _isSecure(String url) {
    return url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabProvider>();
    final browserProvider = context.watch<BrowserProvider>();
    final activeTab = tabProvider.activeTab;
    final url = activeTab?.url ?? '';
    final isLoading = activeTab?.isLoading ?? false;
    final progress = activeTab?.progress ?? 0.0;

    return AnimatedSlide(
      offset: widget.isVisible ? Offset.zero : const Offset(0, -1.5),
      duration: AppTheme.animNormal,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: AppTheme.animFast,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // URL Bar
              GestureDetector(
                onTap: () {
                  setState(() => _isEditing = true);
                  _controller.text = url == 'about:blank' ? '' : url;
                  _focusNode.requestFocus();
                  _controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controller.text.length,
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: activeTab?.isIncognito == true
                        ? AppTheme.incognito
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: _isEditing
                          ? AppTheme.accent
                          : AppTheme.border,
                      width: _isEditing ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      // Security / Incognito icon
                      if (activeTab?.isIncognito == true)
                        const Icon(
                          Icons.visibility_off_rounded,
                          size: 18,
                          color: AppTheme.incognitoAccent,
                        )
                      else if (url.isNotEmpty && url != 'about:blank')
                        Icon(
                          _isSecure(url)
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 16,
                          color: _isSecure(url)
                              ? AppTheme.success
                              : AppTheme.warning,
                        )
                      else
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppTheme.textTertiary,
                        ),
                      const SizedBox(width: 10),

                      // URL display or edit field
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  hintText: 'Search or enter URL',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 14,
                                  ),
                                  filled: false,
                                ),
                                textInputAction: TextInputAction.go,
                                keyboardType: TextInputType.url,
                                autocorrect: false,
                                onSubmitted: (value) {
                                  setState(() => _isEditing = false);
                                  final resolved =
                                      browserProvider.resolveInput(value);
                                  widget.onSubmitted(resolved);
                                },
                                onTapOutside: (_) {
                                  setState(() => _isEditing = false);
                                  _focusNode.unfocus();
                                },
                              )
                            : Text(
                                url == 'about:blank' || url.isEmpty
                                    ? 'Search or enter URL'
                                    : _extractDomain(url),
                                style: TextStyle(
                                  color: url == 'about:blank' || url.isEmpty
                                      ? AppTheme.textTertiary
                                      : AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),

                      // Ad block indicator
                      if (browserProvider.adBlockEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(30),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                        ),

                      // Proxy indicator
                      if (browserProvider.proxyEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withAlpha(30),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.vpn_lock_rounded,
                              size: 14,
                              color: AppTheme.success,
                            ),
                          ),
                        ),

                      const SizedBox(width: 6),

                      // Reload / Stop button
                      if (url != 'about:blank' && url.isNotEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            onTap: widget.onMenuPressed,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isLoading
                                    ? Icons.close_rounded
                                    : Icons.refresh_rounded,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // Progress bar
              if (isLoading && progress > 0 && progress < 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        activeTab?.isIncognito == true
                            ? AppTheme.incognitoAccent
                            : AppTheme.accent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
