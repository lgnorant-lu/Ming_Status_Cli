/*
---------------------------------------------------------------
File name:          plugin_publisher.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件发布器核心实现 (Plugin publisher core implementation)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件发布核心逻辑;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'local_registry.dart';

/// 插件发布结果
class PluginPublishResult {
  /// 是否发布成功
  final bool isSuccess;

  /// 发布的插件ID
  final String? pluginId;

  /// 发布的版本
  final String? version;

  /// 发布的注册表类型
  final String registry;

  /// 发布错误列表
  final List<String> errors;

  /// 发布警告列表
  final List<String> warnings;

  /// 发布详情
  final Map<String, dynamic> details;

  /// 构造函数
  PluginPublishResult({
    required this.isSuccess,
    this.pluginId,
    this.version,
    required this.registry,
    required this.errors,
    required this.warnings,
    required this.details,
  });

  /// 转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'isSuccess': isSuccess,
      'pluginId': pluginId,
      'version': version,
      'registry': registry,
      'errors': errors,
      'warnings': warnings,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

/// 插件发布器
///
/// 负责将插件发布到各种注册表（本地、pub.dev、私有注册表）。
class PluginPublisher {
  /// 发布插件
  ///
  /// [pluginPath] 插件项目路径
  /// [registry] 目标注册表类型
  /// [isDryRun] 是否为预览模式
  Future<PluginPublishResult> publishPlugin(
    String pluginPath, {
    String registry = 'local',
    bool isDryRun = false,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      // 1. 验证插件项目
      final validationResult = await _validatePluginForPublish(pluginPath);
      if (!(validationResult['isValid'] as bool)) {
        errors.addAll(validationResult['errors'] as List<String>);
        return PluginPublishResult(
          isSuccess: false,
          registry: registry,
          errors: errors,
          warnings: warnings,
          details: details,
        );
      }

      // 2. 读取插件清单
      final manifest = await _loadPluginManifest(pluginPath);
      final pluginId = (manifest['plugin']?['id'] ?? manifest['id']) as String?;
      final version =
          (manifest['plugin']?['version'] ?? manifest['version']) as String?;

      details['manifest'] = manifest;
      details['pluginId'] = pluginId;
      details['version'] = version;

      // 3. 检查版本冲突
      final versionCheckResult = await _checkVersionConflict(
        pluginId!,
        version!,
        registry,
      );
      if (!(versionCheckResult['isValid'] as bool)) {
        errors.addAll(versionCheckResult['errors'] as List<String>);
      }
      warnings.addAll(versionCheckResult['warnings'] as List<String>);

      // 4. 构建插件包（如果需要）
      final packagePath = await _ensurePluginPackage(pluginPath);
      details['packagePath'] = packagePath;

      // 5. 发布到指定注册表
      if (!isDryRun && errors.isEmpty) {
        final publishResult = await _publishToRegistry(
          packagePath,
          manifest,
          registry,
        );

        if (!(publishResult['success'] as bool)) {
          errors.addAll(publishResult['errors'] as List<String>);
        }
        warnings.addAll(publishResult['warnings'] as List<String>);
        details['publishResult'] = publishResult;
      } else if (isDryRun) {
        details['dryRun'] = true;
        warnings.add('预览模式：未实际发布插件');
      }

      return PluginPublishResult(
        isSuccess: errors.isEmpty,
        pluginId: pluginId,
        version: version,
        registry: registry,
        errors: errors,
        warnings: warnings,
        details: details,
      );
    } catch (e) {
      errors.add('发布过程中发生错误: $e');
      return PluginPublishResult(
        isSuccess: false,
        registry: registry,
        errors: errors,
        warnings: warnings,
        details: details,
      );
    }
  }

  /// 验证插件是否可以发布
  Future<Map<String, dynamic>> _validatePluginForPublish(
      String pluginPath) async {
    final errors = <String>[];

    // 检查必需文件
    final requiredFiles = [
      'pubspec.yaml',
      'plugin.yaml',
      'lib',
      'README.md',
      'CHANGELOG.md',
    ];

    for (final file in requiredFiles) {
      final filePath = path.join(pluginPath, file);
      final entityType = FileSystemEntity.typeSync(filePath);
      if (entityType == FileSystemEntityType.notFound) {
        errors.add('缺少必需文件: $file');
      }
    }

    // 检查LICENSE文件
    final licenseFile = File(path.join(pluginPath, 'LICENSE'));
    if (!licenseFile.existsSync()) {
      errors.add('缺少LICENSE文件，发布需要明确的许可证');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// 加载插件清单
  Future<Map<String, dynamic>> _loadPluginManifest(String pluginPath) async {
    final manifestPath = path.join(pluginPath, 'plugin.yaml');
    final manifestFile = File(manifestPath);

    if (!manifestFile.existsSync()) {
      throw Exception('plugin.yaml文件不存在');
    }

    final manifestContent = await manifestFile.readAsString();
    final manifest = loadYaml(manifestContent) as Map;

    return Map<String, dynamic>.from(manifest);
  }

  /// 检查版本冲突
  Future<Map<String, dynamic>> _checkVersionConflict(
    String pluginId,
    String version,
    String registry,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      if (registry == 'local') {
        final localRegistry = LocalRegistry();
        final existingPlugin = await localRegistry.getPlugin(pluginId);

        if (existingPlugin != null) {
          final existingVersion = existingPlugin['version'] as String?;
          if (existingVersion == version) {
            errors.add('版本 $version 已存在于本地注册表中');
          } else {
            warnings.add('插件 $pluginId 已存在，将更新到版本 $version');
          }
        }
      } else if (registry == 'pub.dev') {
        // TODO: 检查pub.dev上的版本冲突
        warnings.add('pub.dev版本检查功能正在开发中');
      } else if (registry == 'private') {
        // TODO: 检查私有注册表的版本冲突
        warnings.add('私有注册表版本检查功能正在开发中');
      }
    } catch (e) {
      warnings.add('版本检查失败: $e');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// 确保插件包存在
  Future<String> _ensurePluginPackage(String pluginPath) async {
    final distDir = Directory(path.join(pluginPath, 'dist'));

    if (!distDir.existsSync()) {
      throw Exception('插件包不存在，请先运行 "ming plugin build"');
    }

    // 查找ZIP包文件
    final zipFiles = distDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.zip'))
        .cast<File>()
        .toList();

    if (zipFiles.isEmpty) {
      throw Exception('未找到插件包文件，请先运行 "ming plugin build"');
    }

    // 返回最新的ZIP包
    zipFiles
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return zipFiles.first.path;
  }

  /// 发布到指定注册表
  Future<Map<String, dynamic>> _publishToRegistry(
    String packagePath,
    Map<String, dynamic> manifest,
    String registry,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      if (registry == 'local') {
        return await _publishToLocalRegistry(packagePath, manifest);
      } else if (registry == 'pub.dev') {
        return await _publishToPubDev(packagePath, manifest);
      } else if (registry == 'private') {
        return await _publishToPrivateRegistry(packagePath, manifest);
      } else {
        errors.add('不支持的注册表类型: $registry');
      }
    } catch (e) {
      errors.add('发布到注册表失败: $e');
    }

    return {
      'success': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// 发布到本地注册表
  Future<Map<String, dynamic>> _publishToLocalRegistry(
    String packagePath,
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final localRegistry = LocalRegistry();
      await localRegistry.publishPlugin(packagePath, manifest);

      return {
        'success': true,
        'errors': errors,
        'warnings': warnings,
        'registry': 'local',
      };
    } catch (e) {
      errors.add('发布到本地注册表失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 发布到pub.dev
  Future<Map<String, dynamic>> _publishToPubDev(
    String packagePath,
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // 1. 验证pub.dev发布要求
      final validationResult = await _validatePubDevRequirements(manifest);
      if (!(validationResult['isValid'] as bool)) {
        errors.addAll(validationResult['errors'] as List<String>);
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'registry': 'pub.dev',
        };
      }

      // 2. 生成pubspec.yaml
      final pubspecResult = await _generatePubspecForPubDev(manifest);
      if (!(pubspecResult['success'] as bool)) {
        errors.addAll(pubspecResult['errors'] as List<String>);
      }
      warnings.addAll(pubspecResult['warnings'] as List<String>);

      // 3. 执行pub publish (模拟)
      // TODO: 实现真实的pub publish集成
      final publishResult = await _executePubPublish(packagePath);
      if (!(publishResult['success'] as bool)) {
        errors.addAll(publishResult['errors'] as List<String>);
      }

      return {
        'success': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'registry': 'pub.dev',
        'package_url': publishResult['package_url'],
      };
    } catch (e) {
      errors.add('pub.dev发布失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
        'registry': 'pub.dev',
      };
    }
  }

  /// 验证pub.dev发布要求
  Future<Map<String, dynamic>> _validatePubDevRequirements(
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];

    // 检查必需字段
    final requiredFields = ['name', 'version', 'description', 'author'];
    for (final field in requiredFields) {
      final value = manifest['plugin']?[field] ?? manifest[field];
      if (value == null || value.toString().trim().isEmpty) {
        errors.add('pub.dev发布需要字段: $field');
      }
    }

    // 检查版本格式
    final version = manifest['plugin']?['version'] ?? manifest['version'];
    if (version != null && !_isValidSemVer(version as String)) {
      errors.add('版本号必须符合语义化版本规范: $version');
    }

    // 检查许可证
    final license = manifest['plugin']?['license'] ?? manifest['license'];
    if (license == null) {
      errors.add('pub.dev发布需要明确的许可证信息');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// 生成pub.dev兼容的pubspec.yaml
  Future<Map<String, dynamic>> _generatePubspecForPubDev(
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final pluginData = manifest['plugin'] ?? manifest;

      final pubspec = {
        'name': pluginData['id'],
        'description': pluginData['description'],
        'version': pluginData['version'],
        'author': pluginData['author'],
        'homepage': pluginData['homepage'],
        'repository': pluginData['repository'],
        'license': pluginData['license'],
        'environment': {
          'sdk': '>=3.0.0 <4.0.0',
        },
        'dependencies': {
          'flutter': {
            'sdk': 'flutter',
          },
        },
        'dev_dependencies': {
          'flutter_test': {
            'sdk': 'flutter',
          },
        },
        'flutter': {
          'plugin': {
            'platforms': _generatePlatformConfig(manifest),
          },
        },
      };

      // TODO: 实际写入pubspec.yaml文件
      warnings.add('pubspec.yaml生成完成（模拟）');

      return {
        'success': true,
        'errors': errors,
        'warnings': warnings,
        'pubspec': pubspec,
      };
    } catch (e) {
      errors.add('生成pubspec.yaml失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 执行pub publish
  Future<Map<String, dynamic>> _executePubPublish(String packagePath) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // TODO: 实现真实的pub publish命令执行
      // final result = await Process.run('dart', ['pub', 'publish'], workingDirectory: packagePath);

      // 模拟发布过程
      await Future<void>.delayed(const Duration(seconds: 2));

      warnings.add('模拟pub publish执行成功');

      return {
        'success': true,
        'errors': errors,
        'warnings': warnings,
        'package_url': 'https://pub.dev/packages/example_plugin',
      };
    } catch (e) {
      errors.add('执行pub publish失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 生成平台配置
  Map<String, dynamic> _generatePlatformConfig(Map<String, dynamic> manifest) {
    final platforms = manifest['platforms'] as List<dynamic>? ?? [];
    final config = <String, dynamic>{};

    for (final platform in platforms) {
      switch (platform.toString()) {
        case 'android':
          config['android'] = {
            'package': 'com.example.plugin',
            'pluginClass': 'ExamplePlugin',
          };
          break;
        case 'ios':
          config['ios'] = {
            'pluginClass': 'ExamplePlugin',
          };
          break;
        case 'web':
          config['web'] = {
            'pluginClass': 'ExamplePluginWeb',
            'fileName': 'example_plugin_web.dart',
          };
          break;
        // TODO: 添加其他平台配置
      }
    }

    return config;
  }

  /// 检查是否为有效的语义化版本
  bool _isValidSemVer(String version) {
    final semVerPattern = RegExp(r'^\d+\.\d+\.\d+(\+\d+)?(-[\w\d\-]+)?$');
    return semVerPattern.hasMatch(version);
  }

  /// 发布到私有注册表
  Future<Map<String, dynamic>> _publishToPrivateRegistry(
    String packagePath,
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // 1. 获取私有注册表配置
      final registryConfig = await _getPrivateRegistryConfig();
      if (registryConfig == null) {
        errors.add('未找到私有注册表配置');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'registry': 'private',
        };
      }

      // 2. 验证认证信息
      final authResult = await _validatePrivateRegistryAuth(registryConfig);
      if (!(authResult['isValid'] as bool)) {
        errors.addAll(authResult['errors'] as List<String>);
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'registry': 'private',
        };
      }

      // 3. 上传插件包
      final uploadResult = await _uploadToPrivateRegistry(
        packagePath,
        manifest,
        registryConfig,
      );

      if (!(uploadResult['success'] as bool)) {
        errors.addAll(uploadResult['errors'] as List<String>);
      }
      warnings.addAll(uploadResult['warnings'] as List<String>);

      return {
        'success': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'registry': 'private',
        'registry_url': uploadResult['registry_url'],
        'package_id': uploadResult['package_id'],
      };
    } catch (e) {
      errors.add('私有注册表发布失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
        'registry': 'private',
      };
    }
  }

  /// 获取私有注册表配置
  Future<Map<String, dynamic>?> _getPrivateRegistryConfig() async {
    // TODO: 从配置文件或环境变量读取私有注册表配置
    // 模拟配置
    return {
      'url': 'https://registry.company.com',
      'auth_type': 'token',
      'auth_token': 'private_registry_token',
      'upload_endpoint': '/api/v1/packages/upload',
    };
  }

  /// 验证私有注册表认证
  Future<Map<String, dynamic>> _validatePrivateRegistryAuth(
    Map<String, dynamic> config,
  ) async {
    final errors = <String>[];

    try {
      final authType = config['auth_type'] as String?;

      switch (authType) {
        case 'token':
          final token = config['auth_token'] as String?;
          if (token == null || token.isEmpty) {
            errors.add('私有注册表需要有效的认证令牌');
          }
          break;
        case 'oauth2':
          // TODO: 实现OAuth2认证验证
          errors.add('OAuth2认证暂未实现');
          break;
        case 'apikey':
          final apiKey = config['api_key'] as String?;
          if (apiKey == null || apiKey.isEmpty) {
            errors.add('私有注册表需要有效的API密钥');
          }
          break;
        default:
          errors.add('不支持的认证类型: $authType');
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
      };
    } catch (e) {
      errors.add('认证验证失败: $e');
      return {
        'isValid': false,
        'errors': errors,
      };
    }
  }

  /// 上传到私有注册表
  Future<Map<String, dynamic>> _uploadToPrivateRegistry(
    String packagePath,
    Map<String, dynamic> manifest,
    Map<String, dynamic> config,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final registryUrl = config['url'] as String;
      final uploadEndpoint = config['upload_endpoint'] as String;
      final authToken = config['auth_token'] as String;

      // TODO: 实现真实的HTTP上传
      // 模拟上传过程
      await Future<void>.delayed(const Duration(seconds: 1));

      final pluginId = manifest['plugin']?['id'] ?? manifest['id'];
      final version = manifest['plugin']?['version'] ?? manifest['version'];

      warnings.add('模拟上传到私有注册表成功');

      return {
        'success': true,
        'errors': errors,
        'warnings': warnings,
        'registry_url': registryUrl,
        'package_id': '$pluginId@$version',
      };
    } catch (e) {
      errors.add('上传到私有注册表失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }
}
