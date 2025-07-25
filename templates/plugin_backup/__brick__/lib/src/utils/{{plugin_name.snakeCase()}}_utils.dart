/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_utils.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件工具类
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件工具类;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../constants/{{plugin_name.snakeCase()}}_constants.dart';
import '../exceptions/{{plugin_name.snakeCase()}}_exceptions.dart';

/// {{plugin_name.titleCase()}}插件工具类
/// 
/// 提供插件开发中常用的工具方法
class {{plugin_name.pascalCase()}}Utils {
  /// 私有构造函数，防止实例化
  {{plugin_name.pascalCase()}}Utils._();

  /// 验证插件名称格式
  /// 
  /// [name] 插件名称
  /// 
  /// 返回是否有效
  static bool isValidPluginName(String name) {
    if (name.isEmpty || name.length > 50) return false;
    
    // 检查格式：只允许字母、数字、下划线，必须以字母开头
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// 验证版本号格式
  /// 
  /// [version] 版本号
  /// 
  /// 返回是否有效
  static bool isValidVersion(String version) {
    if (version.isEmpty) return false;
    
    // 检查语义化版本格式：x.y.z
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  /// 格式化文件大小
  /// 
  /// [bytes] 字节数
  /// 
  /// 返回格式化的文件大小字符串
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 格式化时间间隔
  /// 
  /// [duration] 时间间隔
  /// 
  /// 返回格式化的时间字符串
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天 ${duration.inHours % 24}小时';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时 ${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟 ${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 生成唯一ID
  /// 
  /// [prefix] 前缀
  /// 
  /// 返回唯一ID字符串
  static String generateUniqueId([String? prefix]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${prefix ?? {{plugin_name.pascalCase()}}Constants.pluginId}_${timestamp}_$random';
  }

  /// 安全的JSON解析
  /// 
  /// [jsonString] JSON字符串
  /// 
  /// 返回解析结果或null
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      final result = jsonDecode(jsonString);
      return result is Map<String, dynamic> ? result : null;
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] JSON解析失败: $e');
      return null;
    }
  }

  /// 安全的JSON编码
  /// 
  /// [data] 要编码的数据
  /// 
  /// 返回JSON字符串或null
  static String? safeJsonEncode(dynamic data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] JSON编码失败: $e');
      return null;
    }
  }

  /// 检查网络连接
  /// 
  /// 返回是否有网络连接
  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取平台信息
  /// 
  /// 返回当前平台信息
  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': _getCurrentPlatform(),
      'isWeb': kIsWeb,
      'isDebugMode': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
  }

  /// 获取当前平台名称
  static String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    
    return 'unknown';
  }

  /// 验证权限名称
  /// 
  /// [permission] 权限名称
  /// 
  /// 返回是否有效
  static bool isValidPermission(String permission) {
    const validPermissions = [
      'fileSystem',
      'network',
      'camera',
      'microphone',
      'location',
      'notifications',
    ];
    return validPermissions.contains(permission);
  }

  /// 清理临时文件
  /// 
  /// [directory] 临时文件目录
  /// 
  /// 返回清理结果
  static Future<bool> cleanupTempFiles(String directory) async {
    try {
      final dir = Directory(directory);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] 清理临时文件失败: $e');
      return false;
    }
  }

  /// 创建目录
  /// 
  /// [path] 目录路径
  /// 
  /// 返回创建结果
  static Future<bool> createDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] 创建目录失败: $e');
      return false;
    }
  }

  /// 复制文件
  /// 
  /// [sourcePath] 源文件路径
  /// [targetPath] 目标文件路径
  /// 
  /// 返回复制结果
  static Future<bool> copyFile(String sourcePath, String targetPath) async {
    try {
      final sourceFile = File(sourcePath);
      final targetFile = File(targetPath);
      
      if (!await sourceFile.exists()) {
        throw {{plugin_name.pascalCase()}}FileSystemException(
          '源文件不存在',
          filePath: sourcePath,
          operation: 'copy',
        );
      }
      
      // 确保目标目录存在
      final targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      await sourceFile.copy(targetPath);
      return true;
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] 复制文件失败: $e');
      return false;
    }
  }

  /// 计算文件哈希值
  /// 
  /// [filePath] 文件路径
  /// 
  /// 返回文件哈希值
  static Future<String?> calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      // 简单的哈希计算（实际项目中应使用crypto包）
      return bytes.fold<int>(0, (prev, byte) => prev + byte).toString();
    } catch (e) {
      debugPrint('[{{plugin_name.pascalCase()}}Utils] 计算文件哈希失败: $e');
      return null;
    }
  }

  /// 验证配置数据
  /// 
  /// [config] 配置数据
  /// 
  /// 返回验证结果
  static List<String> validateConfig(Map<String, dynamic> config) {
    final errors = <String>[];
    
    // 验证必需字段
    if (!config.containsKey('enabled')) {
      errors.add('缺少必需字段: enabled');
    }
    
    if (!config.containsKey('logLevel')) {
      errors.add('缺少必需字段: logLevel');
    }
    
    // 验证数据类型
    if (config['enabled'] != null && config['enabled'] is! bool) {
      errors.add('字段 enabled 必须是布尔值');
    }
    
    if (config['maxRetries'] != null && config['maxRetries'] is! int) {
      errors.add('字段 maxRetries 必须是整数');
    }
    
    // 验证数值范围
    if (config['maxRetries'] != null) {
      final retries = config['maxRetries'] as int;
      if (retries < 0 || retries > 10) {
        errors.add('字段 maxRetries 必须在 0-10 之间');
      }
    }
    
    return errors;
  }

  /// 格式化错误消息
  /// 
  /// [error] 错误对象
  /// [context] 上下文信息
  /// 
  /// 返回格式化的错误消息
  static String formatError(Object error, [String? context]) {
    final buffer = StringBuffer();
    
    if (context != null) {
      buffer.write('[$context] ');
    }
    
    if (error is {{plugin_name.pascalCase()}}Exception) {
      buffer.write('${error.message}');
      if (error.code != null) {
        buffer.write(' (${error.code})');
      }
    } else {
      buffer.write(error.toString());
    }
    
    return buffer.toString();
  }
}
