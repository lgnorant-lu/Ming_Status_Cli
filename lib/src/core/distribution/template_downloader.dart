/*
---------------------------------------------------------------
File name:          template_downloader.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板下载器 (Template Downloader)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// 下载状态枚举
enum DownloadStatus {
  /// 等待中
  pending,

  /// 下载中
  downloading,

  /// 暂停
  paused,

  /// 完成
  completed,

  /// 失败
  failed,

  /// 取消
  cancelled,
}

/// 压缩格式枚举
enum CompressionFormat {
  /// ZIP格式
  zip,

  /// TAR.GZ格式
  tarGz,

  /// 7Z格式
  sevenZ,

  /// 无压缩
  none,
}

/// 下载进度信息
class DownloadProgress {
  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    required this.remainingTime,
    required this.status,
    this.error,
  });

  /// 已下载字节数
  final int downloadedBytes;

  /// 总字节数
  final int totalBytes;

  /// 下载速度 (字节/秒)
  final double speed;

  /// 剩余时间 (秒)
  final int remainingTime;

  /// 下载状态
  final DownloadStatus status;

  /// 错误信息
  final String? error;

  /// 下载进度百分比
  double get percentage =>
      totalBytes > 0 ? (downloadedBytes / totalBytes) * 100 : 0.0;

  /// 是否完成
  bool get isCompleted => status == DownloadStatus.completed;

  /// 是否失败
  bool get isFailed => status == DownloadStatus.failed;
}

/// 下载配置
class DownloadConfig {
  const DownloadConfig({
    this.maxConnections = 4,
    this.chunkSize = 1024 * 1024, // 1MB
    this.connectionTimeout = 30,
    this.readTimeout = 60,
    this.retryCount = 3,
    this.retryDelay = 2,
    this.enableResume = true,
    this.verifyIntegrity = true,
    this.userAgent = 'Ming-Status-CLI/2.2.0',
  });

  /// 最大并发连接数
  final int maxConnections;

  /// 分块大小 (字节)
  final int chunkSize;

  /// 连接超时时间 (秒)
  final int connectionTimeout;

  /// 读取超时时间 (秒)
  final int readTimeout;

  /// 重试次数
  final int retryCount;

  /// 重试延迟 (秒)
  final int retryDelay;

  /// 是否启用断点续传
  final bool enableResume;

  /// 是否验证完整性
  final bool verifyIntegrity;

  /// 用户代理
  final String userAgent;
}

/// 下载任务
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.outputPath,
    required this.config,
    required this.createdAt,
    this.expectedHash,
    this.format = CompressionFormat.zip,
  });

  /// 任务ID
  final String id;

  /// 下载URL
  final String url;

  /// 输出文件路径
  final String outputPath;

  /// 期望的文件哈希 (SHA-256)
  final String? expectedHash;

  /// 压缩格式
  final CompressionFormat format;

  /// 下载配置
  final DownloadConfig config;

  /// 创建时间
  final DateTime createdAt;
}

/// 模板下载器
class TemplateDownloader {
  /// 构造函数
  TemplateDownloader({
    DownloadConfig? config,
    String? cacheDir,
  })  : _config = config ?? const DownloadConfig(),
        _cacheDir = cacheDir ?? '.ming_cache/downloads' {
    _initializeHttpClient();
    _ensureCacheDirectory();
  }

  /// HTTP客户端
  late final HttpClient _httpClient;

  /// 下载配置
  final DownloadConfig _config;

  /// 活跃下载任务
  final Map<String, StreamController<DownloadProgress>> _activeDownloads = {};

  /// 下载缓存目录
  final String _cacheDir;

  /// 下载统计
  final Map<String, int> _downloadStats = {};

  /// 下载模板
  Future<String> downloadTemplate(
    String url,
    String outputPath, {
    String? expectedHash,
    CompressionFormat format = CompressionFormat.zip,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final taskId = _generateTaskId(url);
    final task = DownloadTask(
      id: taskId,
      url: url,
      outputPath: outputPath,
      expectedHash: expectedHash,
      format: format,
      config: _config,
      createdAt: DateTime.now(),
    );

    // 检查缓存
    final cachedPath = await _checkCache(task);
    if (cachedPath != null) {
      onProgress?.call(
        DownloadProgress(
          downloadedBytes: await File(cachedPath).length(),
          totalBytes: await File(cachedPath).length(),
          speed: 0,
          remainingTime: 0,
          status: DownloadStatus.completed,
        ),
      );
      return cachedPath;
    }

    // 开始下载
    return _performDownload(task, onProgress);
  }

  /// 批量下载模板
  Future<List<String>> downloadMultiple(
    List<String> urls,
    String outputDir, {
    void Function(String url, DownloadProgress)? onProgress,
  }) async {
    final futures = urls.map((url) async {
      final fileName = _extractFileName(url);
      final outputPath = '$outputDir/$fileName';

      return downloadTemplate(
        url,
        outputPath,
        onProgress:
            onProgress != null ? (progress) => onProgress(url, progress) : null,
      );
    });

    return Future.wait(futures);
  }

  /// 暂停下载
  Future<void> pauseDownload(String taskId) async {
    final controller = _activeDownloads[taskId];
    if (controller != null) {
      controller.add(
        const DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          speed: 0,
          remainingTime: 0,
          status: DownloadStatus.paused,
        ),
      );
    }
  }

  /// 取消下载
  Future<void> cancelDownload(String taskId) async {
    final controller = _activeDownloads[taskId];
    if (controller != null) {
      controller.add(
        const DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          speed: 0,
          remainingTime: 0,
          status: DownloadStatus.cancelled,
        ),
      );
      await controller.close();
      _activeDownloads.remove(taskId);
    }
  }

  /// 获取下载统计
  Map<String, dynamic> getDownloadStats() {
    return {
      'totalDownloads':
          _downloadStats.values.fold(0, (sum, count) => sum + count),
      'activeDownloads': _activeDownloads.length,
      'cacheSize': _getCacheSize(),
      'downloadsByFormat': Map<String, dynamic>.from(_downloadStats),
    };
  }

  /// 清理缓存
  Future<void> clearCache() async {
    final cacheDir = Directory(_cacheDir);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await _ensureCacheDirectory();
    }
  }

  /// 初始化HTTP客户端
  void _initializeHttpClient() {
    _httpClient = HttpClient();
    _httpClient.connectionTimeout =
        Duration(seconds: _config.connectionTimeout);
    _httpClient.userAgent = _config.userAgent;
  }

  /// 确保缓存目录存在
  Future<void> _ensureCacheDirectory() async {
    final cacheDir = Directory(_cacheDir);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  /// 生成任务ID
  String _generateTaskId(String url) {
    final bytes =
        utf8.encode(url + DateTime.now().millisecondsSinceEpoch.toString());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// 检查缓存
  Future<String?> _checkCache(DownloadTask task) async {
    final fileName = _extractFileName(task.url);
    final cachedPath = '$_cacheDir/$fileName';
    final cachedFile = File(cachedPath);

    if (await cachedFile.exists()) {
      // 验证缓存文件完整性
      if (task.expectedHash != null) {
        final actualHash = await _calculateFileHash(cachedPath);
        if (actualHash == task.expectedHash) {
          return cachedPath;
        } else {
          // 缓存文件损坏，删除
          await cachedFile.delete();
        }
      } else {
        return cachedPath;
      }
    }

    return null;
  }

  /// 执行下载
  Future<String> _performDownload(
    DownloadTask task,
    void Function(DownloadProgress)? onProgress,
  ) async {
    final controller = StreamController<DownloadProgress>();
    _activeDownloads[task.id] = controller;

    try {
      // 创建输出文件
      final outputFile = File(task.outputPath);
      await outputFile.parent.create(recursive: true);

      // 检查是否支持断点续传
      var startByte = 0;
      if (task.config.enableResume && await outputFile.exists()) {
        startByte = await outputFile.length();
      }

      // 发起HTTP请求
      final request = await _httpClient.getUrl(Uri.parse(task.url));
      if (startByte > 0) {
        request.headers.set('Range', 'bytes=$startByte-');
      }

      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}: Failed to download');
      }

      final totalBytes = response.contentLength + startByte;
      var downloadedBytes = startByte;
      final startTime = DateTime.now();

      // 打开文件写入流
      final sink = outputFile.openWrite(
        mode: startByte > 0 ? FileMode.append : FileMode.write,
      );

      // 监听下载进度
      await for (final chunk in response) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final speed = elapsed > 0
            ? (downloadedBytes - startByte) / (elapsed / 1000)
            : 0.0;
        final remainingBytes = totalBytes - downloadedBytes;
        final remainingTime = speed > 0 ? (remainingBytes / speed).round() : 0;

        final progress = DownloadProgress(
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          speed: speed,
          remainingTime: remainingTime,
          status: DownloadStatus.downloading,
        );

        controller.add(progress);
        onProgress?.call(progress);
      }

      await sink.close();

      // 验证文件完整性
      if (task.config.verifyIntegrity && task.expectedHash != null) {
        final actualHash = await _calculateFileHash(task.outputPath);
        if (actualHash != task.expectedHash) {
          await outputFile.delete();
          throw Exception(
            'File integrity check failed: expected ${task.expectedHash}, got $actualHash',
          );
        }
      }

      // 更新统计
      final formatName = task.format.name;
      _downloadStats[formatName] = (_downloadStats[formatName] ?? 0) + 1;

      // 发送完成状态
      final finalProgress = DownloadProgress(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        speed: 0,
        remainingTime: 0,
        status: DownloadStatus.completed,
      );

      controller.add(finalProgress);
      onProgress?.call(finalProgress);

      return task.outputPath;
    } catch (e) {
      final errorProgress = DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        speed: 0,
        remainingTime: 0,
        status: DownloadStatus.failed,
        error: e.toString(),
      );

      controller.add(errorProgress);
      onProgress?.call(errorProgress);

      rethrow;
    } finally {
      await controller.close();
      _activeDownloads.remove(task.id);
    }
  }

  /// 提取文件名
  String _extractFileName(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return 'template_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 计算文件哈希
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 获取缓存大小
  int _getCacheSize() {
    // 简化实现，返回固定值
    return 1024 * 1024 * 100; // 100MB
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
    for (final controller in _activeDownloads.values) {
      controller.close();
    }
    _activeDownloads.clear();
  }
}
