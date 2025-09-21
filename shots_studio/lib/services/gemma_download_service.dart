import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum DownloadStatus { idle, downloading, paused, completed, error, cancelled }

class DownloadProgress {
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final String? error;
  final String? filePath;

  const DownloadProgress({
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
    this.error,
    this.filePath,
  });

  DownloadProgress copyWith({
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    DownloadStatus? status,
    String? error,
    String? filePath,
  }) {
    return DownloadProgress(
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error ?? this.error,
      filePath: filePath ?? this.filePath,
    );
  }
}

class GemmaDownloadService extends ChangeNotifier {
  static final GemmaDownloadService _instance =
      GemmaDownloadService._internal();
  factory GemmaDownloadService() => _instance;
  GemmaDownloadService._internal();

  static const String _modelUrl =
      'https://huggingface.co/AnsahMohammad/gemma-shots-studio/resolve/main/gemma-3n-E2B-it-int4.task?download=true';
  static const String _fileName = 'gemma-3n-E2B-it-int4.task';

  // Notification constants
  static const String _notificationChannelId = 'gemma_download_channel';
  static const int _notificationId = 999;

  late final FlutterLocalNotificationsPlugin _notificationsPlugin;

  DownloadProgress _progress = const DownloadProgress(
    progress: 0.0,
    downloadedBytes: 0,
    totalBytes: 0,
    status: DownloadStatus.idle,
  );

  http.Client? _httpClient;
  String? _downloadPath;
  bool _notificationsInitialized = false;
  int _lastNotificationUpdate =
      0; // Track last notification update to avoid spam

  /// Initialize notifications for download progress
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Initialize the plugin
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher_monochrome',
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(initializationSettings);

      // Create notification channel
      final androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        const channel = AndroidNotificationChannel(
          _notificationChannelId,
          'Gemma Model Downloads',
          description: 'Shows progress for Gemma model downloads',
          importance: Importance.low,
          enableVibration: false,
          playSound: false,
          showBadge: false,
        );

