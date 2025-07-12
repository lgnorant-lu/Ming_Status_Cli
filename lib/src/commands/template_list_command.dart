/*
---------------------------------------------------------------
File name:          template_list_command.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板列表命令 (Template List Command)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - 模板列表命令;
*/

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板列表命令
class TemplateListCommand extends Command<int> {
  TemplateListCommand() {
    argParser
      ..addOption('type', abbr: 't', help: '按模板类型过滤')
      ..addOption('platform', abbr: 'p', help: '按目标平台过滤')
      ..addFlag('detailed', abbr: 'd', help: '显示详细信息');
  }

  @override
  String get name => 'list';

  @override
  String get description => '列出可用的模板';

  @override
  String get usage => '''
列出可用的模板

使用方法:
  ming template list [选项]

过滤选项:
  -t, --type=<类型>          按模板类型过滤
  -p, --platform=<平台>      按目标平台过滤

显示选项:
  -d, --detailed             显示详细信息

示例:
  # 列出所有模板
  ming template list

  # 按类型过滤
  ming template list --type=ui

  # 按平台过滤
  ming template list --platform=flutter

  # 显示详细信息
  ming template list --detailed

  # 组合过滤
  ming template list --type=ui --platform=flutter --detailed

更多信息:
  使用 'ming help template list' 查看详细文档
''';

  @override
  Future<int> run() async {
    try {
      cli_logger.Logger.info('正在获取模板列表...');

      final registry = TemplateRegistry(registryPath: Directory.current.path);
      const query = TemplateSearchQuery();
      final searchResult = await registry.searchTemplates(query);

      if (searchResult.templates.isEmpty) {
        cli_logger.Logger.warning('未找到模板');
        return 0;
      }

      _displayResults(searchResult.templates);
      cli_logger.Logger.success('找到 ${searchResult.templates.length} 个模板');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('获取模板列表失败', error: e);
      return 1;
    }
  }

  void _displayResults(List<TemplateMetadata> results) {
    final detailed = argResults!['detailed'] as bool;

    print('\n📋 模板列表');
    print('─' * 80);

    if (detailed) {
      for (final metadata in results) {
        print('📦 ${metadata.name} (${metadata.version})');
        print('   类型: ${metadata.type.name}');
        print('   作者: ${metadata.author}');
        print('   描述: ${metadata.description}');
        print('');
      }
    } else {
      for (final metadata in results) {
        print(
          '${metadata.name.padRight(25)} ${metadata.type.name.padRight(12)} ${metadata.author}',
        );
      }
    }
  }
}
