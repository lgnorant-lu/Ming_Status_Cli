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
import 'package:ming_status_cli/src/commands/template_enterprise_command.dart';
import 'package:ming_status_cli/src/commands/template_generate_command.dart';
import 'package:ming_status_cli/src/commands/template_info_command.dart';
import 'package:ming_status_cli/src/commands/template_inherit_command.dart';
import 'package:ming_status_cli/src/commands/template_install_command.dart';
import 'package:ming_status_cli/src/commands/template_library_command.dart';
import 'package:ming_status_cli/src/commands/template_list_command.dart';
import 'package:ming_status_cli/src/commands/template_network_command.dart';
import 'package:ming_status_cli/src/commands/template_params_command.dart';
import 'package:ming_status_cli/src/commands/template_search_command.dart';
import 'package:ming_status_cli/src/commands/template_security_command.dart';
import 'package:ming_status_cli/src/commands/template_update_command.dart';

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

    // Phase 2.2 Week 2: 智能搜索和分发系统
    addSubcommand(TemplateInstallCommand());
    addSubcommand(TemplateUpdateCommand());

    // Task 2.2.2: 企业级安全验证系统
    addSubcommand(TemplateSecurityCommand());

    // Task 2.2.4: 企业级模板管理
    addSubcommand(TemplateEnterpriseCommand());

    // Task 2.2.5: 网络通信和离线支持
    addSubcommand(TemplateNetworkCommand());
  }

  @override
  String get name => 'template';

  @override
  String get description => '模板管理命令';

  @override
  String get usage => '''
模板管理命令

使用方法:
  ming template <子命令> [选项]

子命令:
  list                   列出可用的模板
  search                 搜索模板
  info                   显示模板详细信息
  create                 创建自定义模板
  generate               生成模板实例
  inherit                模板继承和组合
  conditional            条件模板生成
  params                 参数化系统管理
  library                模板库管理
  benchmark              执行性能基准测试
  install                安装模板 (支持依赖解析)
  update                 更新模板 (支持批量更新)
  security               模板安全验证和管理
  enterprise             企业级模板管理
  network                网络通信和离线支持

示例:
  # 模板发现
  ming template list --type=ui --platform=flutter
  ming template search "clean architecture" --tags=mvvm
  ming template info flutter_clean_app --detailed

  # 模板创建
  ming template create --wizard
  ming template generate my_app --template=flutter_clean

  # 高级功能
  ming template inherit base_template --extend=ui_components
  ming template conditional --if="platform==mobile" --template=responsive

  # 参数化管理
  ming template params --set theme=dark --template=my_app
  ming template library --add ./my_templates --name=custom

  # 性能测试
  ming template benchmark --templates=100 --operations=load,validate

  # 查看子命令帮助
  ming template <子命令> --help

更多信息:
  使用 'ming help template' 查看详细文档
''';

  @override
  Future<int> run() async {
    // 如果没有提供子命令，显示帮助信息
    print(usage);
    return 0;
  }
}
