/*
---------------------------------------------------------------
File name:          update_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        更新管理器 (Update Manager)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 智能搜索和分发系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ming_status_cli/src/core/distribution/dependency_resolver.dart';

/// 更新类型枚举
enum UpdateType {
  /// 主版本更新 (破坏性变更)
  major,

  /// 次版本更新 (新功能)
  minor,

  /// 修订版本更新 (bug修复)
  patch,

  /// 预发布版本更新
  prerelease,
}

/// 更新策略枚举
enum UpdateStrategy {
  /// 自动更新所有
  automatic,

  /// 仅安全更新
  securityOnly,

  /// 手动确认
  manual,

  /// 保守更新 (仅patch)
  conservative,

  /// 激进更新 (包括major)
  aggressive,
}

/// 更新状态枚举
enum UpdateStatus {
  /// 检查中
  checking,

  /// 有可用更新
  available,

  /// 下载中
  downloading,

  /// 安装中
  installing,

  /// 完成
  completed,

  /// 失败
  failed,

  /// 回滚中
  rolling_back,

  /// 已回滚
  rolled_back,
}

/// 更新信息
class UpdateInfo {
  const UpdateInfo({
    required this.templateName,
    required this.currentVersion,
    required this.availableVersion,
    required this.updateType,
    required this.updateSize,
    required this.description,
    required this.changelog,
    required this.isSecurityUpdate,
    required this.compatibility,
    required this.releaseDate,
  });

  /// 模板名称
  final String templateName;

  /// 当前版本
  final Version currentVersion;

  /// 可用版本
  final Version availableVersion;

  /// 更新类型
  final UpdateType updateType;

  /// 更新大小 (字节)
  final int updateSize;

  /// 更新描述
  final String description;

  /// 变更日志
  final List<String> changelog;

  /// 是否为安全更新
  final bool isSecurityUpdate;

  /// 兼容性信息
  final Map<String, bool> compatibility;

  /// 发布时间
  final DateTime releaseDate;

  /// 是否为破坏性更新
  bool get isBreakingChange => updateType == UpdateType.major;

  /// 是否推荐更新
  bool get isRecommended => isSecurityUpdate || updateType == UpdateType.patch;
}

/// 更新进度
class UpdateProgress {
  const UpdateProgress({
    required this.templateName,
    required this.status,
    required this.percentage,
    required this.currentStep,
    required this.startTime,
    this.error,
    this.estimatedRemainingTime,
  });

  /// 模板名称
  final String templateName;

  /// 更新状态
  final UpdateStatus status;

  /// 进度百分比 (0-100)
  final double percentage;

  /// 当前步骤描述
  final String currentStep;

  /// 错误信息
  final String? error;

  /// 开始时间
  final DateTime startTime;

  /// 预计剩余时间 (秒)
  final int? estimatedRemainingTime;

  /// 是否完成
  bool get isCompleted => status == UpdateStatus.completed;

  /// 是否失败
  bool get isFailed => status == UpdateStatus.failed;

  /// 已用时间
  Duration get elapsedTime => DateTime.now().difference(startTime);
}

/// 更新快照
class UpdateSnapshot {
  const UpdateSnapshot({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.templateVersions,
    required this.size,
    required this.description,
  });

  /// 快照ID
  final String id;

  /// 快照名称
  final String name;

  /// 创建时间
  final DateTime createdAt;

  /// 包含的模板版本
  final Map<String, Version> templateVersions;

  /// 快照大小 (字节)
  final int size;

  /// 快照描述
  final String description;
}

/// 更新配置
class UpdateConfig {
  const UpdateConfig({
    this.strategy = UpdateStrategy.manual,
    this.autoCheck = true,
    this.checkInterval = 24,
    this.createSnapshot = true,
    this.maxSnapshots = 5,
    this.verifySignature = true,
    this.backupConfig = true,
    this.notifications = const {
      'available': true,
      'completed': true,
      'failed': true,
    },
  });

  /// 更新策略
  final UpdateStrategy strategy;

  /// 是否启用自动检查
  final bool autoCheck;

  /// 检查间隔 (小时)
  final int checkInterval;

  /// 是否创建快照
  final bool createSnapshot;

  /// 最大快照数量
  final int maxSnapshots;

  /// 是否验证签名
  final bool verifySignature;

  /// 是否备份配置
  final bool backupConfig;

  /// 更新通知设置
  final Map<String, bool> notifications;
}

/// 更新管理器
class UpdateManager {
  /// 构造函数
  UpdateManager({
    UpdateConfig? config,
    DependencyResolver? dependencyResolver,
    String? cacheDir,
    String? snapshotDir,
  })  : _config = config ?? const UpdateConfig(),
        _dependencyResolver = dependencyResolver ?? DependencyResolver(),
        _cacheDir = cacheDir ?? '.ming_cache/updates',
        _snapshotDir = snapshotDir ?? '.ming_cache/snapshots' {
    _initializeDirectories();
    _loadSnapshots();
  }

  /// 更新配置
  final UpdateConfig _config;

  /// 当前更新进度
  final Map<String, StreamController<UpdateProgress>> _updateStreams = {};

  /// 更新快照列表
  final List<UpdateSnapshot> _snapshots = [];

  /// 依赖解析器
  final DependencyResolver _dependencyResolver;

  /// 更新缓存目录
  final String _cacheDir;

  /// 快照目录
  final String _snapshotDir;

  /// 检查可用更新
  Future<List<UpdateInfo>> checkForUpdates({
    List<String>? templateNames,
    bool includePrerelease = false,
  }) async {
    final updates = <UpdateInfo>[];

    // 获取当前安装的模板
    final installedTemplates = await _getInstalledTemplates();
    final templatesToCheck = templateNames ?? installedTemplates.keys.toList();

    for (final templateName in templatesToCheck) {
      final currentVersion = installedTemplates[templateName];
      if (currentVersion == null) continue;

      final availableVersions = await _getAvailableVersions(templateName);
      if (availableVersions.isEmpty) continue;

      // 过滤预发布版本
      final filteredVersions = includePrerelease
          ? availableVersions
          : availableVersions.where((v) => v.preRelease == null).toList();

      if (filteredVersions.isEmpty) continue;

      final latestVersion = filteredVersions.last;
      if (latestVersion.compareTo(currentVersion) > 0) {
        final updateInfo = await _createUpdateInfo(
          templateName,
          currentVersion,
          latestVersion,
        );
        updates.add(updateInfo);
      }
    }

    return updates;
  }

  /// 执行更新
  Future<void> performUpdate(
    String templateName, {
    Version? targetVersion,
    bool dryRun = false,
    void Function(UpdateProgress)? onProgress,
  }) async {
    final controller = StreamController<UpdateProgress>();
    _updateStreams[templateName] = controller;

    try {
      // 创建快照
      if (_config.createSnapshot && !dryRun) {
        await _createSnapshot('Before updating $templateName');
      }

      // 开始更新流程
      await _executeUpdate(templateName, targetVersion, dryRun, controller);
    } catch (e) {
      final errorProgress = UpdateProgress(
        templateName: templateName,
        status: UpdateStatus.failed,
        percentage: 0,
        currentStep: 'Update failed',
        error: e.toString(),
        startTime: DateTime.now(),
      );

      controller.add(errorProgress);
      onProgress?.call(errorProgress);

      rethrow;
    } finally {
      await controller.close();
      _updateStreams.remove(templateName);
    }
  }

  /// 批量更新
  Future<void> performBatchUpdate(
    List<String> templateNames, {
    bool dryRun = false,
    void Function(String, UpdateProgress)? onProgress,
  }) async {
    // 创建批量快照
    if (_config.createSnapshot && !dryRun) {
      await _createSnapshot('Batch update: ${templateNames.join(', ')}');
    }

    // 并行执行更新
    final futures = templateNames.map((templateName) async {
      await performUpdate(
        templateName,
        dryRun: dryRun,
        onProgress: onProgress != null
            ? (progress) => onProgress(templateName, progress)
            : null,
      );
    });

    await Future.wait(futures);
  }

  /// 回滚更新
  Future<void> rollbackUpdate(String snapshotId) async {
    final snapshot = _snapshots.firstWhere(
      (s) => s.id == snapshotId,
      orElse: () => throw Exception('Snapshot not found: $snapshotId'),
    );

    // 执行回滚
    for (final entry in snapshot.templateVersions.entries) {
      final templateName = entry.key;
      final targetVersion = entry.value;

      await _rollbackTemplate(templateName, targetVersion);
    }
  }

  /// 创建快照
  Future<UpdateSnapshot> createSnapshot(String name,
      {String? description}) async {
    return _createSnapshot(description ?? name);
  }

  /// 获取快照列表
  List<UpdateSnapshot> getSnapshots() {
    return List.unmodifiable(_snapshots);
  }

  /// 删除快照
  Future<void> deleteSnapshot(String snapshotId) async {
    final snapshot = _snapshots.firstWhere(
      (s) => s.id == snapshotId,
      orElse: () => throw Exception('Snapshot not found: $snapshotId'),
    );

    _snapshots.remove(snapshot);

    // 删除快照文件
    final snapshotFile = File('$_snapshotDir/${snapshot.id}.json');
    if (await snapshotFile.exists()) {
      await snapshotFile.delete();
    }
  }

  /// 获取更新统计
  Map<String, dynamic> getUpdateStats() {
    return {
      'totalSnapshots': _snapshots.length,
      'activeUpdates': _updateStreams.length,
      'updateStrategy': _config.strategy.name,
      'autoCheckEnabled': _config.autoCheck,
      'lastCheckTime': DateTime.now().toIso8601String(),
    };
  }

  /// 初始化目录
  Future<void> _initializeDirectories() async {
    await Directory(_cacheDir).create(recursive: true);
    await Directory(_snapshotDir).create(recursive: true);
  }

  /// 加载快照
  Future<void> _loadSnapshots() async {
    final snapshotDir = Directory(_snapshotDir);
    if (!await snapshotDir.exists()) return;

    await for (final entity in snapshotDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final snapshot = _snapshotFromJson(json);
          _snapshots.add(snapshot);
        } catch (e) {
          // 忽略损坏的快照文件
        }
      }
    }

    // 按创建时间排序
    _snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取已安装的模板
  Future<Map<String, Version>> _getInstalledTemplates() async {
    // 模拟获取已安装模板
    return {
      'flutter_clean_app': Version.parse('1.0.0'),
      'react_dashboard': Version.parse('2.1.0'),
      'vue_component': Version.parse('1.5.0'),
    };
  }

  /// 获取可用版本
  Future<List<Version>> _getAvailableVersions(String templateName) async {
    // 模拟获取可用版本
    switch (templateName) {
      case 'flutter_clean_app':
        return [
          Version.parse('1.0.0'),
          Version.parse('1.1.0'),
          Version.parse('1.2.0'),
          Version.parse('2.0.0-beta.1'),
        ];
      case 'react_dashboard':
        return [
          Version.parse('2.1.0'),
          Version.parse('2.1.1'),
          Version.parse('2.2.0'),
        ];
      case 'vue_component':
        return [
          Version.parse('1.5.0'),
          Version.parse('1.5.1'),
          Version.parse('1.6.0'),
        ];
      default:
        return [];
    }
  }

  /// 创建更新信息
  Future<UpdateInfo> _createUpdateInfo(
    String templateName,
    Version currentVersion,
    Version availableVersion,
  ) async {
    final updateType = _determineUpdateType(currentVersion, availableVersion);

    return UpdateInfo(
      templateName: templateName,
      currentVersion: currentVersion,
      availableVersion: availableVersion,
      updateType: updateType,
      updateSize: 1024 * 1024 * 5, // 5MB
      description: 'Update to version $availableVersion',
      changelog: [
        'Bug fixes and improvements',
        'Performance optimizations',
        'New features added',
      ],
      isSecurityUpdate: updateType == UpdateType.patch,
      compatibility: {'flutter': true, 'dart': true},
      releaseDate: DateTime.now().subtract(const Duration(days: 7)),
    );
  }

  /// 确定更新类型
  UpdateType _determineUpdateType(Version current, Version available) {
    if (available.preRelease != null) return UpdateType.prerelease;
    if (available.major > current.major) return UpdateType.major;
    if (available.minor > current.minor) return UpdateType.minor;
    return UpdateType.patch;
  }

  /// 执行更新
  Future<void> _executeUpdate(
    String templateName,
    Version? targetVersion,
    bool dryRun,
    StreamController<UpdateProgress> controller,
  ) async {
    final startTime = DateTime.now();

    // 检查阶段
    controller.add(
      UpdateProgress(
        templateName: templateName,
        status: UpdateStatus.checking,
        percentage: 10,
        currentStep: 'Checking dependencies',
        startTime: startTime,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    // 下载阶段
    controller.add(
      UpdateProgress(
        templateName: templateName,
        status: UpdateStatus.downloading,
        percentage: 30,
        currentStep: 'Downloading update',
        startTime: startTime,
        estimatedRemainingTime: 30,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    // 安装阶段
    controller.add(
      UpdateProgress(
        templateName: templateName,
        status: UpdateStatus.installing,
        percentage: 80,
        currentStep: 'Installing update',
        startTime: startTime,
        estimatedRemainingTime: 10,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    // 完成
    controller.add(
      UpdateProgress(
        templateName: templateName,
        status: UpdateStatus.completed,
        percentage: 100,
        currentStep: 'Update completed',
        startTime: startTime,
      ),
    );
  }

  /// 创建快照
  Future<UpdateSnapshot> _createSnapshot(String description) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final installedTemplates = await _getInstalledTemplates();

    final snapshot = UpdateSnapshot(
      id: id,
      name: 'Snapshot $id',
      createdAt: DateTime.now(),
      templateVersions: installedTemplates,
      size: 1024 * 1024 * 10, // 10MB
      description: description,
    );

    // 保存快照到文件
    final snapshotFile = File('$_snapshotDir/$id.json');
    await snapshotFile.writeAsString(jsonEncode(_snapshotToJson(snapshot)));

    _snapshots.add(snapshot);

    // 清理旧快照
    if (_snapshots.length > _config.maxSnapshots) {
      final oldSnapshot = _snapshots.removeAt(_snapshots.length - 1);
      await deleteSnapshot(oldSnapshot.id);
    }

    return snapshot;
  }

  /// 回滚模板
  Future<void> _rollbackTemplate(
      String templateName, Version targetVersion) async {
    // 模拟回滚操作
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 快照转JSON
  Map<String, dynamic> _snapshotToJson(UpdateSnapshot snapshot) {
    return {
      'id': snapshot.id,
      'name': snapshot.name,
      'createdAt': snapshot.createdAt.toIso8601String(),
      'templateVersions': snapshot.templateVersions.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      'size': snapshot.size,
      'description': snapshot.description,
    };
  }

  /// JSON转快照
  UpdateSnapshot _snapshotFromJson(Map<String, dynamic> json) {
    return UpdateSnapshot(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      templateVersions: (json['templateVersions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Version.parse(value as String)),
      ),
      size: json['size'] as int,
      description: json['description'] as String,
    );
  }

  /// 释放资源
  void dispose() {
    for (final controller in _updateStreams.values) {
      controller.close();
    }
    _updateStreams.clear();
  }
}
