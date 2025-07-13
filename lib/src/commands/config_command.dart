/*
---------------------------------------------------------------
File name:          config_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        配置管理命令 (Configuration management command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置管理命令实现;
    2025/07/13: Feature enhancement - 添加配置模板和交互式向导功能;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/commands/base_command.dart';
import 'package:ming_status_cli/src/core/config/app_config.dart';
import 'package:ming_status_cli/src/core/config_management/config_manager.dart';
import 'package:ming_status_cli/src/core/config_management/user_config_manager.dart';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 配置管理命令
///
/// 提供完整的配置管理功能，支持全局用户配置和本地工作空间配置：
///
/// **支持的操作**：
/// - 列出配置：`--list` 显示所有配置项
/// - 获取配置：`--get key` 获取指定配置项的值
/// - 设置配置：`--set key=value` 设置配置项的值
/// - 重置配置：`--reset` 重置配置为默认值
/// - 编辑配置：`--edit` 获取配置文件路径用于手动编辑
/// - 配置模板：`--template basic|enterprise` 应用预设配置模板
///
/// **配置作用域**：
/// - 全局配置：`--global` 操作用户级配置，影响所有项目
/// - 本地配置：`--local` 操作当前工作空间配置（仅读取）
///
/// **配置层次结构**：
/// - `user.*`: 用户信息 (name, email, company)
/// - `preferences.*`: 用户偏好 (defaultTemplate, coloredOutput, autoUpdateCheck等)
/// - `defaults.*`: 默认值 (author, license, dartVersion, description)
/// - `security.*`: 安全设置 (加密、访问控制等)
///
/// **使用示例**：
/// ```bash
/// # 查看所有配置
/// ming config --list
///
/// # 设置用户信息
/// ming config --global --set user.name="张三"
/// ming config --global --set user.email="zhang@example.com"
///
/// # 应用企业级配置模板
/// ming config --template enterprise
///
/// # 获取特定配置
/// ming config --get user.name
/// ```
///
/// 集成UserConfigManager和ConfigManager，提供统一的配置管理体验。
class ConfigCommand extends BaseCommand {
  /// 创建配置命令实例，初始化命令参数
  ConfigCommand() {
    argParser
      // 配置操作选项
      ..addFlag(
        'list',
        abbr: 'l',
        help: '列出所有配置项',
        negatable: false,
      )
      ..addFlag(
        'global',
        abbr: 'g',
        help: '操作全局用户配置',
        negatable: false,
      )
      ..addFlag(
        'local',
        help: '操作本地工作空间配置',
        negatable: false,
      )
      ..addOption(
        'get',
        help: '获取指定配置项的值',
        valueHelp: 'key',
      )
      ..addOption(
        'set',
        help: '设置配置项的值',
        valueHelp: 'key=value',
      )
      ..addFlag(
        'unset',
        help: '删除指定配置项',
        negatable: false,
      )
      ..addFlag(
        'reset',
        help: '重置配置为默认值',
        negatable: false,
      )
      ..addFlag(
        'edit',
        help: '在编辑器中打开配置文件',
        negatable: false,
      )
      // 配置模板选项
      ..addOption(
        'template',
        help: '应用配置模板',
        valueHelp: 'basic|enterprise',
        allowed: ['basic', 'enterprise'],
      )
      // 交互式向导选项
      ..addFlag(
        'wizard',
        abbr: 'w',
        help: '启动交互式配置向导',
        negatable: false,
      )
      ..addFlag(
        'quick-setup',
        help: '快速设置常用配置项',
        negatable: false,
      );
  }

  @override
  String get name => 'config';

  @override
  String get description => '管理Ming Status CLI配置';

  @override
  String get usage => '''
管理Ming Status CLI配置

使用方法:
  ming config [选项]

基础选项:
  -l, --list             列出所有配置项
  -g, --global           操作全局用户配置
      --local            操作本地工作空间配置
      --get=<键>         获取指定配置项的值
      --set=<键=值>      设置配置项的值
      --unset            删除指定配置项
      --reset            重置配置为默认值
      --edit             在编辑器中打开配置文件

模板选项:
      --template=<类型>  应用配置模板 (允许: basic, enterprise)

交互式选项:
  -w, --wizard           启动交互式配置向导
      --quick-setup      快速设置常用配置项

示例:
  # 列出所有配置
  ming config --list

  # 列出全局用户配置
  ming config --global --list

  # 获取用户名
  ming config --get=user.name

  # 设置用户信息
  ming config --global --set=user.name="张三"
  ming config --global --set=user.email="zhang@example.com"

  # 应用企业级配置模板
  ming config --template=enterprise

  # 启动交互式配置向导
  ming config --wizard

  # 快速设置用户信息
  ming config --quick-setup

  # 重置配置
  ming config --global --reset

注意:
  • 配置向导会根据您的使用习惯提供智能建议
  • 快速设置适合首次使用或快速配置场景
  • 使用 --verbose 选项可获得更详细的配置说明

配置键路径:
  user.name, user.email, user.company
  preferences.defaultTemplate, preferences.coloredOutput
  preferences.autoUpdateCheck, preferences.verboseLogging
  preferences.preferredIde
  defaults.author, defaults.license, defaults.dartVersion
  defaults.description

更多信息:
  使用 'ming help config' 查看详细文档
''';

  late final UserConfigManager _userConfigManager;
  late final ConfigManager _configManager;

  @override
  Future<int> execute() async {
    try {
      _userConfigManager = UserConfigManager();
      _configManager = ConfigManager();

      // 处理交互式向导
      if (argResults?['wizard'] == true) {
        return await _handleWizardCommand();
      }

      // 处理快速设置
      if (argResults?['quick-setup'] == true) {
        return await _handleQuickSetupCommand();
      }

      // 处理配置模板应用
      if (argResults?['template'] != null) {
        return await _handleTemplateCommand();
      }

      // 处理列出配置
      if (argResults?['list'] == true) {
        return await _handleListCommand();
      }

      // 处理获取配置
      if (argResults?['get'] != null) {
        return await _handleGetCommand();
      }

      // 处理设置配置
      if (argResults?['set'] != null) {
        return await _handleSetCommand();
      }

      // 处理重置配置
      if (argResults?['reset'] == true) {
        return await _handleResetCommand();
      }

      // 处理编辑配置
      if (argResults?['edit'] == true) {
        return await _handleEditCommand();
      }

      // 如果没有指定操作，显示帮助
      Logger.info('请指定要执行的配置操作');
      Logger.info(usage);
      return 1;
    } catch (e) {
      Logger.error('配置命令执行失败', error: e);
      return 1;
    }
  }

  /// 处理配置模板应用
  Future<int> _handleTemplateCommand() async {
    try {
      final templateType = argResults?['template'] as String;
      Logger.info('正在应用配置模板: $templateType');

      final success = await _configManager.applyConfigTemplate(templateType);
      if (success) {
        Logger.success('配置模板应用成功: $templateType');
        return 0;
      } else {
        Logger.error('配置模板应用失败');
        return 1;
      }
    } catch (e) {
      Logger.error('应用配置模板异常', error: e);
      return 1;
    }
  }

  /// 处理列出配置
  Future<int> _handleListCommand() async {
    try {
      final isGlobal = argResults?['global'] == true;
      final isLocal = argResults?['local'] == true;

      if (isGlobal || (!isLocal && !isGlobal)) {
        // 显示用户全局配置
        Logger.info('=== 用户全局配置 ===');
        final userConfig = await _userConfigManager.listAllConfig();

        if (userConfig.isEmpty) {
          Logger.warning('用户配置未初始化');
        } else {
          _printConfigSection('user', userConfig['user']);
          _printConfigSection('preferences', userConfig['preferences']);
          _printConfigSection('defaults', userConfig['defaults']);
          if (userConfig.containsKey('security')) {
            _printConfigSection('security', userConfig['security']);
          }
        }
      }

      if (isLocal || (!isLocal && !isGlobal)) {
        // 显示工作空间配置
        Logger.info('\n=== 工作空间配置 ===');
        final workspaceConfig = await _configManager.loadWorkspaceConfig();

        if (workspaceConfig == null) {
          Logger.warning('工作空间配置未初始化');
        } else {
          final configData = workspaceConfig.toJson();
          _printConfigSection('workspace', configData['workspace']);
          _printConfigSection('templates', configData['templates']);
          _printConfigSection('defaults', configData['defaults']);
          _printConfigSection('validation', configData['validation']);

          if (configData.containsKey('environments')) {
            Logger.info('\n📋 environments:');
            final environments =
                configData['environments'] as Map<String, dynamic>?;
            environments?.forEach((key, value) {
              Logger.info('  $key:');
              if (value is Map<String, dynamic>) {
                value.forEach((k, v) {
                  Logger.info('    $k: $v');
                });
              }
            });
          }
        }
      }

      return 0;
    } catch (e) {
      Logger.error('列出配置失败', error: e);
      return 1;
    }
  }

  /// 处理获取配置
  Future<int> _handleGetCommand() async {
    try {
      final key = argResults?['get'] as String;
      final isGlobal = argResults?['global'] == true;

      String? value;
      if (isGlobal) {
        value = await _userConfigManager.getConfigValue(key);
      } else {
        // 尝试从工作空间配置获取
        final workspaceConfig = await _configManager.loadWorkspaceConfig();
        if (workspaceConfig != null) {
          final configData = workspaceConfig.toJson();
          value = _getValueFromPath(configData, key);
        }
      }

      if (value != null) {
        Logger.info('$key = $value');
        return 0;
      } else {
        Logger.warning('配置项不存在: $key');
        return 1;
      }
    } catch (e) {
      Logger.error('获取配置失败', error: e);
      return 1;
    }
  }

  /// 处理设置配置
  Future<int> _handleSetCommand() async {
    try {
      final setValue = argResults?['set'] as String;
      final parts = setValue.split('=');

      if (parts.length != 2) {
        Logger.error('设置配置格式错误，应为: key=value');
        return 1;
      }

      final key = parts[0].trim();
      final value = parts[1].trim();
      final isGlobal = argResults?['global'] == true;

      var success = false;
      if (isGlobal) {
        success = await _userConfigManager.setConfigValue(key, value);
      } else {
        Logger.warning('当前版本暂不支持设置工作空间配置，请使用 --global 设置用户配置');
        return 1;
      }

      if (success) {
        Logger.success('配置设置成功: $key = $value');
        return 0;
      } else {
        Logger.error('配置设置失败');
        return 1;
      }
    } catch (e) {
      Logger.error('设置配置失败', error: e);
      return 1;
    }
  }

  /// 处理重置配置
  Future<int> _handleResetCommand() async {
    try {
      final isGlobal = argResults?['global'] == true;

      if (isGlobal) {
        final success = await _userConfigManager.resetUserConfig();
        if (success) {
          Logger.success('用户配置已重置为默认值');
          return 0;
        } else {
          Logger.error('重置用户配置失败');
          return 1;
        }
      } else {
        Logger.warning('重置工作空间配置暂不支持，请使用 --global 重置用户配置');
        return 1;
      }
    } catch (e) {
      Logger.error('重置配置失败', error: e);
      return 1;
    }
  }

  /// 处理编辑配置
  Future<int> _handleEditCommand() async {
    try {
      final isGlobal = argResults?['global'] == true;

      String configFile;
      if (isGlobal) {
        configFile = _userConfigManager.userConfigFilePath;
      } else {
        configFile = _configManager.configFilePath;
      }

      Logger.info('配置文件路径: $configFile');
      Logger.info('请手动在编辑器中打开此文件进行编辑');

      return 0;
    } catch (e) {
      Logger.error('获取配置文件路径失败', error: e);
      return 1;
    }
  }

  /// 打印配置节
  void _printConfigSection(String section, dynamic data) {
    if (data == null) return;

    Logger.info('\n📋 $section:');
    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          Logger.info('  $key:');
          value.forEach((k, v) {
            Logger.info('    $k: $v');
          });
        } else {
          Logger.info('  $key: $value');
        }
      });
    } else {
      // 尝试调用toJson方法获取对象的详细信息
      try {
        final jsonData = (data as dynamic).toJson();
        if (jsonData is Map<String, dynamic>) {
          jsonData.forEach((key, value) {
            Logger.info('  $key: $value');
          });
        } else {
          Logger.info('  $data');
        }
      } catch (e) {
        // 如果没有toJson方法，显示对象类型提示
        Logger.info('  ${data.runtimeType} (详细信息需要调用--get查看具体字段)');
      }
    }
  }

  /// 从配置路径获取值
  String? _getValueFromPath(Map<String, dynamic> config, String path) {
    final keys = path.split('.');
    dynamic value = config;

    for (final key in keys) {
      if (value is Map<String, dynamic> && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }

    return value?.toString();
  }

  /// 处理交互式配置向导
  Future<int> _handleWizardCommand() async {
    try {
      Logger.title('🧙‍♂️ 配置向导');
      Logger.info('欢迎使用 Ming Status CLI 配置向导！');
      Logger.info('我将帮助您设置常用的配置项。');
      Logger.newLine();

      // 获取当前配置
      final config = await _userConfigManager.loadUserConfig();

      // 用户信息配置
      Logger.subtitle('👤 用户信息');
      final defaultAuthor =
          await AppConfig.instance.getString('app.author', defaultValue: '');
      final userName = getUserInput(
        '请输入您的姓名',
        defaultValue: config?.user.name ?? defaultAuthor,
      );

      final userEmail = getUserInput(
        '请输入您的邮箱',
        defaultValue: config?.user.email ?? '',
      );

      final userCompany = getUserInput(
        '请输入您的公司/组织 (可选)',
        defaultValue: config?.user.company ?? '',
      );

      // 默认值配置
      Logger.newLine();
      Logger.subtitle('⚙️ 默认设置');

      final defaultLicense = getUserInput(
        '默认许可证类型',
        defaultValue: config?.defaults.license ?? 'MIT',
      );

      final defaultDartVersion = getUserInput(
        '默认 Dart 版本',
        defaultValue: config?.defaults.dartVersion ?? '^3.2.0',
      );

      // 偏好设置
      Logger.newLine();
      Logger.subtitle('🎨 偏好设置');

      final coloredOutput = confirmAction(
        '启用彩色输出？',
        defaultValue: config?.preferences.coloredOutput ?? true,
      );

      final autoUpdateCheck = confirmAction(
        '启用自动更新检查？',
        defaultValue: config?.preferences.autoUpdateCheck ?? true,
      );

      // 应用配置
      Logger.newLine();
      Logger.info('正在保存配置...');

      final success = await _userConfigManager.initializeUserConfig(
        userName: userName,
        userEmail: userEmail,
        company: userCompany,
      );

      if (success) {
        // 更新其他配置项
        if (defaultLicense != null) {
          await _userConfigManager.setConfigValue(
            'defaults.license',
            defaultLicense,
          );
        }
        if (defaultDartVersion != null) {
          await _userConfigManager.setConfigValue(
            'defaults.dartVersion',
            defaultDartVersion,
          );
        }
        await _userConfigManager.setConfigValue(
          'preferences.coloredOutput',
          coloredOutput.toString(),
        );
        await _userConfigManager.setConfigValue(
          'preferences.autoUpdateCheck',
          autoUpdateCheck.toString(),
        );

        Logger.success('✅ 配置向导完成！');
        Logger.info('您可以随时使用 "ming config --list" 查看配置');
        Logger.info('使用 "ming config --set key=value" 修改配置');
        return 0;
      } else {
        Logger.error('配置保存失败');
        return 1;
      }
    } catch (e) {
      Logger.error('配置向导执行失败: $e');
      return 1;
    }
  }

  /// 处理快速设置
  Future<int> _handleQuickSetupCommand() async {
    try {
      Logger.title('⚡ 快速设置');
      Logger.info('快速设置最常用的配置项');
      Logger.newLine();

      // 获取当前配置
      final config = await _userConfigManager.loadUserConfig();

      // 快速设置用户名
      final userName = getUserInput(
        '用户名',
        defaultValue: config?.user.name ??
            await AppConfig.instance.getString('app.author', defaultValue: ''),
        required: true,
      );

      // 快速设置邮箱
      final userEmail = getUserInput(
        '邮箱',
        defaultValue: config?.user.email ?? '',
      );

      // 应用设置
      if (userName != null) {
        await _userConfigManager.setConfigValue('user.name', userName);
        await _userConfigManager.setConfigValue('defaults.author', userName);
      }

      if (userEmail != null && userEmail.isNotEmpty) {
        await _userConfigManager.setConfigValue('user.email', userEmail);
      }

      Logger.success('✅ 快速设置完成！');
      Logger.info('使用 "ming config --wizard" 进行完整配置');
      return 0;
    } catch (e) {
      Logger.error('快速设置失败: $e');
      return 1;
    }
  }
}
