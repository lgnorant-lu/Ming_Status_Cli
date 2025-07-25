/*
---------------------------------------------------------------
File name:          pet_app_bridge.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        Pet App V3桥接层 (Pet App V3 bridge layer)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - Ming CLI与Pet App V3插件系统桥接;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'local_registry.dart';

/// Pet App V3插件清单格式
class PetAppPluginManifest {
  /// 插件ID
  final String id;

  /// 插件名称
  final String name;

  /// 版本
  final String version;

  /// 描述
  final String description;

  /// 作者
  final String author;

  /// 类别
  final String category;

  /// 主入口文件
  final String main;

  /// 主页URL
  final String? homepage;

  /// 仓库URL
  final String? repository;

  /// 许可证
  final String? license;

  /// 关键词
  final List<String> keywords;

  /// 图标路径
  final String? icon;

  /// 截图列表
  final List<String> screenshots;

  /// 最小应用版本
  final String? minAppVersion;

  /// 最大应用版本
  final String? maxAppVersion;

  /// 支持的平台
  final List<String> platforms;

  /// 权限列表
  final List<String> permissions;

  /// 依赖列表
  final List<PetAppPluginDependency> dependencies;

  /// 资源文件列表
  final List<String> assets;

  /// 配置信息
  final Map<String, dynamic> config;

  /// 本地化支持
  final List<String> locales;

  /// 默认语言
  final String? defaultLocale;

  /// 开发者信息
  final Map<String, dynamic>? developer;

  /// 构造函数
  PetAppPluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.category,
    required this.main,
    this.homepage,
    this.repository,
    this.license,
    this.keywords = const [],
    this.icon,
    this.screenshots = const [],
    this.minAppVersion,
    this.maxAppVersion,
    this.platforms = const [],
    this.permissions = const [],
    this.dependencies = const [],
    this.assets = const [],
    this.config = const {},
    this.locales = const [],
    this.defaultLocale,
    this.developer,
  });

  /// 从YAML数据创建
  factory PetAppPluginManifest.fromYaml(Map<String, dynamic> yaml) {
    try {
      // 支持嵌套结构（plugin节点下的字段）
      final pluginNode = yaml['plugin'];
      final pluginData = pluginNode != null
          ? Map<String, dynamic>.from(pluginNode as Map)
          : yaml;

      return PetAppPluginManifest(
        id: pluginData['id'] as String? ?? 'unknown',
        name: pluginData['name'] as String? ?? 'Unknown Plugin',
        version: pluginData['version'] as String? ?? '1.0.0',
        description: pluginData['description'] as String? ?? 'No description',
        author: pluginData['author'] as String? ?? 'Unknown Author',
        category: pluginData['category'] as String? ?? 'tool',
        main: _getMainEntry(yaml),
        homepage: _safeGetString(pluginData, 'homepage'),
        repository: _safeGetString(pluginData, 'repository'),
        license: _safeGetString(pluginData, 'license'),
        keywords: _getStringList(pluginData['keywords']),
        icon: _safeGetString(pluginData, 'icon'),
        screenshots: _getStringList(pluginData['screenshots']),
        minAppVersion: _getCompatibilityVersion(yaml, 'min_app_version'),
        maxAppVersion: _getCompatibilityVersion(yaml, 'max_app_version'),
        platforms: _getPlatforms(yaml),
        permissions: _getStringList(yaml['permissions']),
        dependencies: _getDependencies(yaml),
        assets: _getStringList(yaml['assets']),
        config: _getConfig(yaml),
        locales: _getStringList(yaml['locales']),
        defaultLocale: _safeGetString(yaml, 'default_locale'),
        developer: yaml['developer'] != null
            ? Map<String, dynamic>.from(yaml['developer'] as Map)
            : null,
      );
    } catch (e) {
      throw Exception('解析插件清单失败: $e');
    }
  }

  /// 安全获取字符串值
  static String? _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value?.toString();
  }

  /// 获取主入口文件
  static String _getMainEntry(Map<String, dynamic> yaml) {
    final entryPointsNode = yaml['entry_points'];
    if (entryPointsNode != null) {
      final entryPoints = Map<String, dynamic>.from(entryPointsNode as Map);
      final mainEntry = _safeGetString(entryPoints, 'main');
      if (mainEntry != null) {
        return mainEntry;
      }
    }
    return _safeGetString(yaml, 'main') ?? 'lib/main.dart';
  }

  /// 获取兼容性版本
  static String? _getCompatibilityVersion(
      Map<String, dynamic> yaml, String key) {
    final compatibilityNode = yaml['compatibility'];
    if (compatibilityNode == null) return null;
    final compatibility = Map<String, dynamic>.from(compatibilityNode as Map);
    return _safeGetString(compatibility, key);
  }

  /// 获取平台列表
  static List<String> _getPlatforms(Map<String, dynamic> yaml) {
    final platforms = yaml['platforms'];
    if (platforms is List) {
      return platforms.cast<String>();
    }
    final compatibilityNode = yaml['compatibility'];
    if (compatibilityNode != null) {
      final compatibility = Map<String, dynamic>.from(compatibilityNode as Map);
      final compatPlatforms = compatibility['platforms'];
      if (compatPlatforms is List) {
        return compatPlatforms.cast<String>();
      }
    }
    return [];
  }

  /// 获取字符串列表
  static List<String> _getStringList(dynamic value) {
    if (value is List) {
      return value.cast<String>();
    }
    return [];
  }

  /// 获取依赖列表
  static List<PetAppPluginDependency> _getDependencies(
      Map<String, dynamic> yaml) {
    final dependencies = <PetAppPluginDependency>[];

    final depsNode = yaml['dependencies'];
    if (depsNode != null) {
      final depsData = Map<String, dynamic>.from(depsNode as Map);

      // 处理required依赖
      final required = depsData['required'] as List?;
      if (required != null) {
        for (final dep in required) {
          if (dep is Map) {
            final depMap = Map<String, dynamic>.from(dep);
            dependencies.add(PetAppPluginDependency.fromMap(depMap, true));
          }
        }
      }

      // 处理optional依赖
      final optional = depsData['optional'] as List?;
      if (optional != null) {
        for (final dep in optional) {
          if (dep is Map) {
            final depMap = Map<String, dynamic>.from(dep);
            dependencies.add(PetAppPluginDependency.fromMap(depMap, false));
          }
        }
      }
    }

    return dependencies;
  }

  /// 获取配置信息
  static Map<String, dynamic> _getConfig(Map<String, dynamic> yaml) {
    final config = <String, dynamic>{};

    // 合并configuration节点
    final configurationNode = yaml['configuration'];
    if (configurationNode != null) {
      final configuration = Map<String, dynamic>.from(configurationNode as Map);
      config.addAll(configuration);
    }

    // 合并config节点
    final configNode = yaml['config'];
    if (configNode != null) {
      final configData = Map<String, dynamic>.from(configNode as Map);
      config.addAll(configData);
    }

    return config;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'category': category,
      'main': main,
      'homepage': homepage,
      'repository': repository,
      'license': license,
      'keywords': keywords,
      'icon': icon,
      'screenshots': screenshots,
      'minAppVersion': minAppVersion,
      'maxAppVersion': maxAppVersion,
      'platforms': platforms,
      'permissions': permissions,
      'dependencies': dependencies.map((d) => d.toJson()).toList(),
      'assets': assets,
      'config': config,
      'locales': locales,
      'defaultLocale': defaultLocale,
      'developer': developer,
    };
  }
}

/// Pet App V3插件依赖
class PetAppPluginDependency {
  /// 依赖ID
  final String id;

  /// 版本要求
  final String version;

  /// 是否必需
  final bool required;

  /// 描述
  final String? description;

  /// 构造函数
  PetAppPluginDependency({
    required this.id,
    required this.version,
    required this.required,
    this.description,
  });

  /// 从Map创建
  factory PetAppPluginDependency.fromMap(
      Map<String, dynamic> map, bool isRequired) {
    return PetAppPluginDependency(
      id: map['id'] as String,
      version: map['version'] as String,
      required: isRequired,
      description: map['description'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'required': required,
      'description': description,
    };
  }
}

/// Pet App V3桥接器
///
/// 负责Ming CLI与Pet App V3插件系统之间的数据转换和同步。
class PetAppBridge {
  /// 本地注册表实例
  final LocalRegistry _localRegistry;

  /// 构造函数
  PetAppBridge({LocalRegistry? localRegistry})
      : _localRegistry = localRegistry ?? LocalRegistry();

  /// 解析Pet App V3插件清单
  Future<PetAppPluginManifest> parseManifest(String manifestPath) async {
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      throw Exception('插件清单文件不存在: $manifestPath');
    }

    final manifestContent = await manifestFile.readAsString();
    final yamlData = loadYaml(manifestContent);
    final manifestMap = _convertYamlToMap(yamlData);

    return PetAppPluginManifest.fromYaml(manifestMap);
  }

  /// 将YAML数据转换为Map<String, dynamic> (借鉴Pet App V3实现)
  Map<String, dynamic> _convertYamlToMap(dynamic yamlData) {
    if (yamlData is YamlMap) {
      final result = <String, dynamic>{};
      for (final dynamic key in yamlData.keys) {
        final dynamic value = yamlData[key];
        result[key.toString()] = _convertYamlValue(value);
      }
      return result;
    } else if (yamlData is Map) {
      final result = <String, dynamic>{};
      for (final dynamic key in yamlData.keys) {
        final dynamic value = yamlData[key];
        result[key.toString()] = _convertYamlValue(value);
      }
      return result;
    }
    return <String, dynamic>{};
  }

  /// 转换YAML值为标准值 (借鉴Pet App V3实现)
  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _convertYamlToMap(value);
    } else if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    } else if (value is Map) {
      return _convertYamlToMap(value);
    } else if (value is List) {
      return value.map(_convertYamlValue).toList();
    }
    return value;
  }

  /// 验证Pet App V3兼容性
  Future<Map<String, dynamic>> validatePetAppCompatibility(
    String pluginPath,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // 1. 解析插件清单
      final manifestPath = path.join(pluginPath, 'plugin.yaml');
      final manifest = await parseManifest(manifestPath);
      details['manifest'] = manifest.toJson();

      // 2. 检查Pet App V3特定字段
      _validatePetAppFields(manifest, errors, warnings);

      // 3. 检查依赖兼容性
      _validateDependencies(manifest, errors, warnings);

      // 4. 检查平台支持
      _validatePlatforms(manifest, errors, warnings);

      // 5. 检查权限声明
      _validatePermissions(manifest, errors, warnings);

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'details': details,
      };
    } catch (e) {
      errors.add('Pet App V3兼容性验证失败: $e');
      return {
        'isValid': false,
        'errors': errors,
        'warnings': warnings,
        'details': details,
      };
    }
  }

  /// 验证Pet App V3特定字段
  void _validatePetAppFields(
    PetAppPluginManifest manifest,
    List<String> errors,
    List<String> warnings,
  ) {
    // 检查最小应用版本
    if (manifest.minAppVersion == null) {
      warnings.add('建议设置最小应用版本 (min_app_version)');
    }

    // 检查主入口文件
    if (!manifest.main.endsWith('.dart')) {
      errors.add('主入口文件必须是Dart文件: ${manifest.main}');
    }

    // 检查类别
    final validCategories = [
      'tool',
      'game',
      'education',
      'entertainment',
      'productivity',
      'social',
      'photo',
      'music',
      'video',
      'news',
      'weather',
      'travel',
      'sports',
      'health',
      'finance',
      'business'
    ];
    if (!validCategories.contains(manifest.category)) {
      warnings.add('插件类别 "${manifest.category}" 不在推荐列表中');
    }
  }

  /// 验证依赖
  void _validateDependencies(
    PetAppPluginManifest manifest,
    List<String> errors,
    List<String> warnings,
  ) {
    // 检查是否有plugin_system依赖
    final hasPluginSystemDep =
        manifest.dependencies.any((dep) => dep.id == 'plugin_system');

    if (!hasPluginSystemDep) {
      errors.add('缺少必需的plugin_system依赖');
    }

    // 检查版本格式
    for (final dep in manifest.dependencies) {
      if (!_isValidVersionConstraint(dep.version)) {
        warnings.add('依赖 ${dep.id} 的版本约束格式可能不正确: ${dep.version}');
      }
    }
  }

  /// 验证平台支持
  void _validatePlatforms(
    PetAppPluginManifest manifest,
    List<String> errors,
    List<String> warnings,
  ) {
    final validPlatforms = [
      'android',
      'ios',
      'web',
      'windows',
      'macos',
      'linux'
    ];

    for (final platform in manifest.platforms) {
      if (!validPlatforms.contains(platform)) {
        warnings.add('不支持的平台: $platform');
      }
    }

    if (manifest.platforms.isEmpty) {
      warnings.add('未指定支持的平台');
    }
  }

  /// 验证权限
  void _validatePermissions(
    PetAppPluginManifest manifest,
    List<String> errors,
    List<String> warnings,
  ) {
    final validPermissions = [
      'fileSystem',
      'network',
      'camera',
      'microphone',
      'location',
      'notifications',
      'clipboard',
      'storage',
      'contacts',
      'calendar'
    ];

    for (final permission in manifest.permissions) {
      if (!validPermissions.contains(permission)) {
        warnings.add('未知权限: $permission');
      }
    }
  }

  /// 检查版本约束格式
  bool _isValidVersionConstraint(String version) {
    // 简单的版本约束格式检查
    final patterns = [
      RegExp(r'^\d+\.\d+\.\d+$'), // 精确版本
      RegExp(r'^\^\d+\.\d+\.\d+$'), // 兼容版本
      RegExp(r'^>=\d+\.\d+\.\d+$'), // 最小版本
      RegExp(r'^<=\d+\.\d+\.\d+$'), // 最大版本
    ];

    return patterns.any((pattern) => pattern.hasMatch(version));
  }

  /// 同步到Pet App V3注册表
  Future<Map<String, dynamic>> syncToPetApp(String pluginId) async {
    try {
      // 1. 从本地注册表获取插件信息
      final pluginInfo = await _localRegistry.getPlugin(pluginId);
      if (pluginInfo == null) {
        throw Exception('插件 $pluginId 不存在于本地注册表中');
      }

      // 2. 转换为Pet App V3格式
      final petAppFormat = _convertToPetAppFormat(pluginInfo);

      // 3. 创建同步数据包
      final syncPacket = _createSyncPacket(pluginId, petAppFormat);

      // 4. 模拟同步到Pet App V3（实际实现需要与Pet App V3通信）
      final syncResult = await _performSync(syncPacket);

      return {
        'success': true,
        'pluginId': pluginId,
        'syncResult': syncResult,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'pluginId': pluginId,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 从Pet App V3导入插件
  Future<Map<String, dynamic>> importFromPetApp(String pluginId) async {
    try {
      // 1. 模拟从Pet App V3获取插件信息
      final petAppPluginData = await _fetchFromPetApp(pluginId);

      // 2. 转换为Ming CLI格式
      final mingFormat = _convertToMingFormat(petAppPluginData);

      // 3. 导入到本地注册表
      await _importToLocalRegistry(pluginId, mingFormat);

      return {
        'success': true,
        'pluginId': pluginId,
        'importedData': mingFormat,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'pluginId': pluginId,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 转换为Pet App V3格式
  Map<String, dynamic> _convertToPetAppFormat(Map<String, dynamic> pluginInfo) {
    return {
      'id': pluginInfo['id'],
      'name': pluginInfo['name'],
      'version': pluginInfo['latest_version'],
      'description': pluginInfo['description'],
      'author': pluginInfo['author'],
      'category': pluginInfo['category'],
      'installed': pluginInfo['installed'],
      'versions': pluginInfo['versions'],
      'metadata': {
        'source': 'ming_cli',
        'sync_timestamp': DateTime.now().toIso8601String(),
        'original_data': pluginInfo,
      },
    };
  }

  /// 创建同步数据包
  Map<String, dynamic> _createSyncPacket(
      String pluginId, Map<String, dynamic> data) {
    return {
      'syncId': _generateSyncId(),
      'sourceSystem': 'ming_cli',
      'targetSystem': 'pet_app_v3',
      'operation': 'sync_plugin',
      'pluginId': pluginId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// 执行同步操作
  Future<Map<String, dynamic>> _performSync(
      Map<String, dynamic> syncPacket) async {
    // 模拟同步延迟
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 模拟同步结果
    return {
      'syncId': syncPacket['syncId'],
      'status': 'completed',
      'message': '插件同步成功',
      'pet_app_plugin_id': syncPacket['pluginId'],
      'sync_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 从Pet App V3获取插件数据
  Future<Map<String, dynamic>> _fetchFromPetApp(String pluginId) async {
    // 模拟网络延迟
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // 模拟Pet App V3插件数据
    return {
      'id': pluginId,
      'name': 'Pet App Plugin',
      'version': '1.0.0',
      'description': 'A plugin from Pet App V3',
      'author': 'Pet App Developer',
      'category': 'tool',
      'manifest': {
        'main': 'lib/main.dart',
        'platforms': ['android', 'ios', 'web'],
        'permissions': ['network'],
      },
      'metadata': {
        'source': 'pet_app_v3',
        'export_timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// 转换为Ming CLI格式
  Map<String, dynamic> _convertToMingFormat(Map<String, dynamic> petAppData) {
    return {
      'id': petAppData['id'],
      'name': petAppData['name'],
      'description': petAppData['description'],
      'author': petAppData['author'],
      'category': petAppData['category'],
      'latest_version': petAppData['version'],
      'versions': {
        petAppData['version']: {
          'version': petAppData['version'],
          'manifest': petAppData['manifest'],
          'imported': DateTime.now().toIso8601String(),
        },
      },
      'installed': false,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
      'metadata': {
        'source': 'pet_app_v3',
        'import_timestamp': DateTime.now().toIso8601String(),
        'original_data': petAppData,
      },
    };
  }

  /// 导入到本地注册表
  Future<void> _importToLocalRegistry(
      String pluginId, Map<String, dynamic> data) async {
    // 模拟创建插件包文件
    final tempManifest = {
      'plugin': {
        'id': data['id'],
        'name': data['name'],
        'version': data['latest_version'],
        'description': data['description'],
        'author': data['author'],
        'category': data['category'],
      },
    };

    // 发布到本地注册表
    await _localRegistry.publishPlugin(
      'temp_package_path', // 实际实现中需要创建临时包文件
      tempManifest,
    );
  }

  /// 生成同步ID
  String _generateSyncId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'sync_${timestamp}_$random';
  }
}
