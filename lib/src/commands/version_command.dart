/*
---------------------------------------------------------------
File name:          version_command.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        版本信息命令 (Version information command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 版本信息显示命令;
    2025/06/29: Performance optimization - 轻量级实现，避免重度依赖;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

import '../utils/logger.dart';

/// 版本信息命令
/// 显示Ming Status CLI的版本和系统信息（轻量级实现）
class VersionCommand extends Command<int> {
  @override
  String get name => 'version';

  @override
  String get description => '显示版本信息和系统环境详情';

  @override
  String get invocation => 'ming version [--detailed]';

  VersionCommand() {
    argParser.addFlag(
      'detailed',
      abbr: 'd',
      help: '显示详细的系统和环境信息',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    // 轻量级执行，不依赖BaseCommand的重度服务
    final detailed = argResults?['detailed'] == true;
    
    if (detailed) {
      await _showDetailedVersion();
    } else {
      await _showSimpleVersion();
    }
    
    return 0;
  }

  /// 显示简单版本信息
  Future<void> _showSimpleVersion() async {
    final version = await _getVersionFromPubspec();
    print('Ming Status CLI $version');
  }

  /// 显示详细版本信息  
  Future<void> _showDetailedVersion() async {
    Logger.title('Ming Status CLI 详细信息');
    Logger.newLine();
    
    // 版本信息
    Logger.subtitle('🏷️  版本信息');
    final version = await _getVersionFromPubspec();
    Logger.keyValue('版本', version);
    Logger.keyValue('构建时间', _getBuildInfo());
    Logger.newLine();
    
    // 运行环境
    Logger.subtitle('🖥️  运行环境');
    Logger.keyValue('操作系统', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    Logger.keyValue('架构', _getArchitecture());
    Logger.keyValue('Dart版本', Platform.version);
    Logger.newLine();
    
    // 系统信息
    Logger.subtitle('📁 系统信息');
    Logger.keyValue('当前目录', Directory.current.path);
    Logger.keyValue('可执行文件', Platform.resolvedExecutable);
    Logger.keyValue('环境变量PATH', Platform.environment['PATH'] != null ? '已设置' : '未设置');
    Logger.newLine();
    
    // 性能信息
    Logger.subtitle('⚡ 性能信息');
    Logger.keyValue('处理器核心数', Platform.numberOfProcessors.toString());
    Logger.keyValue('内存使用', _getMemoryUsage());
    Logger.newLine();
    
    Logger.info('如需更多信息，请访问: https://github.com/ignorant-lu/ming-status-cli');
  }

  /// 从pubspec.yaml获取版本信息（缓存结果）
  static String? _cachedVersion;
  Future<String> _getVersionFromPubspec() async {
    if (_cachedVersion != null) return _cachedVersion!;
    
    try {
      // 查找pubspec.yaml文件
      String? pubspecPath;
      var currentDir = Directory.current;
      
      // 向上搜索pubspec.yaml
      for (int i = 0; i < 5; i++) {
        final candidate = File(path.join(currentDir.path, 'pubspec.yaml'));
        if (await candidate.exists()) {
          pubspecPath = candidate.path;
          break;
        }
        
        final parent = currentDir.parent;
        if (parent.path == currentDir.path) break; // 已到根目录
        currentDir = parent;
      }
      
      if (pubspecPath != null) {
        final content = await File(pubspecPath).readAsString();
        final yaml = loadYaml(content) as Map;
        _cachedVersion = yaml['version']?.toString() ?? '开发版本';
      } else {
        _cachedVersion = '开发版本';
      }
    } catch (e) {
      _cachedVersion = '开发版本';
    }
    
    return _cachedVersion!;
  }

  /// 获取构建信息
  String _getBuildInfo() {
    // 简化的构建信息
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 获取系统架构信息
  String _getArchitecture() {
    try {
      // 尝试多种方式获取架构信息
      final env = Platform.environment;
      
      // Windows
      if (Platform.isWindows) {
        return env['PROCESSOR_ARCHITECTURE'] ?? 
               env['PROCESSOR_ARCHITEW6432'] ?? 
               'unknown';
      }
      
      // Unix-like系统
      if (Platform.isLinux || Platform.isMacOS) {
        return Process.runSync('uname', ['-m']).stdout.toString().trim();
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// 获取内存使用信息（简化版）
  String _getMemoryUsage() {
    try {
      if (Platform.isWindows) {
        // Windows系统
        final result = Process.runSync('tasklist', ['/FI', 'PID eq ${pid}', '/FO', 'CSV']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final fields = lines[1].split(',');
            if (fields.length > 4) {
              return fields[4].replaceAll('"', '').trim();
            }
          }
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        // Unix系统
        final result = Process.runSync('ps', ['-o', 'rss=', '-p', pid.toString()]);
        if (result.exitCode == 0) {
          final kb = int.tryParse(result.stdout.toString().trim());
          if (kb != null) {
            return '${(kb / 1024).toStringAsFixed(1)} MB';
          }
        }
      }
    } catch (e) {
      // 忽略错误，返回未知
    }
    
    return '未知';
  }
} 