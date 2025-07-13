/*
---------------------------------------------------------------
File name:          init_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        初始化命令 (Initialization command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 工作空间初始化命令;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/config/app_config.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/utils/progress_manager.dart';
import 'package:ming_status_cli/src/utils/string_utils.dart';
import 'package:path/path.dart' as path;

/// 初始化命令
/// 用于初始化Ming Status工作空间
class InitCommand extends BaseCommand {
  /// 创建初始化命令实例，设置命令行参数配置
  InitCommand() {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: '工作空间名称',
      )
      ..addOption(
        'description',
        abbr: 'd',
        help: '工作空间描述',
      )
      ..addOption(
        'author',
        abbr: 'a',
        help: '默认作者名称',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: '强制初始化（覆盖现有配置）',
        negatable: false,
      );
  }
  @override
  String get name => 'init';

  @override
  String get description => '初始化Ming Status模块工作空间';

  @override
  String get invocation => 'ming init [workspace_name]';

  @override
  String get usage => '''
初始化Ming Status模块工作空间

使用方法:
  ming init [工作空间名称] [选项]

参数:
  [工作空间名称]         要创建的工作空间名称 (可选)

选项:
  -n, --name=<名称>      工作空间名称
  -d, --description=<描述> 工作空间描述
  -a, --author=<作者>    默认作者名称 (默认: lgnorant-lu)
  -f, --force            强制初始化，覆盖现有配置

初始化内容:
  • 创建工作空间配置文件 (ming_workspace.yaml)
  • 建立标准目录结构 (src/, tests/, docs/)
  • 生成示例文件和文档 (README.md)
  • 配置默认设置和模板

示例:
  # 基础初始化
  ming init

  # 指定工作空间名称
  ming init my_project

  # 完整配置初始化
  ming init --name="我的项目" --author="开发者" --description="项目描述"

  # 强制重新初始化
  ming init --force

  # 非交互模式初始化
  ming init my_project --author="Developer" --description="My workspace"

注意事项:
  • 确保当前目录有写权限
  • 工作空间名称应符合包命名规范 (小写字母、数字、下划线)
  • 使用 --force 会覆盖现有配置

更多信息:
  使用 'ming help init' 查看详细文档
''';

  @override
  Future<int> execute() async {
    // 检查是否已经初始化
    if (configManager.isWorkspaceInitialized() &&
        !(argResults!['force'] as bool)) {
      Logger.warning('工作空间已经初始化');
      Logger.info('如需重新初始化，请使用 --force 参数');
      return 0;
    }

    // 创建进度管理器并添加初始化任务
    final progress = ProgressManager()
      ..addTasks([
        {
          'id': 'config_gathering',
          'name': '收集配置信息',
          'description': '获取工作空间名称、描述和作者信息',
        },
        {
          'id': 'config_validation',
          'name': '验证配置',
          'description': '验证工作空间配置的有效性',
        },
        {
          'id': 'user_confirmation',
          'name': '用户确认',
          'description': '显示配置信息并确认初始化',
        },
        {
          'id': 'workspace_creation',
          'name': '创建工作空间',
          'description': '创建目录结构和配置文件',
        },
        {
          'id': 'finalization',
          'name': '完成初始化',
          'description': '生成示例文件和文档',
        },
      ])
      ..start(title: 'Ming Status 工作空间初始化');

    try {
      // 步骤1：收集配置信息
      final configData = await progress.executeTask(() async {
        final workspaceName = await _getWorkspaceName();
        final description = await _getDescription();
        final author = await _getAuthor();

        return {
          'workspaceName': workspaceName,
          'description': description,
          'author': author,
        };
      });

      // 步骤2：验证配置
      await progress.executeTask(() async {
        final workspaceName = configData['workspaceName']!;
        if (!_isValidWorkspaceName(workspaceName)) {
          throw Exception('工作空间名称格式无效: $workspaceName');
        }

        // 检查目录权限
        if (!await _checkDirectoryPermissions()) {
          throw Exception('目录权限不足，无法创建工作空间');
        }
      });

      // 步骤3：用户确认
      final confirmed = await progress.executeTask(() async {
        // 显示配置信息
        Logger.newLine();
        Logger.subtitle('工作空间配置');
        Logger.keyValue('名称', configData['workspaceName']!);
        Logger.keyValue('描述', configData['description']!);
        Logger.keyValue('作者', configData['author']!);
        Logger.keyValue('路径', workingDirectory);
        Logger.newLine();

        // 确认初始化
        if (!quiet) {
          return confirmAction('确认初始化工作空间？', defaultValue: true);
        }
        return true;
      });

      if (!confirmed) {
        Logger.info('初始化已取消');
        return 0;
      }

      // 步骤4：创建工作空间
      final workspaceSuccess = await progress.executeTask(() async {
        return configManager.initializeWorkspace(
          workspaceName: configData['workspaceName']!,
          description: configData['description'],
          author: configData['author'],
        );
      });

      if (!workspaceSuccess) {
        throw Exception('工作空间初始化失败');
      }

      // 步骤5：完成初始化
      await progress.executeTask(() async {
        // 创建示例目录和文件
        await _createSampleStructure();
        return true;
      });

      // 完成进度跟踪
      progress.complete(
        summary: '工作空间初始化成功完成！',
      );

      // 显示后续操作建议
      _showNextSteps();

      return 0;
    } catch (e) {
      Logger.error('初始化过程中发生错误: $e');
      return 1;
    }
  }

  /// 检查目录权限
  Future<bool> _checkDirectoryPermissions() async {
    try {
      // 尝试在当前目录创建临时文件以测试权限
      final testFile = File('$workingDirectory/.ming_test_permissions');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 创建示例结构
  Future<void> _createSampleStructure() async {
    // 这里可以创建一些示例目录和文件
    // 例如：src/, tests/, docs/ 等
    try {
      final srcDir = Directory('$workingDirectory/src');
      if (!srcDir.existsSync()) {
        srcDir.createSync(recursive: true);
      }

      final testsDir = Directory('$workingDirectory/tests');
      if (!testsDir.existsSync()) {
        testsDir.createSync(recursive: true);
      }

      final docsDir = Directory('$workingDirectory/docs');
      if (!docsDir.existsSync()) {
        docsDir.createSync(recursive: true);
      }

      // 创建README.md
      final readmeFile = File('$workingDirectory/README.md');
      if (!readmeFile.existsSync()) {
        await readmeFile.writeAsString('''
# ${path.basename(workingDirectory)}

这是一个使用 Ming Status CLI 创建的模块化项目。

## 项目结构

- `src/` - 源代码目录
- `tests/` - 测试代码目录  
- `docs/` - 文档目录
- `.ming/` - Ming Status CLI 配置目录

## 快速开始

1. 查看可用命令：`ming help`
2. 检查环境状态：`ming doctor`
3. 创建新模块：`ming generate <template> <path>`

''');
      }
    } catch (e) {
      // 创建示例结构失败不应该影响整体初始化
      Logger.warning('创建示例结构时出现问题: $e');
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

    final defaultDescription = await AppConfig.instance
        .getString('defaults.description', defaultValue: 'Ming Status模块工作空间');

    return getUserInput(
          '请输入工作空间描述',
          defaultValue: defaultDescription,
        ) ??
        defaultDescription;
  }

  /// 获取作者名称
  Future<String> _getAuthor() async {
    if (argResults!['author'] != null) {
      return argResults!['author'] as String;
    }

    final defaultAuthor = await AppConfig.instance
        .getString('app.author', defaultValue: 'lgnorant-lu');

    return getUserInput(
          '请输入默认作者名称',
          defaultValue: defaultAuthor,
        ) ??
        defaultAuthor;
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