        await androidImplementation.createNotificationChannel(channel);
      }

      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize download notifications: $e');
    }
  }

  /// Show or update download progress notification
  void _updateNotification({
    required String title,
    required String content,
    bool showProgress = false,
    int? progress,
    int? maxProgress,
    bool ongoing = false,
  }) {
    if (!_notificationsInitialized) return;

    try {
      // Use a slight delay to prevent notification spam
      Future.delayed(const Duration(milliseconds: 100), () {
        _notificationsPlugin.show(
          _notificationId,
          title,
          content,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannelId,
              'Gemma Model Downloads',
              channelDescription: 'Shows progress for Gemma model downloads',
              icon: '@mipmap/ic_launcher_monochrome',
              ongoing: ongoing,
              showProgress: showProgress,
              maxProgress: maxProgress ?? 100,
              progress: progress ?? 0,
              importance: Importance.low,
              priority: Priority.low,
              playSound: false,
              enableVibration: false,
              autoCancel: !ongoing, // Allow auto-cancel when not ongoing
              category: AndroidNotificationCategory.progress,
              onlyAlertOnce: true, // Only alert on first show, not updates
            ),
          ),
        );
      });
    } catch (e) {
      debugPrint('Failed to update download notification: $e');
    }
  }

  /// Clear download notification
  Future<void> _clearNotification() async {
    if (!_notificationsInitialized) return;

    try {
      await _notificationsPlugin.cancel(_notificationId);
    } catch (e) {
      debugPrint('Failed to clear download notification: $e');
    }
  }

  DownloadProgress get progress => _progress;
  bool get isDownloading => _progress.status == DownloadStatus.downloading;
  bool get isPaused => _progress.status == DownloadStatus.paused;
  bool get isCompleted => _progress.status == DownloadStatus.completed;
  bool get hasError => _progress.status == DownloadStatus.error;

  Future<bool> startDownload(String downloadLocation) async {
    if (isDownloading) {
      return false;
    }

    // Initialize notifications
    await _initializeNotifications();

    // Reset notification tracking
    _lastNotificationUpdate = 0;

    _downloadPath = '$downloadLocation/$_fileName';

    // Save download state for recovery
    await _saveDownloadState(DownloadStatus.downloading, _downloadPath!);

    _updateProgress(
      _progress.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        error: null,
        filePath: _downloadPath,
      ),
    );

    // Show initial notification
    _updateNotification(
      title: 'Downloading Gemma Model',
      content: 'Starting download...',
      showProgress: true,
      progress: 0,
      maxProgress: 100,
      ongoing: true,
    );

    try {
      final file = File(_downloadPath!);
      final resumeFromByte = await file.exists() ? await file.length() : 0;

      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(_modelUrl));

      if (resumeFromByte > 0) {
        request.headers['Range'] = 'bytes=$resumeFromByte-';
      }

      final response = await _httpClient!.send(request);

      if (response.statusCode == 200 || response.statusCode == 206) {
        final totalBytes = (response.contentLength ?? 0) + resumeFromByte;
        var downloadedBytes = resumeFromByte;

        // Save total bytes for recovery
        await _saveDownloadProgress(downloadedBytes, totalBytes);

        _updateProgress(
          _progress.copyWith(
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            progress: totalBytes > 0 ? downloadedBytes / totalBytes : 0.0,
          ),
        );

        // Update notification with total size info
        final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
        final currentMB = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
        final initialProgress = (downloadedBytes * 100 / totalBytes).round();

        _updateNotification(
          title: 'Downloading Gemma Model',
          content:
              'Downloaded: ${currentMB}MB / ${totalMB}MB ($initialProgress%)',
          showProgress: true,
          progress: initialProgress,
          maxProgress: 100,
          ongoing: true,
        );

        _lastNotificationUpdate = downloadedBytes;

        final sink = file.openWrite(mode: FileMode.append);

        await for (final chunk in response.stream) {
          if (_progress.status == DownloadStatus.paused ||
              _progress.status == DownloadStatus.cancelled) {
            break;
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;

          _updateProgress(
            _progress.copyWith(
              downloadedBytes: downloadedBytes,
              progress: totalBytes > 0 ? downloadedBytes / totalBytes : 0.0,
            ),
          );

          // Update notification progress every 5MB or significant progress change
          final currentProgress = (downloadedBytes * 100 / totalBytes).round();
          final lastProgress =
              (_lastNotificationUpdate * 100 / totalBytes).round();

          if (downloadedBytes - _lastNotificationUpdate >=
                  (5 * 1024 * 1024) || // Every 5MB
              currentProgress - lastProgress >= 5 || // Every 5% change
              downloadedBytes == totalBytes) {
            // At completion

            final currentMB = (downloadedBytes / (1024 * 1024)).toStringAsFixed(
              1,
            );
            _updateNotification(
              title: 'Downloading Gemma Model',
              content:
                  'Downloaded: ${currentMB}MB / ${totalMB}MB ($currentProgress%)',
              showProgress: true,
              progress: currentProgress,
              maxProgress: 100,
              ongoing: true,
            );

            _lastNotificationUpdate = downloadedBytes;

            // Save progress for recovery every 5MB
            await _saveDownloadProgress(downloadedBytes, totalBytes);
          } else if (downloadedBytes % (1024 * 1024) == 0) {
            // Still save progress every MB for recovery, just don't update notification
            await _saveDownloadProgress(downloadedBytes, totalBytes);
          }
        }

        await sink.close();

        if (downloadedBytes >= totalBytes &&
            _progress.status == DownloadStatus.downloading) {
          // Download completed successfully
          await _saveModelPath(_downloadPath!);
          await _clearDownloadState(); // Clear recovery state

          _updateProgress(
            _progress.copyWith(status: DownloadStatus.completed, progress: 1.0),
          );

          // Show completion notification
          _updateNotification(
            title: 'Gemma Model Downloaded',
            content: 'Download completed successfully! Ready to use.',
            showProgress: false,
            ongoing: false,
          );

          AnalyticsService().logFeatureUsed(
            'gemma_model_downloaded_successfully',
          );
          return true;
        }
      } else {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }
    } catch (e) {
      await _saveDownloadState(
        DownloadStatus.error,
        _downloadPath!,
        error: e.toString(),
      );

      _updateProgress(
        _progress.copyWith(status: DownloadStatus.error, error: e.toString()),
      );

      // Show error notification
      _updateNotification(
        title: 'Download Failed',
        content: 'Failed to download Gemma model: ${e.toString()}',
        showProgress: false,
        ongoing: false,
      );

      return false;
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }

    return false;
  }

  /// Resume download from last saved state when app restarts
  Future<void> checkAndResumeDownload() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getString('download_status');
      final path = prefs.getString('download_path');
      final downloadedBytes = prefs.getInt('download_downloaded_bytes') ?? 0;
      final totalBytes = prefs.getInt('download_total_bytes') ?? 0;

      if (status == 'downloading' && path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          // Initialize notifications for recovery
          await _initializeNotifications();

          _downloadPath = path;
          _updateProgress(
            _progress.copyWith(
              status: DownloadStatus.paused, // Show as paused, user can resume
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes,
              progress: totalBytes > 0 ? downloadedBytes / totalBytes : 0.0,
              filePath: path,
            ),
          );

          // Show notification about recoverable download
          if (totalBytes > 0) {
            final currentMB = (downloadedBytes / (1024 * 1024)).toStringAsFixed(
              1,
            );
            final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            _updateNotification(
              title: 'Download Ready to Resume',
              content:
                  'Gemma model download paused at ${currentMB}MB / ${totalMB}MB',
              showProgress: true,
              progress: (downloadedBytes * 100 / totalBytes).round(),
              maxProgress: 100,
              ongoing: false,
            );
          }

          // Notify listeners that there's a resumable download
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to check resumable download: $e');
    }
  }

  void pauseDownload() {
    if (!isDownloading) return;

    _updateProgress(_progress.copyWith(status: DownloadStatus.paused));
    _httpClient?.close();
    _httpClient = null;

    // Update notification to show paused state
    _updateNotification(
      title: 'Download Paused',
      content: 'Gemma model download has been paused.',
      showProgress: false,
      ongoing: false,
    );
  }

  Future<bool> resumeDownload() async {
    if (_progress.status != DownloadStatus.paused || _downloadPath == null) {
      return false;
    }

    final downloadLocation = File(_downloadPath!).parent.path;
    return await startDownload(downloadLocation);
  }

  void cancelDownload() {
    _updateProgress(
      _progress.copyWith(
        status: DownloadStatus.cancelled,
        progress: 0.0,
        error: null,
      ),
    );

    _httpClient?.close();
    _httpClient = null;

    // Clear download state
    _clearDownloadState();

    // Clear notification
    _clearNotification();

    // Delete partial file if exists
    if (_downloadPath != null) {
      final file = File(_downloadPath!);
      file.exists().then((exists) {
        if (exists) {
          file.delete();
        }
      });
    }

    _downloadPath = null;
  }

  void resetDownload() {
    cancelDownload();
    _updateProgress(
      const DownloadProgress(
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        status: DownloadStatus.idle,
      ),
    );
  }

  /// Save download state for recovery after app restart
  Future<void> _saveDownloadState(
    DownloadStatus status,
    String path, {
    String? error,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('download_status', status.toString());
      await prefs.setString('download_path', path);
      if (error != null) {
        await prefs.setString('download_error', error);
      }
    } catch (e) {
      debugPrint('Failed to save download state: $e');
    }
  }

  /// Save download progress for recovery
  Future<void> _saveDownloadProgress(
    int downloadedBytes,
    int totalBytes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('download_downloaded_bytes', downloadedBytes);
      await prefs.setInt('download_total_bytes', totalBytes);
    } catch (e) {
      debugPrint('Failed to save download progress: $e');
    }
  }

  /// Clear download recovery state
  Future<void> _clearDownloadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('download_status');
      await prefs.remove('download_path');
      await prefs.remove('download_error');
      await prefs.remove('download_downloaded_bytes');
      await prefs.remove('download_total_bytes');
    } catch (e) {
      debugPrint('Failed to clear download state: $e');
    }
  }

  Future<void> _saveModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemma_model_path', path);
  }

  void _updateProgress(DownloadProgress newProgress) {
    _progress = newProgress;
    notifyListeners();
  }

  @override
  void dispose() {
    _httpClient?.close();
    _clearNotification(); // Clear any active notifications
    super.dispose();
  }
}
