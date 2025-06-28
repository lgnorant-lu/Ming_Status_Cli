/*
---------------------------------------------------------------
File name:          help_command.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        帮助命令 (Help command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI帮助信息命令;
---------------------------------------------------------------
*/

import 'base_command.dart';
import '../utils/logger.dart';

/// 帮助命令
/// 显示详细的CLI使用帮助信息
class HelpCommand extends BaseCommand {
  @override
  String get name => 'help';

  @override
  String get description => '显示命令帮助信息';

  @override
  String get invocation => 'ming help [command]';

  @override
  Future<int> execute() async {
    final commandName = argResults?.rest.isNotEmpty == true 
        ? argResults!.rest.first 
        : null;

    if (commandName != null) {
      _showCommandHelp(commandName);
    } else {
      _showGeneralHelp();
    }

    return 0;
  }

  /// 显示通用帮助信息
  void _showGeneralHelp() {
    Logger.title('Ming Status CLI - 模块化开发工具');
    
    print('''
Ming Status CLI 是一个强大的模块化开发工具，用于创建、管理和验证模块化应用的代码结构。

用法:
  ming <command> [arguments]

全局选项:
  -v, --verbose    显示详细输出
  -q, --quiet      静默模式，仅显示错误
  -h, --help       显示帮助信息
      --version    显示版本信息

可用命令:''');

    _showCommandList();

    print('''

示例:
  ming init my_workspace          # 初始化工作空间
  ming template create basic      # 创建基础模板
  ming generate basic ./my_module # 使用模板生成模块
  ming validate ./my_module       # 验证模块结构

获取特定命令的帮助:
  ming help <command>

更多信息请访问: https://github.com/ignorant-lu/ming-status-cli
''');
  }

  /// 显示命令列表
  void _showCommandList() {
    final commands = [
      CommandInfo(
        name: 'init',
        description: '初始化Ming Status工作空间',
        usage: 'ming init [workspace_name]',
      ),
      CommandInfo(
        name: 'template',
        description: '模板管理（创建、列出、删除模板）',
        usage: 'ming template <create|list|delete> [args]',
      ),
      CommandInfo(
        name: 'generate',
        description: '使用模板生成模块代码',
        usage: 'ming generate <template> <output_path>',
      ),
      CommandInfo(
        name: 'validate',
        description: '验证模块结构和规范',
        usage: 'ming validate <module_path>',
      ),
      CommandInfo(
        name: 'status',
        description: '显示工作空间状态信息',
        usage: 'ming status',
      ),
      CommandInfo(
        name: 'clean',
        description: '清理临时文件和缓存',
        usage: 'ming clean',
      ),
      CommandInfo(
        name: 'help',
        description: '显示帮助信息',
        usage: 'ming help [command]',
      ),
      CommandInfo(
        name: 'version',
        description: '显示版本信息',
        usage: 'ming version',
      ),
    ];

    for (final cmd in commands) {
      final nameFormatted = cmd.name.padRight(12);
      print('  $nameFormatted ${cmd.description}');
    }
  }

  /// 显示特定命令的帮助
  void _showCommandHelp(String commandName) {
    switch (commandName.toLowerCase()) {
      case 'init':
        _showInitHelp();
        break;
      case 'template':
        _showTemplateHelp();
        break;
      case 'generate':
        _showGenerateHelp();
        break;
      case 'validate':
        _showValidateHelp();
        break;
      case 'status':
        _showStatusHelp();
        break;
      case 'clean':
        _showCleanHelp();
        break;
      case 'version':
        _showVersionHelp();
        break;
      default:
        Logger.error('未知命令: $commandName');
        Logger.info('使用 "ming help" 查看可用命令');
        return;
    }
  }

  /// 显示init命令帮助
  void _showInitHelp() {
    print('''
ming init - 初始化Ming Status工作空间

用法:
  ming init [workspace_name] [options]

参数:
  workspace_name    工作空间名称（可选）

选项:
  -n, --name        指定工作空间名称
  -d, --description 指定工作空间描述
  -a, --author      指定默认作者名称 (默认: Ignorant-lu)
  -f, --force       强制初始化，覆盖现有配置

示例:
  ming init                       # 交互式初始化
  ming init my_workspace          # 指定名称初始化
  ming init -n my_workspace -d "我的模块工作空间"
  ming init --force               # 强制重新初始化
''');
  }

  /// 显示template命令帮助
  void _showTemplateHelp() {
    print('''
ming template - 模板管理

用法:
  ming template <subcommand> [arguments]

子命令:
  create <name>     创建新模板
  list              列出所有可用模板
  delete <name>     删除指定模板
  info <name>       显示模板详细信息

示例:
  ming template create basic      # 创建基础模板
  ming template list              # 列出所有模板
  ming template info basic        # 查看模板信息
  ming template delete old_template
''');
  }

  /// 显示generate命令帮助
  void _showGenerateHelp() {
    print('''
ming generate - 使用模板生成模块

用法:
  ming generate <template> <output_path> [options]

参数:
  template      模板名称
  output_path   输出路径

选项:
  --overwrite   覆盖现有文件
  --dry-run     预览生成结果，不实际创建文件

示例:
  ming generate basic ./my_module
  ming generate advanced ./modules/user_service --overwrite
  ming generate widget ./ui/my_widget --dry-run
''');
  }

  /// 显示validate命令帮助
  void _showValidateHelp() {
    print('''
ming validate - 验证模块结构

用法:
  ming validate <module_path> [options]

参数:
  module_path   要验证的模块路径

选项:
  --strict      启用严格模式验证
  --fix         自动修复可修复的问题
  --report      生成详细验证报告

示例:
  ming validate ./my_module
  ming validate ./modules/user_service --strict
  ming validate ./ui/widget --fix --report
''');
  }

  /// 显示status命令帮助
  void _showStatusHelp() {
    print('''
ming status - 显示工作空间状态

用法:
  ming status [options]

选项:
  --detailed    显示详细状态信息
  --json        以JSON格式输出

示例:
  ming status
  ming status --detailed
  ming status --json
''');
  }

  /// 显示clean命令帮助
  void _showCleanHelp() {
    print('''
ming clean - 清理临时文件

用法:
  ming clean [options]

选项:
  --cache       清理缓存文件
  --temp        清理临时文件
  --all         清理所有可清理的文件

示例:
  ming clean
  ming clean --cache
  ming clean --all
''');
  }

  /// 显示version命令帮助
  void _showVersionHelp() {
    print('''
ming version - 显示版本信息

用法:
  ming version [options]

选项:
  --detailed    显示详细版本信息

示例:
  ming version
  ming version --detailed
''');
  }
}

/// 命令信息类
class CommandInfo {
  final String name;
  final String description;
  final String usage;

  const CommandInfo({
    required this.name,
    required this.description,
    required this.usage,
  });
} 