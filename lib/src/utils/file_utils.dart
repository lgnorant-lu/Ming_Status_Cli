/*
---------------------------------------------------------------
File name:          file_utils.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        文件操作工具类 (File operation utilities)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础文件操作功能;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 文件操作工具类
/// 提供安全、便捷的文件和目录操作方法
class FileUtils {
  /// 检查文件是否存在
  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// 检查目录是否存在
  static bool directoryExists(String dirPath) {
    return Directory(dirPath).existsSync();
  }

  /// 创建目录（递归创建）
  static Future<Directory> createDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return await dir.create(recursive: true);
    }
    return dir;
  }

  /// 安全地读取文件内容
  static Future<String?> readFileAsString(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return await file.readAsString();
      }
    } catch (e) {
      // 文件读取失败
      return null;
    }
    return null;
  }

  /// 安全地写入文件内容
  static Future<bool> writeFileAsString(
    String filePath, 
    String content, {
    bool createDirectories = true,
  }) async {
    try {
      final file = File(filePath);
      
      // 创建父目录
      if (createDirectories) {
        final dir = Directory(path.dirname(filePath));
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
      }
      
      await file.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 安全地追加文件内容
  static Future<bool> appendToFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content, mode: FileMode.append);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 复制文件
  static Future<bool> copyFile(String sourcePath, String targetPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) return false;
      
      // 创建目标目录
      final targetDir = Directory(path.dirname(targetPath));
      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }
      
      await sourceFile.copy(targetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除目录（递归删除）
  static Future<bool> deleteDirectory(String dirPath, {bool recursive = false}) async {
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: recursive);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取文件大小（字节）
  static int getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (e) {
      // 获取文件大小失败
    }
    return 0;
  }

  /// 获取文件修改时间
  static DateTime? getFileModifiedTime(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return file.lastModifiedSync();
      }
    } catch (e) {
      // 获取修改时间失败
    }
    return null;
  }

  /// 列出目录下的文件
  static List<FileSystemEntity> listDirectory(
    String dirPath, {
    bool recursive = false,
    bool followLinks = true,
  }) {
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        return dir.listSync(recursive: recursive, followLinks: followLinks);
      }
    } catch (e) {
      // 列出目录失败
    }
    return [];
  }

  /// 查找文件
  static List<String> findFiles(
    String dirPath, 
    String pattern, {
    bool recursive = true,
  }) {
    final files = <String>[];
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: recursive);
        for (final entity in entities) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            if (fileName.contains(pattern)) {
              files.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      // 查找文件失败
    }
    return files;
  }

  /// 读取YAML文件
  static Future<Map<String, dynamic>?> readYamlFile(String filePath) async {
    try {
      final content = await readFileAsString(filePath);
      if (content != null) {
        final yamlDoc = loadYaml(content);
        if (yamlDoc is Map) {
          return Map<String, dynamic>.from(yamlDoc);
        }
      }
    } catch (e) {
      // YAML解析失败
    }
    return null;
  }

  /// 写入YAML文件
  static Future<bool> writeYamlFile(
    String filePath, 
    Map<String, dynamic> data,
  ) async {
    try {
      // 这里使用简单的YAML格式化，生产环境可能需要更完善的YAML生成器
      final yamlContent = _formatAsYaml(data);
      return await writeFileAsString(filePath, yamlContent);
    } catch (e) {
      return false;
    }
  }

  /// 获取相对路径
  static String getRelativePath(String from, String to) {
    return path.relative(to, from: from);
  }

  /// 获取绝对路径
  static String getAbsolutePath(String relativePath) {
    return path.absolute(relativePath);
  }

  /// 规范化路径
  static String normalizePath(String inputPath) {
    return path.normalize(inputPath);
  }

  /// 连接路径
  static String joinPath(List<String> parts) {
    return path.joinAll(parts);
  }

  /// 获取文件扩展名
  static String getExtension(String filePath) {
    return path.extension(filePath);
  }

  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取目录名
  static String getDirName(String filePath) {
    return path.dirname(filePath);
  }

  /// 简单的YAML格式化（基础版本）
  static String _formatAsYaml(Map<String, dynamic> data, {int indent = 0}) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Map<String, dynamic>) {
        buffer.writeln('$indentStr$key:');
        buffer.write(_formatAsYaml(value, indent: indent + 1));
      } else if (value is List) {
        buffer.writeln('$indentStr$key:');
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            buffer.writeln('${indentStr}  -');
            buffer.write(_formatAsYaml(item, indent: indent + 2));
          } else {
            buffer.writeln('${indentStr}  - $item');
          }
        }
      } else {
        buffer.writeln('$indentStr$key: $value');
      }
    }
    
    return buffer.toString();
  }

  /// 确保路径安全（防止路径遍历攻击）
  static bool isPathSafe(String inputPath, String basePath) {
    final resolvedPath = path.normalize(path.absolute(inputPath));
    final resolvedBase = path.normalize(path.absolute(basePath));
    return resolvedPath.startsWith(resolvedBase);
  }

  /// 创建临时文件
  static Future<File> createTempFile({String? prefix, String? suffix}) async {
    final tempDir = Directory.systemTemp;
    final tempDirCreated = await tempDir.createTemp(prefix);
    final tempFilePath = suffix != null 
        ? '${tempDirCreated.path}$suffix'
        : '${tempDirCreated.path}.tmp';
    
    final tempFile = File(tempFilePath);
    await tempFile.create();
    
    // 清理临时目录
    await tempDirCreated.delete();
    
    return tempFile;
  }
} 