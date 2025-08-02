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

import 'package:http/http.dart' as http;
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
      } else if (registry == 'github') {
        return await _publishToGitHub(packagePath, manifest);
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
      final pubspecResult =
          await _generatePubspecForPubDev(manifest, packagePath);
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

  /// 发布到GitHub注册表
  Future<Map<String, dynamic>> _publishToGitHub(
    String packagePath,
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // 1. 获取GitHub配置
      final githubConfig = await _getGitHubConfiguration();
      if (githubConfig == null) {
        errors.add('未找到GitHub配置信息');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'registry': 'github',
        };
      }

      // 2. 验证GitHub发布要求
      final validationResult = await _validateGitHubRequirements(manifest);
      if (!(validationResult['isValid'] as bool)) {
        errors.addAll(validationResult['errors'] as List<String>);
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
          'registry': 'github',
        };
      }

      // 3. 创建GitHub Release
      final releaseResult = await _createGitHubRelease(
        packagePath,
        manifest,
        githubConfig,
      );

      if (!(releaseResult['success'] as bool)) {
        errors.addAll(releaseResult['errors'] as List<String>);
      }
      warnings.addAll(releaseResult['warnings'] as List<String>);

      return {
        'success': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'registry': 'github',
        'release_url': releaseResult['release_url'],
        'download_url': releaseResult['download_url'],
      };
    } catch (e) {
      errors.add('GitHub发布失败: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
        'registry': 'github',
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
    String packagePath,
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

      // 实际写入pubspec.yaml文件
      await _writePubspecFile(pubspec, packagePath);
      warnings.add('pubspec.yaml文件已生成并写入');

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

  /// 执行pub publish（真实命令执行）
  Future<Map<String, dynamic>> _executePubPublish(String packagePath) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // 检查是否在正确的包目录中
      final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
      if (!await pubspecFile.exists()) {
        errors.add('pubspec.yaml文件不存在: $packagePath');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }

      // 执行 dart pub publish --dry-run 进行预检查
      final dryRunResult = await Process.run(
        'dart',
        ['pub', 'publish', '--dry-run'],
        workingDirectory: packagePath,
        runInShell: true,
      );

      if (dryRunResult.exitCode != 0) {
        errors.add('pub publish预检查失败: ${dryRunResult.stderr}');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }

      // 执行实际的pub publish命令
      final publishResult = await Process.run(
        'dart',
        ['pub', 'publish', '--force'], // 使用--force跳过交互式确认
        workingDirectory: packagePath,
        runInShell: true,
      );

      if (publishResult.exitCode == 0) {
        // 解析输出以获取包URL
        final output = publishResult.stdout.toString();
        final packageName = await _getPackageNameFromPubspec(packagePath);
        final packageUrl = 'https://pub.dev/packages/$packageName';

        warnings.add('pub publish执行成功');
        warnings.add('输出: $output');

        return {
          'success': true,
          'errors': errors,
          'warnings': warnings,
          'package_url': packageUrl,
        };
      } else {
        errors.add('pub publish执行失败: ${publishResult.stderr}');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }
    } catch (e) {
      errors.add('执行pub publish异常: $e');
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

  /// 获取私有注册表配置（真实配置读取）
  Future<Map<String, dynamic>?> _getPrivateRegistryConfig() async {
    try {
      // 1. 尝试从环境变量读取配置
      final registryUrl = Platform.environment['PRIVATE_REGISTRY_URL'];
      final authType = Platform.environment['PRIVATE_REGISTRY_AUTH_TYPE'];
      final authToken = Platform.environment['PRIVATE_REGISTRY_AUTH_TOKEN'];
      final apiKey = Platform.environment['PRIVATE_REGISTRY_API_KEY'];
      final uploadEndpoint =
          Platform.environment['PRIVATE_REGISTRY_UPLOAD_ENDPOINT'];

      if (registryUrl != null && authType != null) {
        final config = {
          'url': registryUrl,
          'auth_type': authType,
          'upload_endpoint': uploadEndpoint ?? '/api/v1/packages/upload',
          'timeout': 30000,
          'retry_count': 3,
        };

        // 根据认证类型添加相应的认证信息
        switch (authType) {
          case 'token':
            if (authToken != null) {
              config['auth_token'] = authToken;
            }
            break;
          case 'apikey':
            if (apiKey != null) {
              config['api_key'] = apiKey;
            }
            break;
        }

        return config;
      }

      // 2. 尝试从配置文件读取
      final configFile = File('private_registry.json');
      if (await configFile.exists()) {
        final configContent = await configFile.readAsString();
        final config = jsonDecode(configContent) as Map<String, dynamic>;

        if (config['url'] != null && config['auth_type'] != null) {
          return config;
        }
      }

      // 3. 尝试从用户配置目录读取
      final homeDir =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null) {
        final userConfigFile =
            File(path.join(homeDir, '.ming', 'private_registry.json'));
        if (await userConfigFile.exists()) {
          final configContent = await userConfigFile.readAsString();
          final config = jsonDecode(configContent) as Map<String, dynamic>;

          if (config['url'] != null && config['auth_type'] != null) {
            return config;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
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
      final authType = config['auth_type'] as String;
      final timeout = config['timeout'] as int? ?? 30000;
      final retryCount = config['retry_count'] as int? ?? 3;

      // 构建上传URL
      final uploadUrl = '$registryUrl$uploadEndpoint';

      // 准备认证头
      final headers = <String, String>{
        'Content-Type': 'multipart/form-data',
        'User-Agent': 'Ming-CLI/1.0.0',
      };

      // 根据认证类型添加认证头
      switch (authType) {
        case 'token':
          final authToken = config['auth_token'] as String?;
          if (authToken != null) {
            headers['Authorization'] = 'Bearer $authToken';
          }
          break;
        case 'apikey':
          final apiKey = config['api_key'] as String?;
          if (apiKey != null) {
            headers['X-API-Key'] = apiKey;
          }
          break;
      }

      // 读取插件包文件
      final packageFile = File(packagePath);
      if (!await packageFile.exists()) {
        errors.add('插件包文件不存在: $packagePath');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }

      final pluginId = manifest['plugin']?['id'] ?? manifest['id'];
      final version = manifest['plugin']?['version'] ?? manifest['version'];
      final packageBytes = await packageFile.readAsBytes();

      // 创建multipart请求
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers.addAll(headers);

      // 添加文件
      request.files.add(
        http.MultipartFile.fromBytes(
          'package',
          packageBytes,
          filename: path.basename(packagePath),
        ),
      );

      // 添加元数据
      request.fields['plugin_id'] = pluginId.toString();
      request.fields['version'] = version.toString();
      request.fields['manifest'] = jsonEncode(manifest);

      // 执行上传（带重试机制）
      http.StreamedResponse? response;
      Exception? lastException;

      for (int attempt = 1; attempt <= retryCount; attempt++) {
        try {
          response =
              await request.send().timeout(Duration(milliseconds: timeout));
          break;
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          if (attempt < retryCount) {
            warnings.add('上传尝试 $attempt 失败，正在重试...');
            await Future<void>.delayed(Duration(seconds: attempt));
          }
        }
      }

      if (response == null) {
        errors.add('上传失败，已重试 $retryCount 次: ${lastException?.toString()}');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }

      // 处理响应
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        warnings.add('成功上传到私有注册表');

        // 尝试解析响应以获取更多信息
        Map<String, dynamic>? responseData;
        try {
          responseData = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          // 忽略JSON解析错误
        }

        return {
          'success': true,
          'errors': errors,
          'warnings': warnings,
          'registry_url': registryUrl,
          'package_id': '$pluginId@$version',
          'response_data': responseData,
        };
      } else {
        errors.add('私有注册表返回错误: ${response.statusCode} - $responseBody');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }
    } catch (e) {
      errors.add('上传到私有注册表异常: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 获取GitHub配置
  Future<Map<String, dynamic>?> _getGitHubConfiguration() async {
    try {
      // 尝试从环境变量读取
      final token = Platform.environment['GITHUB_TOKEN'];
      final owner = Platform.environment['GITHUB_OWNER'];
      final repo = Platform.environment['GITHUB_REPO'];

      if (token != null && owner != null && repo != null) {
        return {
          'token': token,
          'owner': owner,
          'repo': repo,
          'baseUrl': 'https://api.github.com',
        };
      }

      // 尝试从配置文件读取
      final configFile = File('github_config.json');
      if (await configFile.exists()) {
        final configContent = await configFile.readAsString();
        final config = jsonDecode(configContent) as Map<String, dynamic>;

        if (config['token'] != null &&
            config['owner'] != null &&
            config['repo'] != null) {
          return config;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 验证GitHub发布要求
  Future<Map<String, dynamic>> _validateGitHubRequirements(
    Map<String, dynamic> manifest,
  ) async {
    final errors = <String>[];

    // 检查必需字段
    final requiredFields = ['name', 'version', 'description'];
    for (final field in requiredFields) {
      final value = manifest['plugin']?[field] ?? manifest[field];
      if (value == null || value.toString().trim().isEmpty) {
        errors.add('GitHub发布需要字段: $field');
      }
    }

    // 检查版本格式
    final version = manifest['plugin']?['version'] ?? manifest['version'];
    if (version != null && !_isValidSemVer(version as String)) {
      errors.add('版本号必须符合语义化版本规范: $version');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// 创建GitHub Release
  Future<Map<String, dynamic>> _createGitHubRelease(
    String packagePath,
    Map<String, dynamic> manifest,
    Map<String, dynamic> config,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final pluginId = manifest['plugin']?['id'] ?? manifest['id'];
      final version = manifest['plugin']?['version'] ?? manifest['version'];
      final description =
          manifest['plugin']?['description'] ?? manifest['description'];

      // 创建release数据
      final releaseData = {
        'tag_name': 'v$version',
        'target_commitish': 'main',
        'name': '$pluginId v$version',
        'body': description,
        'draft': false,
        'prerelease': false,
      };

      // 发送创建release请求
      final releaseUrl =
          '${config['baseUrl']}/repos/${config['owner']}/${config['repo']}/releases';
      final response = await http.post(
        Uri.parse(releaseUrl),
        headers: {
          'Authorization': 'token ${config['token']}',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(releaseData),
      );

      if (response.statusCode == 201) {
        final releaseInfo = jsonDecode(response.body) as Map<String, dynamic>;

        // 上传插件包文件
        final uploadResult = await _uploadReleaseAsset(
          packagePath,
          releaseInfo,
          config,
        );

        if (!(uploadResult['success'] as bool)) {
          errors.addAll(uploadResult['errors'] as List<String>);
        }
        warnings.addAll(uploadResult['warnings'] as List<String>);

        return {
          'success': errors.isEmpty,
          'errors': errors,
          'warnings': warnings,
          'release_url': releaseInfo['html_url'],
          'download_url': uploadResult['download_url'],
        };
      } else {
        errors.add(
            '创建GitHub Release失败: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }
    } catch (e) {
      errors.add('创建GitHub Release异常: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 上传Release资产
  Future<Map<String, dynamic>> _uploadReleaseAsset(
    String packagePath,
    Map<String, dynamic> releaseInfo,
    Map<String, dynamic> config,
  ) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final packageFile = File(packagePath);
      if (!await packageFile.exists()) {
        errors.add('插件包文件不存在: $packagePath');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }

      final fileName = path.basename(packagePath);
      final uploadUrl = (releaseInfo['upload_url'] as String)
          .replaceAll('{?name,label}', '?name=$fileName');

      final fileBytes = await packageFile.readAsBytes();

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': 'token ${config['token']}',
          'Content-Type': 'application/octet-stream',
        },
        body: fileBytes,
      );

      if (response.statusCode == 201) {
        final assetInfo = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'errors': errors,
          'warnings': warnings,
          'download_url': assetInfo['browser_download_url'],
        };
      } else {
        errors.add('上传Release资产失败: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'errors': errors,
          'warnings': warnings,
        };
      }
    } catch (e) {
      errors.add('上传Release资产异常: $e');
      return {
        'success': false,
        'errors': errors,
        'warnings': warnings,
      };
    }
  }

  /// 写入pubspec.yaml文件
  Future<void> _writePubspecFile(
    Map<String, dynamic> pubspec,
    String packagePath,
  ) async {
    final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));

    // 将Map转换为YAML格式字符串
    final yamlContent = _mapToYaml(pubspec);

    // 写入文件
    await pubspecFile.writeAsString(yamlContent);
  }

  /// 将Map转换为YAML格式字符串
  String _mapToYaml(Map<String, dynamic> map, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    for (final entry in map.entries) {
      if (entry.value is Map) {
        buffer.writeln('$indentStr${entry.key}:');
        buffer
            .write(_mapToYaml(entry.value as Map<String, dynamic>, indent + 1));
      } else if (entry.value is List) {
        buffer.writeln('$indentStr${entry.key}:');
        for (final item in entry.value as List) {
          if (item is Map) {
            buffer.write(_mapToYaml(item as Map<String, dynamic>, indent + 1));
          } else {
            buffer.writeln('$indentStr  - $item');
          }
        }
      } else {
        buffer.writeln('$indentStr${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// 从pubspec.yaml获取包名
  Future<String> _getPackageNameFromPubspec(String packagePath) async {
    try {
      final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
      if (await pubspecFile.exists()) {
        final content = await pubspecFile.readAsString();
        final yamlData = loadYaml(content) as Map;
        return yamlData['name'] as String? ?? 'unknown_package';
      }
      return 'unknown_package';
    } catch (e) {
      return 'unknown_package';
    }
  }
}
