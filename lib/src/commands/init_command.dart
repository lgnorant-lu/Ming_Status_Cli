/*
---------------------------------------------------------------
File name:          init_command.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        初始化命令 (Initialization command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 工作空间初始化命令;
---------------------------------------------------------------
*/

import 'package:path/path.dart' as path;

import 'base_command.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

/// 初始化命令
/// 用于初始化Ming Status工作空间
class InitCommand extends BaseCommand {
  @override
  String get name => 'init';

  @override
  String get description => '初始化Ming Status模块工作空间';

  @override
  String get invocation => 'ming init [workspace_name]';

  InitCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: '工作空间名称',
    );
    
    argParser.addOption(
      'description',
      abbr: 'd',
      help: '工作空间描述',
    );
    
    argParser.addOption(
      'author',
      abbr: 'a',
      help: '默认作者名称',
      defaultsTo: 'Ignorant-lu',
    );
    
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: '强制初始化（覆盖现有配置）',
      negatable: false,
    );
  }

  @override
  Future<int> execute() async {
    Logger.title('Ming Status 工作空间初始化');
    
    // 检查是否已经初始化
    if (configManager.isWorkspaceInitialized() && !(argResults!['force'] as bool)) {
      Logger.warning('工作空间已经初始化');
      Logger.info('如需重新初始化，请使用 --force 参数');
      return 0;
    }
    
    // 获取工作空间配置
    final workspaceName = await _getWorkspaceName();
    final description = await _getDescription();
    final author = await _getAuthor();
    
    // 显示配置信息
    Logger.subtitle('工作空间配置');
    Logger.keyValue('名称', workspaceName);
    Logger.keyValue('描述', description);
    Logger.keyValue('作者', author);
    Logger.keyValue('路径', workingDirectory);
    Logger.newLine();
    
    // 确认初始化
    if (!quiet && !confirmAction('确认初始化工作空间？', defaultValue: true)) {
      Logger.info('初始化已取消');
      return 0;
    }
    
    // 执行初始化
    Logger.progress('正在初始化工作空间...');
    
    final success = await configManager.initializeWorkspace(
      workspaceName: workspaceName,
      description: description,
      author: author,
    );
    
    if (success) {
      Logger.complete('工作空间初始化成功！');
      Logger.newLine();
      
      // 显示后续操作建议
      _showNextSteps();
      
      return 0;
    } else {
      Logger.error('工作空间初始化失败');
      return 1;
    }
  }

  /// 获取工作空间名称
  Future<String> _getWorkspaceName() async {
    // 首先尝试从命令行参数获取
    if (argResults!.rest.isNotEmpty) {
      final name = argResults!.rest.first;
      if (_isValidWorkspaceName(name)) {
        return name;
      } else {
        Logger.warning('工作空间名称格式无效: $name');
      }
    }
    
    // 从选项获取
    if (argResults!['name'] != null) {
      final name = argResults!['name'] as String;
      if (_isValidWorkspaceName(name)) {
        return name;
      } else {
        Logger.warning('工作空间名称格式无效: $name');
      }
    }
    
    // 交互式获取
    final defaultName = path.basename(workingDirectory);
    
    while (true) {
      final name = getUserInput(
        '请输入工作空间名称',
        defaultValue: defaultName,
        required: true,
      );
      
      if (name != null && _isValidWorkspaceName(name)) {
        return name;
      }
      
      Logger.error('工作空间名称必须是有效的包名格式（小写字母、数字、下划线）');
    }
  }

  /// 获取工作空间描述
  Future<String> _getDescription() async {
    if (argResults!['description'] != null) {
      return argResults!['description'] as String;
    }
    
    return getUserInput(
      '请输入工作空间描述',
      defaultValue: 'Ming Status模块工作空间',
    ) ?? 'Ming Status模块工作空间';
  }

  /// 获取作者名称
  Future<String> _getAuthor() async {
    if (argResults!['author'] != null) {
      return argResults!['author'] as String;
    }
    
    return getUserInput(
      '请输入默认作者名称',
      defaultValue: 'Ignorant-lu',
    ) ?? 'Ignorant-lu';
  }

  /// 验证工作空间名称格式
  bool _isValidWorkspaceName(String name) {
    if (name.isEmpty) return false;
    
    // 基本格式检查
    if (!StringUtils.isValidPackageName(name)) {
      return false;
    }
    
    // 长度检查
    if (name.length < 2 || name.length > 50) {
      return false;
    }
    
    return true;
  }

  /// 显示后续操作建议
  void _showNextSteps() {
    Logger.subtitle('后续操作建议');
    Logger.listItem('查看可用命令: ming --help');
    Logger.listItem('创建模板: ming template create <template_name>');
    Logger.listItem('生成模块: ming generate <template_name> <output_path>');
    Logger.listItem('验证模块: ming validate <module_path>');
    Logger.newLine();
    
    Logger.info('工作空间已就绪，现在可以开始创建和管理模块了！');
  }
} 