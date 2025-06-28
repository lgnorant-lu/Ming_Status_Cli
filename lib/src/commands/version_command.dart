/*
---------------------------------------------------------------
File name:          version_command.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        版本命令 (Version command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 版本信息显示命令;
---------------------------------------------------------------
*/

import 'dart:io';

import 'base_command.dart';
import '../utils/logger.dart';
import '../utils/file_utils.dart';

/// 版本命令
/// 显示CLI工具的版本信息
class VersionCommand extends BaseCommand {
  @override
  String get name => 'version';

  @override
  String get description => '显示版本信息';

  @override
  String get invocation => 'ming version';

  VersionCommand() {
    argParser.addFlag(
      'detailed',
      abbr: 'd',
      help: '显示详细版本信息',
      negatable: false,
    );
  }

  @override
  Future<int> execute() async {
    final detailed = argResults!['detailed'] as bool;
    
    if (detailed) {
      await _showDetailedVersion();
    } else {
      await _showSimpleVersion();
    }

    return 0;
  }

  /// 显示简单版本信息
  Future<void> _showSimpleVersion() async {
    final version = await _getVersion();
    print('Ming Status CLI v$version');
  }

  /// 显示详细版本信息
  Future<void> _showDetailedVersion() async {
    Logger.title('Ming Status CLI 版本信息');
    
    final version = await _getVersion();
    final dartVersion = Platform.version;
    final platform = _getPlatformInfo();
    
    Logger.keyValue('版本', version);
    Logger.keyValue('Dart SDK', dartVersion.split(' ').first);
    Logger.keyValue('平台', platform);
    Logger.keyValue('可执行文件', Platform.resolvedExecutable);
    
    Logger.newLine();
    Logger.subtitle('运行环境');
    Logger.keyValue('操作系统', Platform.operatingSystem);
    Logger.keyValue('系统版本', Platform.operatingSystemVersion);
    Logger.keyValue('处理器架构', Platform.localeName);
    
    // 显示工作空间信息
    if (configManager.isWorkspaceInitialized()) {
      Logger.newLine();
      Logger.subtitle('当前工作空间');
      
      final config = await configManager.loadWorkspaceConfig();
      if (config != null) {
        Logger.keyValue('名称', config.workspace.name);
        Logger.keyValue('版本', config.workspace.version);
        Logger.keyValue('描述', config.workspace.description ?? 'N/A');
        Logger.keyValue('配置文件', configManager.configFilePath);
      }
    } else {
      Logger.newLine();
      Logger.info('当前目录未初始化为Ming Status工作空间');
    }
    
    Logger.newLine();
    Logger.subtitle('支持信息');
    print('  文档: https://github.com/ignorant-lu/ming-status-cli/wiki');
    print('  问题反馈: https://github.com/ignorant-lu/ming-status-cli/issues');
    print('  许可证: MIT License');
  }

  /// 获取版本号
  Future<String> _getVersion() async {
    try {
      // 尝试从pubspec.yaml读取版本
      final pubspecPath = _findPubspecPath();
      if (pubspecPath != null) {
        final yamlData = await FileUtils.readYamlFile(pubspecPath);
        if (yamlData != null && yamlData.containsKey('version')) {
          return yamlData['version'].toString();
        }
      }
    } catch (e) {
      Logger.debug('无法从pubspec.yaml读取版本: $e');
    }
    
    // 默认版本
    return '1.0.0';
  }

  /// 查找pubspec.yaml文件
  String? _findPubspecPath() {
    // 从当前目录开始向上查找
    var currentDir = Directory.current;
    
    while (true) {
      final pubspecPath = '${currentDir.path}/pubspec.yaml';
      if (FileUtils.fileExists(pubspecPath)) {
        return pubspecPath;
      }
      
      final parentDir = currentDir.parent;
      if (parentDir.path == currentDir.path) {
        // 已到达根目录
        break;
      }
      currentDir = parentDir;
    }
    
    return null;
  }

  /// 获取平台信息
  String _getPlatformInfo() {
    final os = Platform.operatingSystem;
    final arch = _getArchitecture();
    return '$os-$arch';
  }

  /// 获取处理器架构
  String _getArchitecture() {
    // 这是一个简化的实现
    if (Platform.version.contains('x64')) {
      return 'x64';
    } else if (Platform.version.contains('arm64')) {
      return 'arm64';
    } else if (Platform.version.contains('arm')) {
      return 'arm';
    } else {
      return 'unknown';
    }
  }
} 