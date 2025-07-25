/*
---------------------------------------------------------------
File name:          plugin_build_command.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件构建命令 (Plugin build command)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 实现插件构建功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/plugin_system/plugin_builder.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 插件构建命令
///
/// 构建插件包，生成可分发的插件文件。
class PluginBuildCommand extends BaseCommand {
  /// 创建插件构建命令实例
  PluginBuildCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: '输出目录路径',
        defaultsTo: './dist',
      )
      ..addFlag(
        'release',
        abbr: 'r',
        help: '构建发布版本',
        defaultsTo: false,
      );
  }

  @override
  String get name => 'build';

  @override
  String get description => '构建插件包';

  @override
  String get usage => '''
构建插件包

使用方法:
  ming plugin build [选项]

选项:
  -o, --output=<路径>    输出目录路径 (默认: ./dist)
  -r, --release          构建发布版本
  -v, --verbose          显示详细构建信息
  -h, --help             显示帮助信息

示例:
  # 构建插件包
  ming plugin build

  # 构建到指定目录
  ming plugin build --output=./build

  # 构建发布版本
  ming plugin build --release

更多信息:
  使用 'ming help plugin build' 查看详细文档
''';

  @override
  Future<int> execute() async {
    final outputPath = argResults!['output'] as String;
    final isRelease = argResults!['release'] as bool;

    Logger.info('🔨 开始构建插件包...');
    Logger.debug('输出路径: $outputPath');
    Logger.debug('发布模式: $isRelease');

    // 检查当前目录是否为插件项目
    final currentDir = Directory.current.path;
    final pluginYamlFile = File('$currentDir/plugin.yaml');
    final pubspecYamlFile = File('$currentDir/pubspec.yaml');

    if (!pluginYamlFile.existsSync() || !pubspecYamlFile.existsSync()) {
      Logger.error('当前目录不是有效的插件项目');
      Logger.info('请确保当前目录包含 plugin.yaml 和 pubspec.yaml 文件');
      return 1;
    }

    try {
      // 创建插件构建器
      final builder = PluginBuilder();

      // 执行构建
      final result = await builder.buildPlugin(
        currentDir,
        outputPath: outputPath,
        isRelease: isRelease,
      );

      // 显示构建结果
      _displayBuildResult(result);

      if (result.isSuccess) {
        Logger.success('✅ 插件构建成功！');
        Logger.info('📦 插件包位置: ${result.outputPath}');
        return 0;
      } else {
        Logger.error('❌ 插件构建失败');
        return 1;
      }
    } catch (e) {
      Logger.error('构建过程中发生错误: $e');
      return 1;
    }
  }

  /// 显示构建结果
  void _displayBuildResult(PluginBuildResult result) {
    Logger.info('\n📋 构建结果摘要:');
    Logger.info('  构建状态: ${result.isSuccess ? "成功" : "失败"}');
    Logger.info('  生成文件: ${result.builtFiles.length} 个');

    if (result.errors.isNotEmpty) {
      Logger.info('\n❌ 错误:');
      for (final error in result.errors) {
        Logger.error('  • $error');
      }
    }

    if (result.warnings.isNotEmpty) {
      Logger.info('\n⚠️  警告:');
      for (final warning in result.warnings) {
        Logger.warning('  • $warning');
      }
    }

    if (verbose && result.builtFiles.isNotEmpty) {
      Logger.info('\n📁 生成的文件:');
      for (final file in result.builtFiles) {
        Logger.info('  • $file');
      }
    }
  }
}
