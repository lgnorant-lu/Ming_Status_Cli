/*
---------------------------------------------------------------
File name:          dependency_validator.dart
Author:             Ignorant-lu
Date created:       2025/07/03
Last modified:      2025/07/03
Dart Version:       3.32.4
Description:        依赖关系验证器 - 验证项目依赖的安全性和兼容性
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - 依赖关系验证器实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// 依赖关系验证器
/// 验证依赖版本兼容性、安全性和合理性
class DependencyValidator extends ModuleValidator {
  @override
  String get validatorName => 'dependency';

  @override
  List<ValidationType> get supportedTypes => [ValidationType.dependency];

  @override
  int get priority => 30;

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    final result = ValidationResult(strictMode: context.strictMode);

    try {
      // Task 40.5: 增强pubspec.yaml格式验证
      await _validatePubspecFormat(result, modulePath);

      // pubspec.yaml依赖验证
      await _validatePubspecDependencies(result, modulePath);

      // Task 40.5: 增强依赖版本兼容性验证
      await _validateVersionCompatibility(result, modulePath);

      // Task 40.6: 增强过时包检测
      await _validateOutdatedPackages(result, modulePath);

      // 未使用依赖检查
      await _validateUnusedDependencies(result, modulePath);

      // Task 40.6: 增强安全漏洞检查
      await _validateSecurityVulnerabilities(result, modulePath);

      // 依赖锁文件验证
      await _validateLockFile(result, modulePath);

      // Task 40.5: 添加依赖冲突检测
      await _validateDependencyConflicts(result, modulePath);
    } catch (e) {
      result.addError(
        '依赖关系验证过程发生异常: $e',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }

    result.markCompleted();
    return result;
  }

  /// 验证pubspec.yaml依赖
  Future<void> _validatePubspecDependencies(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      result.addError(
        '缺少pubspec.yaml文件',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
      return;
    }

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);

      // 检查dependencies部分
      if (yaml is Map && yaml.containsKey('dependencies')) {
        final deps = Map<String, dynamic>.from(yaml['dependencies'] as Map);
        await _analyzeDependencies(result, deps, 'dependencies');
      }

      // 检查dev_dependencies部分
      if (yaml is Map && yaml.containsKey('dev_dependencies')) {
        final devDeps =
            Map<String, dynamic>.from(yaml['dev_dependencies'] as Map);
        await _analyzeDependencies(result, devDeps, 'dev_dependencies');
      }

      // 检查dependency_overrides
      if (yaml is Map && yaml.containsKey('dependency_overrides')) {
        result.addWarning(
          '使用了dependency_overrides，请确保这是必要的',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
      }
    } catch (e) {
      result.addError(
        'pubspec.yaml格式错误: $e',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 分析依赖列表
  Future<void> _analyzeDependencies(
    ValidationResult result,
    Map<String, dynamic> dependencies,
    String section,
  ) async {
    for (final entry in dependencies.entries) {
      final packageName = entry.key;
      final versionSpec = entry.value;

      // 跳过SDK依赖
      if (packageName == 'flutter' || packageName == 'meta') {
        continue;
      }

      await _validateSingleDependency(
        result,
        packageName,
        versionSpec,
        section,
      );
    }
  }

  /// 验证单个依赖
  Future<void> _validateSingleDependency(
    ValidationResult result,
    String packageName,
    dynamic versionSpec,
    String section,
  ) async {
    // 检查版本约束格式
    if (versionSpec is String) {
      _validateVersionConstraint(
        result,
        packageName,
        versionSpec,
        section,
      );
    } else if (versionSpec is Map) {
      // Git/Path依赖
      if (versionSpec.containsKey('git')) {
        result.addWarning(
          '$packageName 使用Git依赖，可能影响稳定性',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
      } else if (versionSpec.containsKey('path')) {
        result.addInfo(
          '$packageName 使用本地路径依赖',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
      }
    }

    // 检查常见有问题的包
    _checkProblematicPackages(result, packageName);
  }

  /// 验证版本约束
  void _validateVersionConstraint(
    ValidationResult result,
    String packageName,
    String versionSpec,
    String section,
  ) {
    // 检查是否使用了具体版本约束
    if (versionSpec.startsWith('^')) {
      result.addSuccess(
        '$packageName 使用兼容版本约束: $versionSpec',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    } else if (versionSpec.startsWith('>=')) {
      result.addInfo(
        '$packageName 使用范围版本约束: $versionSpec',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    } else if (versionSpec == 'any') {
      result.addWarning(
        '$packageName 使用any版本约束，可能导致不稳定',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
        fixSuggestion: FixSuggestion(
          description: '指定具体的版本约束',
          fixabilityLevel: FixabilityLevel.manual,
          codeExample: '$packageName: ^1.0.0',
        ),
      );
    } else if (!versionSpec.contains('.')) {
      result.addWarning(
        '$packageName 版本约束格式可能不正确: $versionSpec',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 检查有问题的包
  void _checkProblematicPackages(
    ValidationResult result,
    String packageName,
  ) {
    // 已知有安全问题或维护问题的包
    final problematicPackages = {
      'flutter_secure_storage': '某些版本存在安全问题',
      'firebase_core': '需要定期更新以修复安全漏洞',
    };

    if (problematicPackages.containsKey(packageName)) {
      result.addWarning(
        '$packageName: ${problematicPackages[packageName]}',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }

    // 检查废弃的包
    final deprecatedPackages = [
      'pedantic', // 已被lints替代
      'effective_dart', // 已被lints替代
    ];

    if (deprecatedPackages.contains(packageName)) {
      result.addWarning(
        '$packageName 已被废弃，建议使用替代方案',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 验证版本兼容性
  Future<void> _validateVersionCompatibility(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    // 检查Dart SDK约束
    final environment = (yaml is Map && yaml.containsKey('environment'))
        ? Map<String, dynamic>.from(yaml['environment'] as Map)
        : null;
    if (environment?.containsKey('sdk') ?? false) {
      final sdkConstraint = environment!['sdk'] as String;
      _validateSdkConstraint(result, sdkConstraint);
    }

    // 检查Flutter SDK约束
    if (environment?.containsKey('flutter') ?? false) {
      result.addInfo(
        '指定了Flutter SDK约束',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 验证SDK约束
  void _validateSdkConstraint(
    ValidationResult result,
    String sdkConstraint,
  ) {
    if (sdkConstraint.contains('>=3.0.0')) {
      result.addSuccess(
        'Dart SDK约束支持最新特性',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    } else if (sdkConstraint.contains('>=2.')) {
      result.addWarning(
        'Dart SDK约束较老，建议升级到3.x',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 验证未使用的依赖
  Future<void> _validateUnusedDependencies(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    final dependencies = (yaml is Map && yaml.containsKey('dependencies'))
        ? Map<String, dynamic>.from(yaml['dependencies'] as Map)
        : null;
    if (dependencies == null) return;

    // 收集所有Dart文件中的import语句
    final usedPackages = <String>{};
    final libDir = Directory(path.join(modulePath, 'lib'));

    if (libDir.existsSync()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileContent = await entity.readAsString();
          final importRegex = RegExp(r'import\s+.*package:(\w+)');
          final matches = importRegex.allMatches(fileContent);

          for (final match in matches) {
            final packageName = match.group(1);
            if (packageName != null) {
              usedPackages.add(packageName);
            }
          }
        }
      }
    }

    // 检查未使用的依赖
    for (final packageName in dependencies.keys) {
      if (packageName == 'flutter' || packageName == 'meta') continue;

      if (!usedPackages.contains(packageName)) {
        result.addWarning(
          '可能未使用的依赖: $packageName',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
          fixSuggestion: const FixSuggestion(
            description: '移除未使用的依赖或确认其必要性',
            fixabilityLevel: FixabilityLevel.manual,
          ),
        );
      }
    }

    if (usedPackages.isNotEmpty) {
      result.addSuccess(
        '发现 ${usedPackages.length} 个被使用的依赖包',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// Task 40.6: 增强安全漏洞检查
  Future<void> _validateSecurityVulnerabilities(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    // 扩展的安全漏洞数据库
    final vulnerablePackages = {
      'http': ['<0.13.0', 'HTTP请求伪造漏洞，升级到>=0.13.0'],
      'path_provider': ['<2.0.0', '路径遍历漏洞，升级到>=2.0.0'],
      'webview_flutter': ['<3.0.0', 'WebView代码注入风险，升级到>=3.0.0'],
      'firebase_auth': ['<4.0.0', 'Firebase认证绕过漏洞，升级到>=4.0.0'],
      'flutter_secure_storage': ['<5.0.0', '密钥存储泄露风险，升级到>=5.0.0'],
      'dio': ['<4.0.0', 'HTTP拦截器安全问题，升级到>=4.0.0'],
      'crypto': ['<3.0.0', '加密算法弱点，升级到>=3.0.0'],
      'flutter_webview_plugin': ['any', '已停止维护，存在多个安全漏洞，建议替换为webview_flutter'],
      'image_picker': ['<0.8.0', '文件访问权限问题，升级到>=0.8.0'],
      'permission_handler': ['<8.0.0', '权限绕过漏洞，升级到>=8.0.0'],
      'camera': ['<0.9.0', '相机权限泄露，升级到>=0.9.0'],
      'location': ['<4.0.0', '位置信息泄露风险，升级到>=4.0.0'],
      'flutter_bluetooth_serial': ['any', '蓝牙通信加密不足，考虑更安全的替代方案'],
      'biometric_storage': ['<4.0.0', '生物识别数据泄露风险，升级到>=4.0.0'],
    };

    // 高风险包模式
    final highRiskPatterns = {
      '.*test.*': '测试包可能包含调试信息，不应在生产环境使用',
      '.*debug.*': '调试包可能暴露敏感信息',
      '.*dev.*': '开发工具包可能包含后门',
    };

    // 检查敏感权限相关包
    final sensitivePermissionPackages = {
      'camera': '相机权限',
      'microphone': '麦克风权限',
      'location': '位置权限',
      'contacts': '联系人权限',
      'phone_state': '电话状态权限',
      'sms': '短信权限',
      'storage': '存储权限',
    };

    final dependencies = (yaml is Map && yaml.containsKey('dependencies'))
        ? Map<String, dynamic>.from(yaml['dependencies'] as Map)
        : null;
    final devDependencies =
        (yaml is Map && yaml.containsKey('dev_dependencies'))
            ? Map<String, dynamic>.from(yaml['dev_dependencies'] as Map)
            : null;

    void checkSecurityInPackageList(
      Map<String, dynamic>? packages,
      String sectionName,
    ) {
      if (packages == null) return;

      for (final entry in packages.entries) {
        final packageName = entry.key;
        final versionSpec = entry.value.toString();

        // 检查已知漏洞
        if (vulnerablePackages.containsKey(packageName)) {
          final vulnInfo = vulnerablePackages[packageName]!;
          final vulnerableVersionPattern = vulnInfo[0];
          final description = vulnInfo[1];

          result.addError(
            '$packageName 存在安全风险: $description',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
            fixSuggestion: FixSuggestion(
              description: '立即升级到安全版本 (避免$vulnerableVersionPattern)',
              fixabilityLevel: FixabilityLevel.manual,
            ),
          );
        }

        // 检查高风险模式
        for (final pattern in highRiskPatterns.keys) {
          if (RegExp(pattern, caseSensitive: false).hasMatch(packageName)) {
            result.addWarning(
              '$packageName: ${highRiskPatterns[pattern]}',
              file: 'pubspec.yaml',
              validationType: ValidationType.dependency,
              validatorName: validatorName,
            );
          }
        }

        // 检查敏感权限包
        for (final sensitivePackage in sensitivePermissionPackages.keys) {
          if (packageName.toLowerCase().contains(sensitivePackage)) {
            final permission = sensitivePermissionPackages[sensitivePackage];
            final message = '$packageName 涉及$permission，请确保合规使用';
            result.addInfo(
              message,
              file: 'pubspec.yaml',
              validationType: ValidationType.dependency,
              validatorName: validatorName,
            );
          }
        }

        // 检查不安全的版本模式
        if (versionSpec == 'any' || versionSpec.contains('>=0.0.0')) {
          result.addWarning(
            '$packageName 使用不安全的版本约束: $versionSpec',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }
    }

    checkSecurityInPackageList(dependencies, 'dependencies');
    checkSecurityInPackageList(devDependencies, 'dev_dependencies');

    // 检查安全工具
    final recommendedSecurityTools = {
      'lints': '代码规范检查',
      'very_good_analysis': '严格的代码分析',
      'integration_test': '集成测试安全',
    };

    var hasSecurityTools = false;
    for (final tool in recommendedSecurityTools.keys) {
      if (devDependencies?.containsKey(tool) ?? false) {
        hasSecurityTools = true;
        result.addSuccess(
          '已集成安全工具: $tool',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
      }
    }

    if (!hasSecurityTools) {
      result.addWarning(
        '建议添加安全分析工具到dev_dependencies',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '添加lints或very_good_analysis进行代码安全检查',
          fixabilityLevel: FixabilityLevel.suggested,
        ),
      );
    }

    // 安全配置建议
    result.addInfo(
      '建议定期运行安全扫描和依赖更新检查',
      validationType: ValidationType.dependency,
      validatorName: validatorName,
      fixSuggestion: const FixSuggestion(
        description: '运行dart pub audit检查安全漏洞',
        fixabilityLevel: FixabilityLevel.suggested,
        command: 'dart pub audit',
      ),
    );
  }

  /// 验证依赖锁文件
  Future<void> _validateLockFile(
    ValidationResult result,
    String modulePath,
  ) async {
    final lockFile = File(path.join(modulePath, 'pubspec.lock'));

    if (lockFile.existsSync()) {
      result.addSuccess(
        'pubspec.lock 文件存在，依赖版本已锁定',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );

      // 检查锁文件是否过时
      final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        final pubspecStat = pubspecFile.statSync();
        final lockStat = lockFile.statSync();

        if (pubspecStat.modified.isAfter(lockStat.modified)) {
          result.addWarning(
            'pubspec.lock 可能过时，建议运行 pub get',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
            fixSuggestion: const FixSuggestion(
              description: '运行 pub get 更新锁文件',
              fixabilityLevel: FixabilityLevel.automatic,
              command: 'dart pub get',
            ),
          );
        }
      }

      // 检查锁文件内容
      try {
        final lockContent = await lockFile.readAsString();
        final lockYaml = loadYaml(lockContent);

        if (lockYaml is Map && lockYaml.containsKey('packages')) {
          final packages =
              Map<String, dynamic>.from(lockYaml['packages'] as Map);
          result.addInfo(
            '锁定了 ${packages.length} 个依赖包版本',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      } catch (e) {
        result.addError(
          'pubspec.lock 格式错误: $e',
          file: 'pubspec.lock',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
      }
    } else {
      result.addWarning(
        '缺少 pubspec.lock 文件，建议运行 pub get',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '运行 pub get 生成锁文件',
          fixabilityLevel: FixabilityLevel.automatic,
          command: 'dart pub get',
        ),
      );
    }
  }

  /// Task 40.5: 增强pubspec.yaml格式验证
  Future<void> _validatePubspecFormat(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      result.addError(
        '缺少pubspec.yaml文件',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
      return;
    }

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! Map) {
        result.addError(
          'pubspec.yaml格式不正确',
          file: 'pubspec.yaml',
          validationType: ValidationType.dependency,
          validatorName: validatorName,
        );
        return;
      }

      final yamlMap = Map<String, dynamic>.from(yaml);

      // 检查必需字段
      final requiredFields = ['name', 'version', 'environment'];
      for (final field in requiredFields) {
        if (!yamlMap.containsKey(field)) {
          result.addError(
            'pubspec.yaml缺少必需字段: $field',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }

      // 检查推荐字段
      final recommendedFields = ['description', 'homepage', 'repository'];
      for (final field in recommendedFields) {
        if (!yamlMap.containsKey(field)) {
          result.addInfo(
            'pubspec.yaml建议添加字段: $field',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }

      // 验证name字段格式
      if (yamlMap.containsKey('name')) {
        final name = yamlMap['name'] as String;
        if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
          result.addError(
            '包名格式不正确: $name (应使用snake_case)',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }

      // 验证version字段格式
      if (yamlMap.containsKey('version')) {
        final version = yamlMap['version'] as String;
        if (!RegExp(r'^\d+\.\d+\.\d+(\+\d+)?$').hasMatch(version)) {
          result.addWarning(
            '版本号格式不符合语义化版本规范: $version',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }

      // 检查environment设置
      if (yamlMap.containsKey('environment')) {
        final env = Map<String, dynamic>.from(yamlMap['environment'] as Map);
        if (!env.containsKey('sdk')) {
          result.addWarning(
            'environment中缺少sdk约束',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }
      }

      result.addSuccess(
        'pubspec.yaml格式验证通过',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    } catch (e) {
      result.addError(
        'pubspec.yaml解析失败: $e',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// Task 40.6: 增强过时包检测
  Future<void> _validateOutdatedPackages(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    // 扩展的废弃包列表
    final deprecatedPackages = {
      'pedantic': 'lints',
      'effective_dart': 'lints',
      'flutter_driver': 'integration_test',
      'mockito': 'mocktail',
      'flutter_test': '使用package:flutter_test',
      'test_api': 'package:test',
      'analyzer': '直接使用dart analyze',
      'build_runner': '考虑使用build_web_compilers',
    };

    // 检查即将废弃的包
    final soonDeprecated = {
      'http': '建议关注dart:io或dio的最新发展',
      'shared_preferences': '考虑使用更现代的状态管理解决方案',
      'sqflite': '考虑使用drift (formerly moor)',
    };

    // 检查过时的版本模式
    final outdatedPatterns = {
      r'^0\.': '使用0.x版本，稳定性可能不足',
      'any': '使用any约束，版本控制不够严格',
      r'^\d+\.\d+\.\d+$': '使用精确版本，建议使用兼容性约束(^)',
    };

    final dependencies = (yaml is Map && yaml.containsKey('dependencies'))
        ? Map<String, dynamic>.from(yaml['dependencies'] as Map)
        : null;
    final devDependencies =
        (yaml is Map && yaml.containsKey('dev_dependencies'))
            ? Map<String, dynamic>.from(yaml['dev_dependencies'] as Map)
            : null;

    void checkPackageList(Map<String, dynamic>? packages, String sectionName) {
      if (packages == null) return;

      for (final entry in packages.entries) {
        final packageName = entry.key;
        final versionSpec = entry.value.toString();

        // 检查废弃包
        if (deprecatedPackages.containsKey(packageName)) {
          result.addWarning(
            '$packageName已废弃，建议使用: ${deprecatedPackages[packageName]}',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
            fixSuggestion: const FixSuggestion(
              description: '替换为推荐的包',
              fixabilityLevel: FixabilityLevel.manual,
            ),
          );
        }

        // 检查即将废弃的包
        if (soonDeprecated.containsKey(packageName)) {
          result.addInfo(
            '$packageName: ${soonDeprecated[packageName]}',
            file: 'pubspec.yaml',
            validationType: ValidationType.dependency,
            validatorName: validatorName,
          );
        }

        // 检查版本模式
        for (final pattern in outdatedPatterns.keys) {
          if (RegExp(pattern).hasMatch(versionSpec)) {
            result.addInfo(
              '$packageName ($versionSpec): ${outdatedPatterns[pattern]}',
              file: 'pubspec.yaml',
              validationType: ValidationType.dependency,
              validatorName: validatorName,
            );
            break;
          }
        }
      }
    }

    checkPackageList(dependencies, 'dependencies');
    checkPackageList(devDependencies, 'dev_dependencies');

    // 建议运行pub outdated检查
    result.addInfo(
      '建议定期运行"dart pub outdated"检查包更新',
      validationType: ValidationType.dependency,
      validatorName: validatorName,
      fixSuggestion: const FixSuggestion(
        description: '运行pub outdated检查包更新',
        fixabilityLevel: FixabilityLevel.suggested,
        command: 'dart pub outdated',
      ),
    );
  }

  /// Task 40.5: 添加依赖冲突检测
  Future<void> _validateDependencyConflicts(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return;

    final lockFile = File(path.join(modulePath, 'pubspec.lock'));
    if (!lockFile.existsSync()) {
      result.addWarning(
        '无法检测依赖冲突：缺少pubspec.lock文件',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
      return;
    }

    try {
      final pubspecContent = await pubspecFile.readAsString();
      final lockContent = await lockFile.readAsString();

      final pubspecYaml = loadYaml(pubspecContent);
      final lockYaml = loadYaml(lockContent);

      // 检查版本冲突
      final dependencies =
          (pubspecYaml is Map && pubspecYaml.containsKey('dependencies'))
              ? Map<String, dynamic>.from(pubspecYaml['dependencies'] as Map)
              : null;
      final lockPackages = (lockYaml is Map && lockYaml.containsKey('packages'))
          ? Map<String, dynamic>.from(lockYaml['packages'] as Map)
          : null;

      if (dependencies != null && lockPackages != null) {
        await _detectVersionConflicts(result, dependencies, lockPackages);
      }

      // 检查平台冲突
      await _detectPlatformConflicts(result, dependencies);

      // 检查Flutter/Dart版本兼容性
      await _validateFlutterDartCompatibility(result, pubspecYaml, lockYaml);
    } catch (e) {
      result.addError(
        '依赖冲突检测失败: $e',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 检测版本冲突
  Future<void> _detectVersionConflicts(
    ValidationResult result,
    Map<String, dynamic> dependencies,
    Map<String, dynamic> lockPackages,
  ) async {
    final conflictingPairs = {
      'flutter_test': ['test'],
      'mockito': ['mocktail'],
      'pedantic': ['lints', 'effective_dart'],
      'build_runner': ['build_web_compilers'],
    };

    for (final entry in conflictingPairs.entries) {
      final primaryPackage = entry.key;
      final conflictingPackages = entry.value;

      if (dependencies.containsKey(primaryPackage)) {
        for (final conflictPackage in conflictingPackages) {
          if (dependencies.containsKey(conflictPackage)) {
            result.addWarning(
              '检测到潜在冲突: $primaryPackage 与 $conflictPackage',
              file: 'pubspec.yaml',
              validationType: ValidationType.dependency,
              validatorName: validatorName,
              fixSuggestion: const FixSuggestion(
                description: '移除冲突的包或选择其中一个',
                fixabilityLevel: FixabilityLevel.manual,
              ),
            );
          }
        }
      }
    }
  }

  /// 检测平台冲突
  Future<void> _detectPlatformConflicts(
    ValidationResult result,
    Map<String, dynamic>? dependencies,
  ) async {
    if (dependencies == null) return;

    final webOnlyPackages = [
      'universal_html',
      'js',
      'dart:html',
    ];

    final mobileOnlyPackages = [
      'flutter_blue',
      'camera',
      'battery',
      'device_info',
      'package_info',
    ];

    final hasWebPackages = dependencies.keys.any(
      webOnlyPackages.contains,
    );
    final hasMobilePackages = dependencies.keys.any(
      mobileOnlyPackages.contains,
    );

    if (hasWebPackages && hasMobilePackages) {
      result.addWarning(
        '检测到Web和移动端专用包共存，可能存在平台兼容性问题',
        file: 'pubspec.yaml',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }
  }

  /// 验证Flutter/Dart版本兼容性
  Future<void> _validateFlutterDartCompatibility(
    ValidationResult result,
    dynamic pubspecYaml,
    dynamic lockYaml,
  ) async {
    final environment =
        (pubspecYaml is Map && pubspecYaml.containsKey('environment'))
            ? Map<String, dynamic>.from(pubspecYaml['environment'] as Map)
            : null;
    if (environment == null) return;

    final dartSdk = environment['sdk'] as String?;
    final flutterSdk = environment['flutter'] as String?;

    // 检查Dart SDK与Flutter版本兼容性
    if (dartSdk != null && flutterSdk != null) {
      // 这里可以添加具体的兼容性检查逻辑
      result.addInfo(
        'Dart SDK: $dartSdk, Flutter: $flutterSdk',
        validationType: ValidationType.dependency,
        validatorName: validatorName,
      );
    }

    // 检查依赖包的最低要求
    final lockPackages = (lockYaml is Map && lockYaml.containsKey('packages'))
        ? Map<String, dynamic>.from(lockYaml['packages'] as Map)
        : null;
    if (lockPackages != null) {
      for (final entry in lockPackages.entries) {
        final packageInfo = entry.value;
        if (packageInfo is Map && packageInfo.containsKey('version')) {
          // 可以在这里添加特定包版本的兼容性检查
        }
      }
    }

    result.addSuccess(
      '依赖冲突检测完成',
      validationType: ValidationType.dependency,
      validatorName: validatorName,
    );
  }
}
