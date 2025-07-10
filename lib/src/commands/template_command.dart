/*
---------------------------------------------------------------
File name:          template_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        模板管理主命令 (Template Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 模板管理主命令;
    2025/07/11: Feature enhancement - 添加子命令实现;
---------------------------------------------------------------
*/

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/commands/template_benchmark_command.dart';
import 'package:ming_status_cli/src/commands/template_conditional_command.dart';
import 'package:ming_status_cli/src/commands/template_create_command.dart';
import 'package:ming_status_cli/src/commands/template_generate_command.dart';
import 'package:ming_status_cli/src/commands/template_info_command.dart';
import 'package:ming_status_cli/src/commands/template_inherit_command.dart';
import 'package:ming_status_cli/src/commands/template_library_command.dart';
import 'package:ming_status_cli/src/commands/template_list_command.dart';
import 'package:ming_status_cli/src/commands/template_params_command.dart';
import 'package:ming_status_cli/src/commands/template_search_command.dart';

/// 模板管理主命令
///
/// 实现 `ming template` 命令及其所有子命令
class TemplateCommand extends Command<int> {
  /// 创建模板命令实例
  TemplateCommand() {
    // 添加子命令 - Task 2.1.1: 多层级模板系统重构
    addSubcommand(TemplateListCommand());
    addSubcommand(TemplateSearchCommand());
    addSubcommand(TemplateInfoCommand());
    addSubcommand(TemplateBenchmarkCommand());

    // Task 2.1.4: 自定义模板创建工具
    addSubcommand(TemplateCreateCommand());

    // Task 2.1.2: 企业级模板继承和组合引擎
    addSubcommand(TemplateInheritCommand());

    // Task 2.2.1: 智能条件生成系统
    addSubcommand(TemplateConditionalCommand());

    // Task 2.2.2: 企业级参数化系统
    addSubcommand(TemplateParamsCommand());

    // Task 2.3.1: 企业级模板创建工具
    addSubcommand(TemplateGenerateCommand());

    // Task 2.3.2: 企业级模板库管理系统
    addSubcommand(TemplateLibraryCommand());
  }

  @override
  String get name => 'template';

  @override
  String get description => '模板管理命令';

  @override
  String get usage => '''
使用方法:
  ming template <子命令> [选项]

可用子命令:
  list        列出可用的模板
  search      搜索模板
  info        显示模板详细信息
  benchmark   执行性能基准测试
  create      创建自定义模板

示例:
  # 列出模板
  ming template list --type=ui --platform=flutter

  # 搜索模板
  ming template search "clean architecture"

  # 查看模板信息
  ming template info flutter_clean_app --detailed

  # 性能测试
  ming template benchmark --templates=100 --operations=load,validate

  # 创建模板
  ming template create --wizard
  ming template create --name my_widget --type ui

  # 查看帮助
  ming template --help
  ming template <子命令> --help
''';

  @override
  Future<int> run() async {
    // 如果没有提供子命令，显示帮助信息
    printUsage();
    return 0;
  }
}
