/*
---------------------------------------------------------------
File name:          user_config_manager.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        用户配置管理器 (User configuration manager)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 用户全局配置管理功能;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/models/user_config.dart';
import 'package:ming_status_cli/src/models/workspace_config.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 用户配置管理器
/// 负责用户全局配置的加载、保存和管理
class UserConfigManager {
  /// 创建用户配置管理器实例
  UserConfigManager();

  /// 用户配置目录名
  static const String userConfigDirName = '.ming';

  /// 用户配置文件名
  static const String userConfigFileName = 'config.json';

  /// 缓存的用户配置
  UserConfig? _cachedUserConfig;

  /// 获取用户配置目录路径
  String get userConfigDir {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return path.join(homeDir, userConfigDirName);
  }

  /// 获取用户配置文件路径
  String get userConfigFilePath => path.join(userConfigDir, userConfigFileName);

  /// 检查用户配置是否已初始化
  bool isUserConfigInitialized() {
    return FileUtils.fileExists(userConfigFilePath);
  }

  /// 初始化用户配置目录和文件
  Future<bool> initializeUserConfig({
    String? userName,
    String? userEmail,
    String? company,
  }) async {
    try {
      Logger.info('正在初始化用户配置目录: $userConfigDir');

      // 创建用户配置目录
      await FileUtils.createDirectory(userConfigDir);

      // 创建默认用户配置
      final config = UserConfig.defaultConfig().copyWith(
        user: UserInfo(
          name: userName ?? '开发者名称',
          email: userEmail ?? '',
          company: company ?? '',
        ),
        defaults: UserDefaults(
          author: userName ?? '开发者名称',
          license: 'MIT',
          dartVersion: '^3.2.0',
        ),
      );

      // 保存配置文件
      final success = await saveUserConfig(config);
      if (success) {
        Logger.success('用户配置初始化成功');
        _cachedUserConfig = config;

        // 创建其他相关目录
        await _createUserDirectoryStructure();

        return true;
      } else {
        Logger.error('用户配置初始化失败：无法保存配置文件');
        return false;
      }
    } catch (e) {
      Logger.error('用户配置初始化异常', error: e);
      return false;
    }
  }

  /// 加载用户配置
  Future<UserConfig?> loadUserConfig({bool useCache = true}) async {
    try {
      // 使用缓存
      if (useCache && _cachedUserConfig != null) {
        return _cachedUserConfig;
      }

      // 检查配置文件是否存在
      if (!FileUtils.fileExists(userConfigFilePath)) {
        Logger.debug('用户配置文件不存在，将使用默认配置');
        // 自动创建默认配置
        await initializeUserConfig();
        return _cachedUserConfig;
      }

      // 读取JSON文件
      final jsonString = await FileUtils.readFileAsString(userConfigFilePath);
      if (jsonString == null) {
        Logger.error('无法读取用户配置文件，使用默认配置');
        return UserConfig.defaultConfig();
      }

      // 解析JSON并转换为配置对象
      try {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>?;
        final config = UserConfig.fromJson(jsonData);
        _cachedUserConfig = config;

        Logger.debug('用户配置加载成功');
        return config;
      } catch (parseError) {
        Logger.error('用户配置文件损坏，使用默认配置', error: parseError);
        // 配置文件损坏时，返回默认配置而不是null
        final defaultConfig = UserConfig.defaultConfig();
        _cachedUserConfig = defaultConfig;
        return defaultConfig;
      }
    } catch (e) {
      Logger.error('加载用户配置失败，使用默认配置', error: e);
      // 任何其他错误也使用默认配置
      final defaultConfig = UserConfig.defaultConfig();
      _cachedUserConfig = defaultConfig;
      return defaultConfig;
    }
  }

  /// 保存用户配置
  Future<bool> saveUserConfig(UserConfig config) async {
    try {
      // 确保配置目录存在
      await FileUtils.createDirectory(userConfigDir);

      // 转换为JSON字符串
      final jsonData = config.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // 保存到文件
      final success =
          await FileUtils.writeFileAsString(userConfigFilePath, jsonString);
      if (success) {
        _cachedUserConfig = config;
        Logger.debug('用户配置保存成功');
        return true;
      } else {
        Logger.error('保存用户配置失败');
        return false;
      }
    } catch (e) {
      Logger.error('保存用户配置异常', error: e);
      return false;
    }
  }

  /// 更新用户配置
  Future<bool> updateUserConfig(UserConfig Function(UserConfig) updater) async {
    try {
      final currentConfig = await loadUserConfig();
      if (currentConfig == null) {
        Logger.error('无法加载当前用户配置进行更新');
        return false;
      }

      final updatedConfig = updater(currentConfig);
      return await saveUserConfig(updatedConfig);
    } catch (e) {
      Logger.error('更新用户配置异常', error: e);
      return false;
    }
  }

  /// 获取配置值
  Future<String?> getConfigValue(String key) async {
    try {
      final config = await loadUserConfig();
      if (config == null) return null;

      final keys = key.split('.');
      if (keys.isEmpty) return null;

      dynamic value = config;

      for (final k in keys) {
        if (value == null) return null;

        // 处理不同类型的值
        if (value is Map<String, dynamic>) {
          value = value.containsKey(k) ? value[k] : null;
        } else if (value is UserConfig) {
          switch (k) {
            case 'user':
              value = value.user;
            case 'preferences':
              value = value.preferences;
            case 'defaults':
              value = value.defaults;
            case 'integrations':
              value = value.integrations;
            case 'security':
              value = value.security;
            default:
              // 如果不匹配预定义字段，尝试从integrations中查找
              if (value.integrations != null &&
                  value.integrations!.containsKey(key)) {
                return value.integrations![key]?.toString();
              }
              return null;
          }
        } else if (value is UserInfo) {
          switch (k) {
            case 'name':
              value = value.name;
            case 'email':
              value = value.email;
            case 'company':
              value = value.company;
            default:
              return null;
          }
        } else if (value is UserPreferences) {
          switch (k) {
            case 'defaultTemplate':
              value = value.defaultTemplate;
            case 'coloredOutput':
              value = value.coloredOutput;
            case 'autoUpdateCheck':
              value = value.autoUpdateCheck;
            case 'verboseLogging':
              value = value.verboseLogging;
            case 'preferredIde':
              value = value.preferredIde;
            default:
              return null;
          }
        } else if (value is UserDefaults) {
          switch (k) {
            case 'author':
              value = value.author;
            case 'license':
              value = value.license;
            case 'dartVersion':
              value = value.dartVersion;
            case 'description':
              value = value.description;
            default:
              return null;
          }
        } else if (value is SecuritySettings) {
          switch (k) {
            case 'encryptedCredentials':
              value = value.encryptedCredentials;
            case 'strictPermissions':
              value = value.strictPermissions;
            default:
              return null;
          }
        } else if (value is Map<String, dynamic>) {
          // 处理integrations或其他Map类型
          value = value.containsKey(k) ? value[k] : null;
        } else {
          // 对于其他类型，尝试使用反射或toJson
          if (value.runtimeType.toString().startsWith('_')) {
            // 可能是内部类型，无法处理
            return null;
          }

          // 尝试调用toJson方法
          try {
            final json = (value as dynamic).toJson();
            if (json is Map<String, dynamic> && json.containsKey(k)) {
              value = json[k];
            } else {
              return null;
            }
          } catch (_) {
            return null;
          }
        }
      }

      return value?.toString();
    } catch (e) {
      Logger.error('获取配置值失败', error: e);
      return null;
    }
  }

  /// 设置配置值
  Future<bool> setConfigValue(String key, String value) async {
    try {
      final config = await loadUserConfig();
      if (config == null) return false;

      final keys = key.split('.');
      if (keys.isEmpty || keys.length < 2) return false;

      UserConfig? updatedConfig;

      // 根据键路径更新配置
      switch (keys[0]) {
        case 'user':
          final userInfo = config.user;
          switch (keys[1]) {
            case 'name':
              updatedConfig = config.copyWith(
                user: userInfo.copyWith(name: value),
              );
            case 'email':
              updatedConfig = config.copyWith(
                user: userInfo.copyWith(email: value),
              );
            case 'company':
              updatedConfig = config.copyWith(
                user: userInfo.copyWith(company: value),
              );
            default:
              return false; // 无效的用户字段
          }
        case 'preferences':
          final prefs = config.preferences;
          switch (keys[1]) {
            case 'defaultTemplate':
              updatedConfig = config.copyWith(
                preferences: prefs.copyWith(defaultTemplate: value),
              );
            case 'coloredOutput':
              updatedConfig = config.copyWith(
                preferences: prefs.copyWith(
                    coloredOutput: value.toLowerCase() == 'true',),
              );
            case 'autoUpdateCheck':
              updatedConfig = config.copyWith(
                preferences: prefs.copyWith(
                    autoUpdateCheck: value.toLowerCase() == 'true',),
              );
            case 'verboseLogging':
              updatedConfig = config.copyWith(
                preferences: prefs.copyWith(
                    verboseLogging: value.toLowerCase() == 'true',),
              );
            case 'preferredIde':
              updatedConfig = config.copyWith(
                preferences: prefs.copyWith(preferredIde: value),
              );
            default:
              return false; // 无效的偏好字段
          }
        case 'defaults':
          final defaults = config.defaults;
          switch (keys[1]) {
            case 'author':
              updatedConfig = config.copyWith(
                defaults: defaults.copyWith(author: value),
              );
            case 'license':
              updatedConfig = config.copyWith(
                defaults: defaults.copyWith(license: value),
              );
            case 'dartVersion':
              updatedConfig = config.copyWith(
                defaults: defaults.copyWith(dartVersion: value),
              );
            case 'description':
              updatedConfig = config.copyWith(
                defaults: defaults.copyWith(description: value),
              );
            default:
              return false; // 无效的默认值字段
          }
        default:
          // 验证键路径格式 - 只有有效的顶级键才被接受
          if (keys.length < 2 ||
              keys.length > 10 ||
              key.contains('..') ||
              key.isEmpty ||
              key.startsWith('.') ||
              key.endsWith('.') ||
              !['user', 'preferences', 'defaults', 'security', 'integrations']
                  .contains(keys[0])) {
            return false; // 无效的键路径格式
          }

          // 检查是否有空的键部分
          if (keys.any((k) => k.isEmpty)) {
            return false;
          }

          // 对于integrations字段，特殊处理，但限制嵌套深度
          if (keys[0] == 'integrations') {
            // 限制integrations的嵌套深度，最多3层：integrations.key1.key2
            if (keys.length > 3) {
              return false; // 拒绝过深的嵌套
            }
            final integrations =
                Map<String, dynamic>.from(config.integrations ?? {});
            
            // 创建嵌套结构而不是使用点号连接的键
            final integrationKeys = keys.sublist(1);
            var current = integrations;
            
            // 导航到正确的嵌套位置
            for (var i = 0; i < integrationKeys.length - 1; i++) {
              final key = integrationKeys[i];
              if (!current.containsKey(key)) {
                current[key] = <String, dynamic>{};
              }
              if (current[key] is! Map<String, dynamic>) {
                current[key] = <String, dynamic>{};
              }
              current = current[key] as Map<String, dynamic>;
            }
            
            // 设置最终值
            current[integrationKeys.last] = value;
            
            updatedConfig = config.copyWith(integrations: integrations);
          } else {
            return false; // 其他不识别的有效顶级键但无法处理的情况
          }
      }

      return await saveUserConfig(updatedConfig);
    } catch (e) {
      Logger.error('设置配置值失败', error: e);
      return false;
    }
  }

  /// 合并用户配置和工作空间配置
  /// 优先级：命令行参数 > 工作空间配置 > 用户配置
  Future<WorkspaceConfig?> mergeWithWorkspaceConfig(
      WorkspaceConfig workspaceConfig,
      {Map<String, String>? overrides,}) async {
    try {
      final userConfig = await loadUserConfig();
      if (userConfig == null) {
        Logger.debug('用户配置不存在，使用工作空间配置');
        return workspaceConfig;
      }

      // 合并默认设置，工作空间配置优先
      final mergedDefaults = DefaultSettings(
        author: workspaceConfig.defaults.author.isNotEmpty
            ? workspaceConfig.defaults.author
            : userConfig.defaults.author,
        license: workspaceConfig.defaults.license.isNotEmpty
            ? workspaceConfig.defaults.license
            : userConfig.defaults.license,
        dartVersion: workspaceConfig.defaults.dartVersion.isNotEmpty
            ? workspaceConfig.defaults.dartVersion
            : userConfig.defaults.dartVersion,
        description: workspaceConfig.defaults.description.isNotEmpty
            ? workspaceConfig.defaults.description
            : userConfig.defaults.description,
      );

      // 应用命令行覆盖
      var finalDefaults = mergedDefaults;
      if (overrides != null) {
        finalDefaults = mergedDefaults.copyWith(
          author: overrides['author'] ?? mergedDefaults.author,
          license: overrides['license'] ?? mergedDefaults.license,
          dartVersion: overrides['dartVersion'] ?? mergedDefaults.dartVersion,
          description: overrides['description'] ?? mergedDefaults.description,
        );
      }

      final mergedConfig = workspaceConfig.copyWith(
        defaults: finalDefaults,
      );

      Logger.debug('配置合并完成');
      return mergedConfig;
    } catch (e) {
      Logger.error('配置合并失败', error: e);
      return workspaceConfig;
    }
  }

  /// 列出所有配置值
  Future<Map<String, dynamic>> listAllConfig() async {
    try {
      final config = await loadUserConfig();
      if (config == null) return {};

      return config.toJson();
    } catch (e) {
      Logger.error('列出配置失败', error: e);
      return {};
    }
  }

  /// 重置用户配置为默认值
  Future<bool> resetUserConfig() async {
    try {
      final defaultConfig = UserConfig.defaultConfig();
      final success = await saveUserConfig(defaultConfig);
      if (success) {
        Logger.success('用户配置已重置为默认值');
        return true;
      } else {
        Logger.error('重置用户配置失败');
        return false;
      }
    } catch (e) {
      Logger.error('重置用户配置异常', error: e);
      return false;
    }
  }

  /// 清理缓存
  void clearCache() {
    _cachedUserConfig = null;
    Logger.debug('用户配置缓存已清理');
  }

  /// 创建用户目录结构
  Future<void> _createUserDirectoryStructure() async {
    try {
      final directories = [
        'templates',
        'cache',
      ];

      for (final dir in directories) {
        final dirPath = path.join(userConfigDir, dir);
        await FileUtils.createDirectory(dirPath);
        Logger.debug('创建用户目录: $dirPath');
      }
    } catch (e) {
      Logger.error('创建用户目录结构失败', error: e);
    }
  }

  /// 获取用户配置摘要
  Map<String, dynamic> getUserConfigSummary() {
    final config = _cachedUserConfig;
    if (config == null) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'user_name': config.user.name,
      'user_email': config.user.email,
      'default_template': config.preferences.defaultTemplate,
      'preferred_ide': config.preferences.preferredIde,
      'config_dir': userConfigDir,
      'config_file': userConfigFilePath,
    };
  }
}
