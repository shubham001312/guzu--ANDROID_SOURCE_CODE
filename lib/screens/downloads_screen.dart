import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/download_provider.dart';
import '../models/download_model.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DownloadProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final downloads = downloadProvider.downloads;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Downloads'),
        actions: [
          if (downloads.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
              onSelected: (value) {
                if (value == 'clear') {
                  downloadProvider.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear All'),
                ),
              ],
            ),
        ],
      ),
      body: downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded,
                      size: 64, color: AppTheme.textTertiary.withAlpha(80)),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    'No downloads yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Downloaded files will appear here',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final item = downloads[index];
                return _DownloadTile(
                  item: item,
                  index: index,
                  onCancel: () => downloadProvider.cancelDownload(item.url),
                  onRetry: () => downloadProvider.retryDownload(item.url),
                  onDelete: () {
                    if (item.id != null) downloadProvider.deleteRecord(item.id!);
                  },
                  onOpen: () => _openFile(item.filePath),
                );
              },
            ),
    );
  }

  void _openFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(filePath);
      try {
        await launchUrl(uri);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this file type')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
    }
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;
  final int index;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _DownloadTile({
    required this.item,
    required this.index,
    required this.onCancel,
    required this.onRetry,
    required this.onDelete,
    required this.onOpen,
  });

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.videocam_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audiotrack_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive_rounded;
      case 'apk':
        return Icons.android_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _statusColor() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return AppTheme.accent;
      case DownloadStatus.completed:
        return AppTheme.success;
      case DownloadStatus.failed:
        return AppTheme.error;
      case DownloadStatus.cancelled:
        return AppTheme.warning;
      case DownloadStatus.paused:
        return AppTheme.warning;
      case DownloadStatus.queued:
        return AppTheme.textTertiary;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return '${(item.progressPercent * 100).toStringAsFixed(0)}% · ${item.formattedSize}';
      case DownloadStatus.completed:
        return 'Completed · ${item.formattedSize}';
      case DownloadStatus.failed:
        return 'Failed${item.errorMessage != null ? " · ${item.errorMessage}" : ""}';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.paused:
        return 'Paused · ${(item.progressPercent * 100).toStringAsFixed(0)}%';
      case DownloadStatus.queued:
        return 'Waiting...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 6,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _statusColor().withAlpha(20),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(
          _fileIcon(item.fileName),
          color: _statusColor(),
          size: 22,
        ),
      ),
      title: Text(
        item.fileName,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (item.status == DownloadStatus.downloading)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: item.progressPercent,
                minHeight: 3,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor()),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _statusLabel(),
            style: TextStyle(
              color: _statusColor(),
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: _buildTrailingButton(),
      onTap: item.status == DownloadStatus.completed ? onOpen : null,
    ).animate().fadeIn(duration: 200.ms, delay: (index * 40).ms);
  }

  Widget _buildTrailingButton() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
          onPressed: onCancel,
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.accent),
          onPressed: onRetry,
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.open_in_new_rounded, size: 20, color: AppTheme.success),
          onPressed: onOpen,
        );
      default:
        return const SizedBox(width: 48);
    }
  }
}
