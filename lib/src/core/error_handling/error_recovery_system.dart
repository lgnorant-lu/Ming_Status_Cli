/*
---------------------------------------------------------------
File name:          error_recovery_system.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.1 - 错误处理和恢复机制
                    实现异常处理、回滚和诊断功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 错误处理和恢复系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 错误恢复策略
enum RecoveryStrategy {
  automatic, // 自动恢复
  interactive, // 交互式恢复
  manual, // 手动恢复
  abort, // 中止操作
}

/// 错误严重程度
enum ErrorSeverity {
  low, // 低级错误，可以继续
  medium, // 中级错误，需要处理
  high, // 高级错误，需要回滚
  critical, // 严重错误，需要中止
}

/// 操作状态
enum OperationStatus {
  pending, // 等待执行
  running, // 正在执行
  completed, // 已完成
  failed, // 已失败
  rolledBack, // 已回滚
}

/// 可恢复的错误
class RecoverableError extends Error {
  RecoverableError({
    required this.message,
    required this.severity,
    required this.strategy,
    this.context = const {},
    this.recoveryActions = const [],
  });
  final String message;
  final ErrorSeverity severity;
  final RecoveryStrategy strategy;
  final Map<String, dynamic> context;
  final List<RecoveryAction> recoveryActions;

  @override
  String toString() => 'RecoverableError: $message';
}

/// 恢复操作
class RecoveryAction {
  const RecoveryAction({
    required this.name,
    required this.description,
    required this.action,
    this.isDestructive = false,
  });
  final String name;
  final String description;
  final Future<bool> Function() action;
  final bool isDestructive;
}

/// 操作快照
class OperationSnapshot {
  OperationSnapshot({
    required this.id,
    required this.operationName,
    required this.timestamp,
    required this.state,
    this.createdFiles = const [],
    this.modifiedFiles = const [],
    this.originalContents = const {},
  });

  factory OperationSnapshot.fromJson(Map<String, dynamic> json) {
    return OperationSnapshot(
      id: json['id'] as String,
      operationName: json['operationName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      state: Map<String, dynamic>.from(json['state'] as Map),
      createdFiles: List<String>.from(json['createdFiles'] as List? ?? []),
      modifiedFiles: List<String>.from(json['modifiedFiles'] as List? ?? []),
      originalContents:
          Map<String, String>.from(json['originalContents'] as Map? ?? {}),
    );
  }
  final String id;
  final String operationName;
  final DateTime timestamp;
  final Map<String, dynamic> state;
  final List<String> createdFiles;
  final List<String> modifiedFiles;
  final Map<String, String> originalContents;

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationName': operationName,
        'timestamp': timestamp.toIso8601String(),
        'state': state,
        'createdFiles': createdFiles,
        'modifiedFiles': modifiedFiles,
        'originalContents': originalContents,
      };
}

/// 错误恢复系统
class ErrorRecoverySystem {
  factory ErrorRecoverySystem() => _instance;
  ErrorRecoverySystem._internal();
  static final ErrorRecoverySystem _instance = ErrorRecoverySystem._internal();

  final List<OperationSnapshot> _snapshots = [];
  final Map<String, OperationStatus> _operationStatus = {};
  // Logger是静态类，不需要实例化

  String? _snapshotDirectory;

  /// 初始化恢复系统
  Future<void> initialize({String? snapshotDirectory}) async {
    _snapshotDirectory = snapshotDirectory ??
        path.join(Directory.systemTemp.path, 'ming_cli_snapshots');

    final dir = Directory(_snapshotDirectory!);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // 加载现有快照
    await _loadSnapshots();

    Logger.info('错误恢复系统已初始化: $_snapshotDirectory');
  }

  /// 创建操作快照
  Future<String> createSnapshot({
    required String operationName,
    required Map<String, dynamic> state,
    List<String> filesToWatch = const [],
  }) async {
    final snapshotId = _generateSnapshotId();
    final timestamp = DateTime.now();

    // 记录文件原始内容
    final originalContents = <String, String>{};
    for (final filePath in filesToWatch) {
      final file = File(filePath);
      if (file.existsSync()) {
        originalContents[filePath] = await file.readAsString();
      }
    }

    final snapshot = OperationSnapshot(
      id: snapshotId,
      operationName: operationName,
      timestamp: timestamp,
      state: state,
      originalContents: originalContents,
    );

    _snapshots.add(snapshot);
    _operationStatus[snapshotId] = OperationStatus.pending;

    // 保存快照到磁盘
    await _saveSnapshot(snapshot);

    Logger.debug('创建操作快照: $operationName ($snapshotId)');
    return snapshotId;
  }

  /// 更新操作状态
  void updateOperationStatus(String snapshotId, OperationStatus status) {
    _operationStatus[snapshotId] = status;
    Logger.debug('更新操作状态: $snapshotId -> $status');
  }

  /// 记录文件创建
  void recordFileCreation(String snapshotId, String filePath) {
    final snapshot = _findSnapshot(snapshotId);
    if (snapshot != null) {
      final updatedSnapshot = OperationSnapshot(
        id: snapshot.id,
        operationName: snapshot.operationName,
        timestamp: snapshot.timestamp,
        state: snapshot.state,
        createdFiles: [...snapshot.createdFiles, filePath],
        modifiedFiles: snapshot.modifiedFiles,
        originalContents: snapshot.originalContents,
      );

      _replaceSnapshot(snapshot, updatedSnapshot);
    }
  }

  /// 记录文件修改
  void recordFileModification(String snapshotId, String filePath) {
    final snapshot = _findSnapshot(snapshotId);
    if (snapshot != null && !snapshot.modifiedFiles.contains(filePath)) {
      final updatedSnapshot = OperationSnapshot(
        id: snapshot.id,
        operationName: snapshot.operationName,
        timestamp: snapshot.timestamp,
        state: snapshot.state,
        createdFiles: snapshot.createdFiles,
        modifiedFiles: [...snapshot.modifiedFiles, filePath],
        originalContents: snapshot.originalContents,
      );

      _replaceSnapshot(snapshot, updatedSnapshot);
    }
  }

  /// 回滚操作
  Future<bool> rollbackOperation(String snapshotId) async {
    final snapshot = _findSnapshot(snapshotId);
    if (snapshot == null) {
      Logger.error('快照不存在: $snapshotId');
      return false;
    }

    try {
      Logger.info('开始回滚操作: ${snapshot.operationName}');

      // 删除创建的文件
      for (final filePath in snapshot.createdFiles) {
        final file = File(filePath);
        if (file.existsSync()) {
          await file.delete();
          Logger.debug('删除文件: $filePath');
        }
      }

      // 恢复修改的文件
      for (final filePath in snapshot.modifiedFiles) {
        final originalContent = snapshot.originalContents[filePath];
        if (originalContent != null) {
          final file = File(filePath);
          await file.writeAsString(originalContent);
          Logger.debug('恢复文件: $filePath');
        }
      }

      _operationStatus[snapshotId] = OperationStatus.rolledBack;
      Logger.info('回滚操作完成: ${snapshot.operationName}');

      return true;
    } catch (e) {
      Logger.error('回滚操作失败: $e');
      return false;
    }
  }

  /// 处理可恢复错误
  Future<bool> handleRecoverableError(RecoverableError error) async {
    Logger.error('处理可恢复错误: ${error.message}');

    switch (error.strategy) {
      case RecoveryStrategy.automatic:
        return _attemptAutomaticRecovery(error);

      case RecoveryStrategy.interactive:
        return _attemptInteractiveRecovery(error);

      case RecoveryStrategy.manual:
        _displayManualRecoveryInstructions(error);
        return false;

      case RecoveryStrategy.abort:
        Logger.error('操作已中止: ${error.message}');
        return false;
    }
  }

  /// 自动恢复
  Future<bool> _attemptAutomaticRecovery(RecoverableError error) async {
    for (final action in error.recoveryActions) {
      try {
        Logger.info('尝试自动恢复: ${action.name}');
        final success = await action.action();
        if (success) {
          Logger.info('自动恢复成功: ${action.name}');
          return true;
        }
      } catch (e) {
        Logger.warning('自动恢复失败: ${action.name} - $e');
      }
    }

    Logger.error('所有自动恢复尝试都失败了');
    return false;
  }

  /// 交互式恢复
  Future<bool> _attemptInteractiveRecovery(RecoverableError error) async {
    print('\n🔧 检测到可恢复的错误:');
    print('   ${error.message}');
    print('\n可用的恢复选项:');

    for (var i = 0; i < error.recoveryActions.length; i++) {
      final action = error.recoveryActions[i];
      final warning = action.isDestructive ? ' ⚠️' : '';
      print('   ${i + 1}. ${action.description}$warning');
    }
    print('   ${error.recoveryActions.length + 1}. 跳过恢复');

    stdout.write('\n选择恢复方式 (1-${error.recoveryActions.length + 1}): ');
    final input = stdin.readLineSync();

    if (input == null) return false;

    final choice = int.tryParse(input);
    if (choice == null ||
        choice < 1 ||
        choice > error.recoveryActions.length + 1) {
      print('无效选择');
      return false;
    }

    if (choice == error.recoveryActions.length + 1) {
      print('跳过恢复');
      return false;
    }

    final selectedAction = error.recoveryActions[choice - 1];

    if (selectedAction.isDestructive) {
      stdout.write('此操作不可撤销，确定继续吗？ (y/N): ');
      final confirm = stdin.readLineSync()?.toLowerCase();
      if (confirm != 'y' && confirm != 'yes') {
        print('已取消');
        return false;
      }
    }

    try {
      print('正在执行: ${selectedAction.name}...');
      final success = await selectedAction.action();
      if (success) {
        print('✅ 恢复成功');
        return true;
      } else {
        print('❌ 恢复失败');
        return false;
      }
    } catch (e) {
      print('❌ 恢复过程中发生错误: $e');
      return false;
    }
  }

  /// 显示手动恢复说明
  void _displayManualRecoveryInstructions(RecoverableError error) {
    print('\n📋 手动恢复说明:');
    print('   错误: ${error.message}');
    print('\n建议的恢复步骤:');

    for (var i = 0; i < error.recoveryActions.length; i++) {
      final action = error.recoveryActions[i];
      print('   ${i + 1}. ${action.description}');
    }

    if (error.context.isNotEmpty) {
      print('\n上下文信息:');
      error.context.forEach((key, value) {
        print('   $key: $value');
      });
    }
  }

  /// 清理过期快照
  Future<void> cleanupOldSnapshots({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    final toRemove = <OperationSnapshot>[];

    for (final snapshot in _snapshots) {
      if (snapshot.timestamp.isBefore(cutoffTime)) {
        toRemove.add(snapshot);
      }
    }

    for (final snapshot in toRemove) {
      _snapshots.remove(snapshot);
      _operationStatus.remove(snapshot.id);

      // 删除磁盘上的快照文件
      final snapshotFile =
          File(path.join(_snapshotDirectory!, '${snapshot.id}.json'));
      if (snapshotFile.existsSync()) {
        await snapshotFile.delete();
      }
    }

    if (toRemove.isNotEmpty) {
      Logger.info('清理了 ${toRemove.length} 个过期快照');
    }
  }

  /// 获取操作历史
  List<OperationSnapshot> getOperationHistory() {
    return List.unmodifiable(_snapshots);
  }

  /// 生成快照ID
  String _generateSnapshotId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'snapshot_${timestamp}_$random';
  }

  /// 查找快照
  OperationSnapshot? _findSnapshot(String id) {
    try {
      return _snapshots.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 替换快照
  void _replaceSnapshot(OperationSnapshot old, OperationSnapshot updated) {
    final index = _snapshots.indexOf(old);
    if (index != -1) {
      _snapshots[index] = updated;
      _saveSnapshot(updated); // 异步保存，不等待
    }
  }

  /// 保存快照到磁盘
  Future<void> _saveSnapshot(OperationSnapshot snapshot) async {
    if (_snapshotDirectory == null) return;

    final snapshotFile =
        File(path.join(_snapshotDirectory!, '${snapshot.id}.json'));
    await snapshotFile.writeAsString(jsonEncode(snapshot.toJson()));
  }

  /// 加载快照
  Future<void> _loadSnapshots() async {
    if (_snapshotDirectory == null) return;

    final dir = Directory(_snapshotDirectory!);
    if (!dir.existsSync()) return;

    final files =
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final snapshot = OperationSnapshot.fromJson(json);
        _snapshots.add(snapshot);
        _operationStatus[snapshot.id] = OperationStatus.completed; // 假设已完成
      } catch (e) {
        Logger.warning('无法加载快照文件: ${file.path} - $e');
      }
    }

    if (_snapshots.isNotEmpty) {
      Logger.info('加载了 ${_snapshots.length} 个历史快照');
    }
  }
}
