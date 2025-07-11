/*
---------------------------------------------------------------
File name:          security_validator.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.2 - 安全验证系统
                    实现输入验证、路径安全和权限检查
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 安全验证系统;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 安全验证结果
enum SecurityValidationResult {
  safe, // 安全
  warning, // 警告
  dangerous, // 危险
  blocked, // 阻止
}

/// 安全验证错误
class SecurityValidationError extends Error {
  SecurityValidationError({
    required this.message,
    required this.result,
    this.details,
    this.suggestions = const [],
  });

  /// 错误消息
  final String message;

  /// 验证结果
  final SecurityValidationResult result;

  /// 详细信息
  final String? details;

  /// 建议
  final List<String> suggestions;

  @override
  String toString() => 'SecurityValidationError: $message';
}

/// 路径安全验证器
class PathSecurityValidator {
  /// 危险路径模式
  static final List<RegExp> _dangerousPatterns = [
    RegExp(r'\.\.[\\/]'), // 路径遍历
    RegExp('[<>"|?*]'), // Windows非法字符（移除冒号和斜杠检查）
    RegExp(r'[\x00-\x1f]'), // 控制字符
    RegExp(r'^\s+|\s+$'), // 前后空格
  ];

  /// 系统敏感目录
  static final List<String> _systemDirectories = [
    '/etc',
    '/bin',
    '/sbin',
    '/usr/bin',
    '/usr/sbin',
    '/System',
    '/Windows',
    '/Program Files',
    '/Program Files (x86)',
  ];

  /// 验证路径安全性
  static SecurityValidationResult validatePath(String inputPath) {
    // 检查空路径
    if (inputPath.trim().isEmpty) {
      throw SecurityValidationError(
        message: '路径不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    // 规范化路径
    final normalizedPath = path.normalize(inputPath);

    // 检查路径遍历攻击
    if (inputPath.contains('..')) {
      throw SecurityValidationError(
        message: '检测到路径遍历攻击',
        result: SecurityValidationResult.dangerous,
        details: '路径包含 ".." 模式',
        suggestions: [
          '使用相对路径',
          '避免使用 ".." 路径',
          '检查路径格式',
        ],
      );
    }

    // 检查其他危险模式（跳过路径遍历检查）
    for (final pattern in _dangerousPatterns.skip(1)) {
      if (pattern.hasMatch(inputPath)) {
        throw SecurityValidationError(
          message: '检测到危险路径模式',
          result: SecurityValidationResult.dangerous,
          details: '路径包含不安全字符或模式: ${pattern.pattern}',
          suggestions: [
            '使用相对路径',
            '避免使用特殊字符',
            '检查路径格式',
          ],
        );
      }
    }

    // 检查系统目录
    for (final sysDir in _systemDirectories) {
      if (normalizedPath.startsWith(sysDir)) {
        return SecurityValidationResult.warning;
      }
    }

    // 检查路径长度
    if (normalizedPath.length > 260) {
      throw SecurityValidationError(
        message: '路径过长',
        result: SecurityValidationResult.blocked,
        details: '路径长度超过260字符限制',
        suggestions: ['缩短路径长度', '使用更短的目录名'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 验证文件名安全性
  static SecurityValidationResult validateFileName(String fileName) {
    // 检查空文件名
    if (fileName.trim().isEmpty) {
      throw SecurityValidationError(
        message: '文件名不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    // 检查保留名称
    final reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    ];

    final upperFileName = fileName.toUpperCase();
    for (final reserved in reservedNames) {
      if (upperFileName == reserved || upperFileName.startsWith('$reserved.')) {
        throw SecurityValidationError(
          message: '文件名使用了系统保留名称',
          result: SecurityValidationResult.blocked,
          details: '文件名 "$fileName" 是系统保留名称',
          suggestions: ['使用不同的文件名', '添加前缀或后缀'],
        );
      }
    }

    // 检查非法字符
    final illegalChars = RegExp(r'[<>:"|?*\\/]');
    if (illegalChars.hasMatch(fileName)) {
      throw SecurityValidationError(
        message: '文件名包含非法字符',
        result: SecurityValidationResult.blocked,
        details: r'文件名包含以下非法字符: < > : " | ? * \ /',
        suggestions: ['移除或替换非法字符', '使用字母、数字和下划线'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 检查路径是否在允许的目录内
  static bool isPathWithinAllowedDirectory(
    String targetPath,
    String allowedDir,
  ) {
    try {
      final normalizedTarget = path.normalize(path.absolute(targetPath));
      final normalizedAllowed = path.normalize(path.absolute(allowedDir));

      return normalizedTarget.startsWith(normalizedAllowed);
    } catch (e) {
      return false;
    }
  }
}

/// 输入验证器
class InputValidator {
  /// 验证项目名称
  static SecurityValidationResult validateProjectName(String name) {
    // 检查空名称
    if (name.trim().isEmpty) {
      throw SecurityValidationError(
        message: '项目名称不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    // 检查长度
    if (name.length > 100) {
      throw SecurityValidationError(
        message: '项目名称过长',
        result: SecurityValidationResult.blocked,
        details: '项目名称不能超过100个字符',
        suggestions: ['缩短项目名称'],
      );
    }

    // 检查格式
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(name)) {
      throw SecurityValidationError(
        message: '项目名称格式无效',
        result: SecurityValidationResult.blocked,
        details: '项目名称只能包含字母、数字、下划线和连字符',
        suggestions: ['使用字母、数字、下划线和连字符', '避免使用特殊字符和空格'],
      );
    }

    // 检查开头字符
    if (!RegExp('^[a-zA-Z]').hasMatch(name)) {
      throw SecurityValidationError(
        message: '项目名称必须以字母开头',
        result: SecurityValidationResult.blocked,
        suggestions: ['以字母开头'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 验证模板名称
  static SecurityValidationResult validateTemplateName(String name) {
    // 基本验证
    if (name.trim().isEmpty) {
      throw SecurityValidationError(
        message: '模板名称不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    // 检查格式
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(name)) {
      throw SecurityValidationError(
        message: '模板名称格式无效',
        result: SecurityValidationResult.blocked,
        details: '模板名称只能包含字母、数字、下划线和连字符',
        suggestions: ['使用字母、数字、下划线和连字符'],
      );
    }

    return SecurityValidationResult.safe;
  }

  /// 验证配置值
  static SecurityValidationResult validateConfigValue(
    String key,
    String value,
  ) {
    // 检查键名
    if (key.trim().isEmpty) {
      throw SecurityValidationError(
        message: '配置键名不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    // 检查值长度
    if (value.length > 1000) {
      throw SecurityValidationError(
        message: '配置值过长',
        result: SecurityValidationResult.blocked,
        details: '配置值不能超过1000个字符',
        suggestions: ['缩短配置值'],
      );
    }

    // 检查敏感信息
    final sensitivePatterns = [
      RegExp('password', caseSensitive: false),
      RegExp('secret', caseSensitive: false),
      RegExp('token', caseSensitive: false),
      RegExp('key', caseSensitive: false),
    ];

    for (final pattern in sensitivePatterns) {
      if (pattern.hasMatch(key) && value.isNotEmpty) {
        return SecurityValidationResult.warning;
      }
    }

    return SecurityValidationResult.safe;
  }

  /// 验证URL
  static SecurityValidationResult validateUrl(String url) {
    if (url.trim().isEmpty) {
      throw SecurityValidationError(
        message: 'URL不能为空',
        result: SecurityValidationResult.blocked,
      );
    }

    try {
      final uri = Uri.parse(url);

      // 检查协议
      if (!['http', 'https', 'file'].contains(uri.scheme)) {
        throw SecurityValidationError(
          message: '不支持的URL协议',
          result: SecurityValidationResult.blocked,
          details: '只支持 http、https 和 file 协议',
          suggestions: ['使用支持的协议'],
        );
      }

      // 检查本地文件访问
      if (uri.scheme == 'file') {
        return SecurityValidationResult.warning;
      }

      return SecurityValidationResult.safe;
    } catch (e) {
      throw SecurityValidationError(
        message: 'URL格式无效',
        result: SecurityValidationResult.blocked,
        details: e.toString(),
        suggestions: ['检查URL格式', '确保URL完整'],
      );
    }
  }
}

/// 权限验证器
class PermissionValidator {
  /// 检查文件读权限
  static Future<SecurityValidationResult> checkReadPermission(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw SecurityValidationError(
          message: '文件不存在',
          result: SecurityValidationResult.blocked,
          details: '无法访问文件: $filePath',
          suggestions: ['检查文件路径', '确认文件存在'],
        );
      }

      // 尝试读取文件
      await file.readAsString();
      return SecurityValidationResult.safe;
    } catch (e) {
      if (e is SecurityValidationError) rethrow;

      throw SecurityValidationError(
        message: '文件读取权限不足',
        result: SecurityValidationResult.blocked,
        details: e.toString(),
        suggestions: ['检查文件权限', '使用管理员权限运行'],
      );
    }
  }

  /// 检查文件写权限
  static Future<SecurityValidationResult> checkWritePermission(
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final dir = Directory(path.dirname(filePath));

      // 确保目录存在
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // 尝试写入测试文件
      final testContent = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await file.writeAsString(testContent);

      // 验证写入内容
      final readContent = await file.readAsString();
      if (readContent != testContent) {
        throw SecurityValidationError(
          message: '文件写入验证失败',
          result: SecurityValidationResult.blocked,
        );
      }

      return SecurityValidationResult.safe;
    } catch (e) {
      if (e is SecurityValidationError) rethrow;

      throw SecurityValidationError(
        message: '文件写入权限不足',
        result: SecurityValidationResult.blocked,
        details: e.toString(),
        suggestions: ['检查目录权限', '确保磁盘空间充足', '使用管理员权限运行'],
      );
    }
  }

  /// 检查目录权限
  static Future<SecurityValidationResult> checkDirectoryPermission(
    String dirPath,
  ) async {
    try {
      final dir = Directory(dirPath);

      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // 测试创建临时文件
      final testFile = File(path.join(dirPath, '.ming_permission_test'));
      await testFile.writeAsString('test');
      await testFile.delete();

      return SecurityValidationResult.safe;
    } catch (e) {
      throw SecurityValidationError(
        message: '目录权限不足',
        result: SecurityValidationResult.blocked,
        details: e.toString(),
        suggestions: ['检查目录权限', '使用管理员权限运行'],
      );
    }
  }
}

/// 安全验证器主类
class SecurityValidator {
  /// 验证所有输入
  static Future<Map<String, SecurityValidationResult>> validateAll({
    String? projectName,
    String? templateName,
    String? targetPath,
    Map<String, String>? configValues,
    String? url,
  }) async {
    final results = <String, SecurityValidationResult>{};

    try {
      // 验证项目名称
      if (projectName != null) {
        results['projectName'] =
            InputValidator.validateProjectName(projectName);
      }

      // 验证模板名称
      if (templateName != null) {
        results['templateName'] =
            InputValidator.validateTemplateName(templateName);
      }

      // 验证目标路径
      if (targetPath != null) {
        results['targetPath'] = PathSecurityValidator.validatePath(targetPath);
        results['targetPathPermission'] =
            await PermissionValidator.checkDirectoryPermission(targetPath);
      }

      // 验证配置值
      if (configValues != null) {
        for (final entry in configValues.entries) {
          results['config_${entry.key}'] =
              InputValidator.validateConfigValue(entry.key, entry.value);
        }
      }

      // 验证URL
      if (url != null) {
        results['url'] = InputValidator.validateUrl(url);
      }

      Logger.info('安全验证完成: ${results.length}项检查');
      return results;
    } catch (e) {
      Logger.error('安全验证失败: $e');
      rethrow;
    }
  }

  /// 检查是否有危险结果
  static bool hasDangerousResults(
    Map<String, SecurityValidationResult> results,
  ) {
    return results.values.any(
      (result) =>
          result == SecurityValidationResult.dangerous ||
          result == SecurityValidationResult.blocked,
    );
  }

  /// 检查是否有警告结果
  static bool hasWarningResults(Map<String, SecurityValidationResult> results) {
    return results.values
        .any((result) => result == SecurityValidationResult.warning);
  }
}
