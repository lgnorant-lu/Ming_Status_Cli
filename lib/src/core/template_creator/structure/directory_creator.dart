/*
---------------------------------------------------------------
File name:          directory_creator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        目录结构创建器基类 (Directory Structure Creator Base)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:path/path.dart' as path;

/// 目录结构创建器基类
///
/// 定义创建项目目录结构的通用接口和基础功能
abstract class DirectoryCreator {
  /// 创建目录结构创建器实例
  const DirectoryCreator();

  /// 获取目录列表
  ///
  /// 子类需要实现此方法，返回需要创建的目录列表
  List<String> getDirectories(ScaffoldConfig config);

  /// 创建目录结构
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回创建的目录列表
  Future<List<String>> createDirectories(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final directories = getDirectories(config);
    final createdDirectories = <String>[];

    for (final dir in directories) {
      final dirPath = path.join(templatePath, dir);
      final directory = Directory(dirPath);
      
      try {
        await directory.create(recursive: true);
        createdDirectories.add(dirPath);
      } catch (e) {
        throw DirectoryCreationException(
          'Failed to create directory: $dirPath',
          originalException: e,
        );
      }
    }

    return createdDirectories;
  }

  /// 验证目录是否存在
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回验证结果
  Future<DirectoryValidationResult> validateDirectories(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final directories = getDirectories(config);
    final existingDirectories = <String>[];
    final missingDirectories = <String>[];

    for (final dir in directories) {
      final dirPath = path.join(templatePath, dir);
      final directory = Directory(dirPath);
      
      if (await directory.exists()) {
        existingDirectories.add(dirPath);
      } else {
        missingDirectories.add(dirPath);
      }
    }

    return DirectoryValidationResult(
      existingDirectories: existingDirectories,
      missingDirectories: missingDirectories,
    );
  }

  /// 清理目录结构
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// [force] 是否强制删除非空目录
  Future<void> cleanDirectories(
    String templatePath,
    ScaffoldConfig config, {
    bool force = false,
  }) async {
    final directories = getDirectories(config);
    
    // 按深度排序，先删除深层目录
    final sortedDirectories = directories
        .map((dir) => path.join(templatePath, dir))
        .toList()
      ..sort((a, b) => b.split(path.separator).length.compareTo(
          a.split(path.separator).length,),);

    for (final dirPath in sortedDirectories) {
      final directory = Directory(dirPath);
      
      if (await directory.exists()) {
        try {
          if (force) {
            await directory.delete(recursive: true);
          } else {
            // 只删除空目录
            final contents = await directory.list().toList();
            if (contents.isEmpty) {
              await directory.delete();
            }
          }
        } catch (e) {
          // 忽略删除失败的情况
        }
      }
    }
  }

  /// 获取目录统计信息
  ///
  /// [templatePath] 模板根路径
  /// [config] 脚手架配置
  /// 返回目录统计信息
  Future<DirectoryStatistics> getDirectoryStatistics(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final directories = getDirectories(config);
    var totalDirectories = 0;
    var existingDirectories = 0;
    var totalSize = 0;

    for (final dir in directories) {
      final dirPath = path.join(templatePath, dir);
      final directory = Directory(dirPath);
      totalDirectories++;
      
      if (await directory.exists()) {
        existingDirectories++;
        
        try {
          await for (final entity in directory.list(recursive: true)) {
            if (entity is File) {
              final stat = await entity.stat();
              totalSize += stat.size;
            }
          }
        } catch (e) {
          // 忽略统计失败的情况
        }
      }
    }

    return DirectoryStatistics(
      totalDirectories: totalDirectories,
      existingDirectories: existingDirectories,
      missingDirectories: totalDirectories - existingDirectories,
      totalSize: totalSize,
    );
  }
}

/// 目录验证结果
class DirectoryValidationResult {
  /// 创建目录验证结果实例
  const DirectoryValidationResult({
    required this.existingDirectories,
    required this.missingDirectories,
  });

  /// 存在的目录列表
  final List<String> existingDirectories;

  /// 缺失的目录列表
  final List<String> missingDirectories;

  /// 是否所有目录都存在
  bool get isValid => missingDirectories.isEmpty;

  /// 存在的目录数量
  int get existingCount => existingDirectories.length;

  /// 缺失的目录数量
  int get missingCount => missingDirectories.length;

  /// 总目录数量
  int get totalCount => existingCount + missingCount;

  @override
  String toString() {
    return 'DirectoryValidationResult('
        'existing: $existingCount, '
        'missing: $missingCount, '
        'valid: $isValid'
        ')';
  }
}

/// 目录统计信息
class DirectoryStatistics {
  /// 创建目录统计信息实例
  const DirectoryStatistics({
    required this.totalDirectories,
    required this.existingDirectories,
    required this.missingDirectories,
    required this.totalSize,
  });

  /// 总目录数量
  final int totalDirectories;

  /// 存在的目录数量
  final int existingDirectories;

  /// 缺失的目录数量
  final int missingDirectories;

  /// 总大小（字节）
  final int totalSize;

  /// 存在目录的百分比
  double get existingPercentage => 
      totalDirectories > 0 ? (existingDirectories / totalDirectories) * 100 : 0;

  /// 格式化的总大小
  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'DirectoryStatistics('
        'total: $totalDirectories, '
        'existing: $existingDirectories, '
        'missing: $missingDirectories, '
        'size: $formattedSize'
        ')';
  }
}

/// 目录创建异常
class DirectoryCreationException implements Exception {
  /// 创建目录创建异常实例
  const DirectoryCreationException(
    this.message, {
    this.originalException,
  });

  /// 错误消息
  final String message;

  /// 原始异常
  final Object? originalException;

  @override
  String toString() {
    if (originalException != null) {
      return 'DirectoryCreationException: $message\nCaused by: $originalException';
    }
    return 'DirectoryCreationException: $message';
  }
}
