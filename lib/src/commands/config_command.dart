/*
---------------------------------------------------------------
File name:          config_command.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        配置管理命令 (Configuration management command)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 配置管理命令实现;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/commands/base_command.dart';
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
      );
  }

  @override
  String get name => 'config';

  @override
  String get description => '管理Ming Status CLI配置';

  @override
  String get usageFooter => '''
示例:
  ming config --list                    # 列出所有配置
  ming config --global --list           # 列出全局用户配置
  ming config --get user.name           # 获取用户名
  ming config --set user.name="张三"     # 设置用户名
  ming config --global --set user.email="zhang@example.com"  # 设置邮箱
  ming config --reset                   # 重置配置
  ming config --template enterprise     # 应用企业级配置模板
  
配置键路径:
  user.name, user.email, user.company
  preferences.defaultTemplate, preferences.coloredOutput
  preferences.autoUpdateCheck, preferences.verboseLogging
  preferences.preferredIde
  defaults.author, defaults.license, defaults.dartVersion
  defaults.description''';

  late final UserConfigManager _userConfigManager;
  late final ConfigManager _configManager;

  @override
  Future<int> execute() async {
    try {
      _userConfigManager = UserConfigManager();
      _configManager = ConfigManager();

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
}
