/*
---------------------------------------------------------------
File name:          version_command.dart
Author:             lgnorant-lu
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
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/version.dart';

/// 版本信息命令
/// 显示Ming Status CLI的版本和系统信息（轻量级实现）
class VersionCommand extends Command<int> {
  /// 创建版本命令实例，配置命令行参数选项
  VersionCommand() {
    argParser.addFlag(
      'detailed',
      abbr: 'd',
      help: '显示详细的系统和环境信息',
      negatable: false,
    );
  }
  @override
  String get name => 'version';

  @override
  String get description => '显示版本信息和系统环境详情';

  @override
  String get invocation => 'ming version [--detailed]';

  @override
  String get usage => '''
显示版本信息和系统环境详情

使用方法:
  ming version [选项]

选项:
  -d, --detailed             显示详细的系统和环境信息

示例:
  # 显示基本版本信息
  ming version

  # 显示详细版本和系统信息
  ming version --detailed

更多信息:
  使用 'ming help version' 查看详细文档
''';

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
    final version = VersionManager.instance.getVersion();
    final name = VersionManager.instance.getName();
    Logger.info('$name $version');
  }

  /// 显示详细版本信息
  Future<void> _showDetailedVersion() async {
    Logger.title('Ming Status CLI 详细信息');
    Logger.newLine();

    // 版本信息
    Logger.subtitle('🏷️  版本信息');
    final version = VersionManager.instance.getVersion();
    final name = VersionManager.instance.getName();
    final description = VersionManager.instance.getDescription();
    final repository = VersionManager.instance.getRepository();

    Logger.keyValue('应用名称', name);
    Logger.keyValue('版本', version);
    Logger.keyValue('描述', description);
    Logger.keyValue('仓库', repository);
    Logger.keyValue('构建时间', _getBuildInfo());
    Logger.newLine();

    // 运行环境
    Logger.subtitle('🖥️  运行环境');
    Logger.keyValue(
      '操作系统',
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
    Logger.keyValue('架构', _getArchitecture());
    Logger.keyValue('Dart版本', Platform.version);
    Logger.newLine();

    // 系统信息
    Logger.subtitle('📁 系统信息');
    Logger.keyValue('当前目录', Directory.current.path);
    Logger.keyValue('可执行文件', Platform.resolvedExecutable);
    Logger.keyValue(
      '环境变量PATH',
      Platform.environment['PATH'] != null ? '已设置' : '未设置',
    );
    Logger.newLine();

    // 性能信息
    Logger.subtitle('⚡ 性能信息');
    Logger.keyValue('处理器核心数', Platform.numberOfProcessors.toString());
    Logger.keyValue('内存使用', _getMemoryUsage());
    Logger.newLine();

    final repoUrl = VersionManager.instance.getRepository();
    Logger.info('如需更多信息，请访问: $repoUrl');
  }

  /// 获取构建信息
  String _getBuildInfo() {
    // 尝试从编译时常量获取构建时间
    const buildTime = String.fromEnvironment('BUILD_TIME');
    if (buildTime.isNotEmpty) {
      return buildTime;
    }

    // 尝试从Git获取最后提交时间
    try {
      final result = Process.runSync('git', ['log', '-1', '--format=%ci']);
      if (result.exitCode == 0) {
        final gitDate = result.stdout.toString().trim();
        if (gitDate.isNotEmpty) {
          final dateTime = DateTime.tryParse(gitDate);
          if (dateTime != null) {
            return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
                '${dateTime.day.toString().padLeft(2, '0')}';
          }
        }
      }
    } catch (e) {
      // Git命令失败，继续使用fallback
    }

    // Fallback: 使用pubspec.yaml的修改时间
    try {
      final pubspecFile = File('pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final stat = pubspecFile.statSync();
        final modified = stat.modified;
        return '${modified.year}-${modified.month.toString().padLeft(2, '0')}-'
            '${modified.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // 文件操作失败
    }

    // 最后的fallback: 显示"开发版本"
    return '开发版本';
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
      final currentPid = pid;

      if (Platform.isWindows) {
        // Windows系统 - 使用 tasklist 命令
        final result = Process.runSync(
          'tasklist',
          ['/FI', 'PID eq $currentPid', '/FO', 'CSV'],
        );
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final fields = lines[1].split(',');
            if (fields.length > 4) {
              return fields[4].replaceAll('"', '').trim();
            }
          }
        }

        // 备用方案：使用 wmic 命令
        final wmicResult = Process.runSync('wmic', [
          'process',
          'where',
          'ProcessId=$currentPid',
          'get',
          'WorkingSetSize',
          '/value',
        ]);
        if (wmicResult.exitCode == 0) {
          final output = wmicResult.stdout.toString();
          final match = RegExp(r'WorkingSetSize=(\d+)').firstMatch(output);
          if (match != null) {
            final bytes = int.tryParse(match.group(1)!);
            if (bytes != null) {
              return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
            }
          }
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        // Unix系统 - 使用 ps 命令
        final result =
            Process.runSync('ps', ['-o', 'rss=', '-p', currentPid.toString()]);
        if (result.exitCode == 0) {
          final kb = int.tryParse(result.stdout.toString().trim());
          if (kb != null) {
            return '${(kb / 1024).toStringAsFixed(1)} MB';
          }
        }

        // 备用方案：读取 /proc/self/status
        try {
          final statusFile = File('/proc/self/status');
          if (statusFile.existsSync()) {
            final content = statusFile.readAsStringSync();
            final match = RegExp(r'VmRSS:\s*(\d+)\s*kB').firstMatch(content);
            if (match != null) {
              final kb = int.tryParse(match.group(1)!);
              if (kb != null) {
                return '${(kb / 1024).toStringAsFixed(1)} MB';
              }
            }
          }
        } catch (e) {
          // 忽略文件读取错误
        }
      }
    } catch (e) {
      // 忽略错误，返回未知
    }

    return '未知';
  }
}
