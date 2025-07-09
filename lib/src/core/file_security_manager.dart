/*
---------------------------------------------------------------
File name:          file_security_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.2 - 文件安全管理器
                    实现文件操作安全、权限管理和沙箱机制
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 文件安全管理器;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ming_status_cli/src/core/security_validator.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 文件操作类型
enum FileOperationType {
  read,           // 读取
  write,          // 写入
  create,         // 创建
  delete,         // 删除
  move,           // 移动
  copy,           // 复制
}

/// 文件安全策略
class FileSecurityPolicy {

  const FileSecurityPolicy({
    this.allowedExtensions = const {'.dart', '.yaml', '.yml', '.json', '.md', '.txt'},
    this.blockedExtensions = const {'.exe', '.bat', '.cmd', '.sh', '.ps1'},
    this.maxFileSize = 10 * 1024 * 1024, // 10MB
    this.allowedDirectories = const {},
    this.blockedDirectories = const {},
    this.allowDirectoryCreation = true,
    this.allowFileDeletion = false,
  });
  /// 允许的文件扩展名
  final Set<String> allowedExtensions;
  
  /// 禁止的文件扩展名
  final Set<String> blockedExtensions;
  
  /// 最大文件大小（字节）
  final int maxFileSize;
  
  /// 允许的目录
  final Set<String> allowedDirectories;
  
  /// 禁止的目录
  final Set<String> blockedDirectories;
  
  /// 是否允许创建目录
  final bool allowDirectoryCreation;
  
  /// 是否允许删除文件
  final bool allowFileDeletion;

  /// 默认策略
  static const FileSecurityPolicy defaultPolicy = FileSecurityPolicy();

  /// 严格策略
  static const FileSecurityPolicy strictPolicy = FileSecurityPolicy(
    allowedExtensions: {'.dart', '.yaml', '.yml', '.json'},
    maxFileSize: 1024 * 1024, // 1MB
    allowDirectoryCreation: false,
  );

  /// 宽松策略
  static const FileSecurityPolicy permissivePolicy = FileSecurityPolicy(
    allowedExtensions: {},
    blockedExtensions: {'.exe', '.bat', '.cmd'},
    maxFileSize: 50 * 1024 * 1024, // 50MB
    allowFileDeletion: true,
  );
}

/// 文件操作记录
class FileOperationRecord {

  const FileOperationRecord({
    required this.type,
    required this.filePath,
    required this.timestamp,
    required this.success,
    this.error,
    this.fileSize,
    this.fileHash,
  });
  /// 操作类型
  final FileOperationType type;
  
  /// 文件路径
  final String filePath;
  
  /// 操作时间
  final DateTime timestamp;
  
  /// 操作结果
  final bool success;
  
  /// 错误信息
  final String? error;
  
  /// 文件大小
  final int? fileSize;
  
  /// 文件哈希
  final String? fileHash;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'filePath': filePath,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'error': error,
    'fileSize': fileSize,
    'fileHash': fileHash,
  };
}

/// 文件安全管理器
class FileSecurityManager {
  factory FileSecurityManager() => _instance;
  FileSecurityManager._internal();
  static final FileSecurityManager _instance = FileSecurityManager._internal();

  /// 当前安全策略
  FileSecurityPolicy _policy = FileSecurityPolicy.defaultPolicy;
  
  /// 操作记录
  final List<FileOperationRecord> _operationLog = [];
  
  /// 沙箱根目录
  String? _sandboxRoot;

  /// 设置安全策略
  void setPolicy(FileSecurityPolicy policy) {
    _policy = policy;
    Logger.info('文件安全策略已更新');
  }

  /// 设置沙箱根目录
  void setSandboxRoot(String rootPath) {
    _sandboxRoot = path.normalize(path.absolute(rootPath));
    Logger.info('沙箱根目录设置为: $_sandboxRoot');
  }

  /// 验证文件路径安全性
  SecurityValidationResult _validateFilePath(String filePath, FileOperationType operation) {
    // 基本路径验证
    PathSecurityValidator.validatePath(filePath);
    
    final normalizedPath = path.normalize(path.absolute(filePath));
    
    // 沙箱检查
    if (_sandboxRoot != null) {
      if (!normalizedPath.startsWith(_sandboxRoot!)) {
        throw SecurityValidationError(
          message: '文件路径超出沙箱范围',
          result: SecurityValidationResult.blocked,
          details: '文件路径 $normalizedPath 不在沙箱 $_sandboxRoot 内',
          suggestions: ['使用沙箱内的路径'],
        );
      }
    }

    // 检查允许的目录
    if (_policy.allowedDirectories.isNotEmpty) {
      final isInAllowedDir = _policy.allowedDirectories.any((allowedDir) =>
          normalizedPath.startsWith(path.normalize(path.absolute(allowedDir))),);
      
      if (!isInAllowedDir) {
        throw SecurityValidationError(
          message: '文件路径不在允许的目录内',
          result: SecurityValidationResult.blocked,
          suggestions: ['使用允许的目录'],
        );
      }
    }

    // 检查禁止的目录
    for (final blockedDir in _policy.blockedDirectories) {
      if (normalizedPath.startsWith(path.normalize(path.absolute(blockedDir)))) {
        throw SecurityValidationError(
          message: '文件路径在禁止的目录内',
          result: SecurityValidationResult.blocked,
          details: '路径 $normalizedPath 在禁止目录 $blockedDir 内',
          suggestions: ['使用其他目录'],
        );
      }
    }

    return SecurityValidationResult.safe;
  }

  /// 验证文件扩展名
  SecurityValidationResult _validateFileExtension(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    // 检查禁止的扩展名
    if (_policy.blockedExtensions.contains(extension)) {
      throw SecurityValidationError(
        message: '文件扩展名被禁止',
        result: SecurityValidationResult.blocked,
        details: '扩展名 $extension 在禁止列表中',
        suggestions: ['使用允许的文件类型'],
      );
    }

    // 检查允许的扩展名
    if (_policy.allowedExtensions.isNotEmpty && !_policy.allowedExtensions.contains(extension)) {
      throw SecurityValidationError(
        message: '文件扩展名不被允许',
        result: SecurityValidationResult.blocked,
        details: '扩展名 $extension 不在允许列表中',
        suggestions: ['使用允许的文件类型: ${_policy.allowedExtensions.join(', ')}'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 验证文件大小
  SecurityValidationResult _validateFileSize(int fileSize) {
    if (fileSize > _policy.maxFileSize) {
      throw SecurityValidationError(
        message: '文件大小超过限制',
        result: SecurityValidationResult.blocked,
        details: '文件大小 ${_formatFileSize(fileSize)} 超过限制 ${_formatFileSize(_policy.maxFileSize)}',
        suggestions: ['减小文件大小', '分割文件'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 计算文件哈希
  Future<String> _calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      Logger.warning('无法计算文件哈希: $e');
      return '';
    }
  }

  /// 记录文件操作
  void _recordOperation(FileOperationRecord record) {
    _operationLog.add(record);
    
    // 限制日志大小
    if (_operationLog.length > 1000) {
      _operationLog.removeRange(0, _operationLog.length - 1000);
    }
  }

  /// 安全读取文件
  Future<String> secureReadFile(String filePath) async {
    try {
      // 验证路径和扩展名
      _validateFilePath(filePath, FileOperationType.read);
      _validateFileExtension(filePath);

      // 检查权限
      await PermissionValidator.checkReadPermission(filePath);

      // 读取文件
      final file = File(filePath);
      final content = await file.readAsString();
      
      // 验证文件大小
      final fileSize = await file.length();
      _validateFileSize(fileSize);

      // 计算哈希
      final fileHash = await _calculateFileHash(filePath);

      // 记录操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.read,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: true,
        fileSize: fileSize,
        fileHash: fileHash,
      ),);

      Logger.debug('安全读取文件: $filePath');
      return content;
    } catch (e) {
      // 记录失败操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.read,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      ),);

      Logger.error('文件读取失败: $filePath - $e');
      rethrow;
    }
  }

  /// 安全写入文件
  Future<void> secureWriteFile(String filePath, String content) async {
    try {
      // 验证路径和扩展名
      _validateFilePath(filePath, FileOperationType.write);
      _validateFileExtension(filePath);

      // 验证内容大小
      final contentBytes = utf8.encode(content);
      _validateFileSize(contentBytes.length);

      // 检查权限
      await PermissionValidator.checkWritePermission(filePath);

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(content);

      // 计算哈希
      final fileHash = await _calculateFileHash(filePath);

      // 记录操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.write,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: true,
        fileSize: contentBytes.length,
        fileHash: fileHash,
      ),);

      Logger.debug('安全写入文件: $filePath');
    } catch (e) {
      // 记录失败操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.write,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      ),);

      Logger.error('文件写入失败: $filePath - $e');
      rethrow;
    }
  }

  /// 安全创建目录
  Future<void> secureCreateDirectory(String dirPath) async {
    try {
      if (!_policy.allowDirectoryCreation) {
        throw SecurityValidationError(
          message: '目录创建被禁止',
          result: SecurityValidationResult.blocked,
          suggestions: ['修改安全策略以允许目录创建'],
        );
      }

      // 验证路径
      _validateFilePath(dirPath, FileOperationType.create);

      // 检查权限
      await PermissionValidator.checkDirectoryPermission(dirPath);

      // 创建目录
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // 记录操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.create,
        filePath: dirPath,
        timestamp: DateTime.now(),
        success: true,
      ),);

      Logger.debug('安全创建目录: $dirPath');
    } catch (e) {
      // 记录失败操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.create,
        filePath: dirPath,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      ),);

      Logger.error('目录创建失败: $dirPath - $e');
      rethrow;
    }
  }

  /// 安全删除文件
  Future<void> secureDeleteFile(String filePath) async {
    try {
      if (!_policy.allowFileDeletion) {
        throw SecurityValidationError(
          message: '文件删除被禁止',
          result: SecurityValidationResult.blocked,
          suggestions: ['修改安全策略以允许文件删除'],
        );
      }

      // 验证路径
      _validateFilePath(filePath, FileOperationType.delete);

      // 删除文件
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }

      // 记录操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.delete,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: true,
      ),);

      Logger.debug('安全删除文件: $filePath');
    } catch (e) {
      // 记录失败操作
      _recordOperation(FileOperationRecord(
        type: FileOperationType.delete,
        filePath: filePath,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      ),);

      Logger.error('文件删除失败: $filePath - $e');
      rethrow;
    }
  }

  /// 获取操作日志
  List<FileOperationRecord> getOperationLog({int? limit}) {
    if (limit != null && limit > 0) {
      final startIndex = _operationLog.length > limit ? _operationLog.length - limit : 0;
      return _operationLog.sublist(startIndex);
    }
    return List.unmodifiable(_operationLog);
  }

  /// 清理操作日志
  void clearOperationLog() {
    _operationLog.clear();
    Logger.info('文件操作日志已清理');
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取安全统计信息
  Map<String, dynamic> getSecurityStats() {
    final totalOperations = _operationLog.length;
    final successfulOperations = _operationLog.where((op) => op.success).length;
    final failedOperations = totalOperations - successfulOperations;
    
    final operationsByType = <String, int>{};
    for (final op in _operationLog) {
      operationsByType[op.type.name] = (operationsByType[op.type.name] ?? 0) + 1;
    }

    return {
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'successRate': totalOperations > 0 ? (successfulOperations / totalOperations * 100).toStringAsFixed(1) : '0.0',
      'operationsByType': operationsByType,
      'sandboxRoot': _sandboxRoot,
      'policy': {
        'allowedExtensions': _policy.allowedExtensions.toList(),
        'blockedExtensions': _policy.blockedExtensions.toList(),
        'maxFileSize': _formatFileSize(_policy.maxFileSize),
        'allowDirectoryCreation': _policy.allowDirectoryCreation,
        'allowFileDeletion': _policy.allowFileDeletion,
      },
    };
  }
}
