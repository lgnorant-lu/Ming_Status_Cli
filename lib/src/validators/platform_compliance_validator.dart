/*
---------------------------------------------------------------
File name:                  platform_compliance_validator.dart
Author:                     Ignorant-lu
Date created:               2025/07/03
Last modified:              2025/07/03
Dart Version:               3.32.4
Description:                平台规范验证器 - 验证Pet App平台模块规范和API兼容性
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - Pet App平台规范验证器实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/validation_system/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Pet App平台规范验证器
/// 验证模块是否符合Pet App平台标准和API兼容性要求
class PlatformComplianceValidator extends ModuleValidator {
  @override
  String get validatorName => 'platform';

  @override
  List<ValidationType> get supportedTypes => [ValidationType.compliance];

  @override
  int get priority => 40;

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    final result = ValidationResult(strictMode: context.strictMode);

    try {
      // Task 41.1: Pet App平台模块规范检查
      await _validatePetAppModuleStandards(result, modulePath);

      // Task 41.2: API兼容性检查
      await _validateApiCompatibility(result, modulePath);

      // Task 41.2: 接口规范验证
      await _validateInterfaceStandards(result, modulePath);

      // 模块配置验证
      await _validateModuleConfiguration(result, modulePath);

      // 导出规范验证
      await _validateExportStandards(result, modulePath);

      // 文档规范验证
      await _validateDocumentationStandards(result, modulePath);

      // 测试规范验证
      await _validateTestingStandards(result, modulePath);

      // 国际化规范验证
      await _validateInternationalizationStandards(result, modulePath);
    } catch (e) {
      result.addError(
        '平台规范验证过程发生异常: $e',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }

    result.markCompleted();
    return result;
  }

  /// Task 41.1: 验证Pet App平台模块标准
  Future<void> _validatePetAppModuleStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    // 检查模块类型定义
    await _validateModuleType(result, modulePath);

    // 检查模块生命周期
    await _validateModuleLifecycle(result, modulePath);

    // 检查模块依赖管理
    await _validateModuleDependencies(result, modulePath);

    // 检查模块权限定义
    await _validateModulePermissions(result, modulePath);

    // 检查平台特定配置
    await _validatePlatformConfiguration(result, modulePath);
  }

  /// 验证模块类型定义
  Future<void> _validateModuleType(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleFile = File(
      path.join(modulePath, 'lib', '${path.basename(modulePath)}_module.dart'),
    );

    if (!moduleFile.existsSync()) {
      result.addError(
        '缺少模块定义文件: ${path.basename(modulePath)}_module.dart',
        file: 'lib/${path.basename(modulePath)}_module.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建模块定义文件并实现ModuleInterface',
          fixabilityLevel: FixabilityLevel.manual,
        ),
      );
      return;
    }

    final content = await moduleFile.readAsString();

    // 检查是否实现了ModuleInterface
    if (!content.contains('implements ModuleInterface') &&
        !content.contains('extends ModuleInterface')) {
      result.addError(
        '模块必须实现ModuleInterface接口',
        file: 'lib/${path.basename(modulePath)}_module.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }

    // 检查必需的模块方法
    final requiredMethods = [
      'initialize',
      'dispose',
      'getModuleInfo',
      'registerRoutes',
    ];

    for (final method in requiredMethods) {
      if (!content.contains(method)) {
        result.addWarning(
          '缺少必需的模块方法: $method',
          file: 'lib/${path.basename(modulePath)}_module.dart',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }

    result.addSuccess(
      '模块类型定义验证通过',
      file: 'lib/${path.basename(modulePath)}_module.dart',
      validationType: ValidationType.compliance,
      validatorName: validatorName,
    );
  }

  /// 验证模块生命周期
  Future<void> _validateModuleLifecycle(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleFile = File(
      path.join(modulePath, 'lib', '${path.basename(modulePath)}_module.dart'),
    );

    if (!moduleFile.existsSync()) return;

    final content = await moduleFile.readAsString();

    // 检查生命周期方法实现
    final lifecycleMethods = {
      'onModuleLoad': '模块加载时调用',
      'onModuleUnload': '模块卸载时调用',
      'onConfigChanged': '配置变更时调用',
      'onPermissionChanged': '权限变更时调用',
    };

    var implementedCount = 0;
    for (final entry in lifecycleMethods.entries) {
      if (content.contains(entry.key)) {
        implementedCount++;
        result.addSuccess(
          '实现了生命周期方法: ${entry.key}',
          file: 'lib/${path.basename(modulePath)}_module.dart',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      } else {
        result.addInfo(
          '建议实现生命周期方法: ${entry.key} - ${entry.value}',
          file: 'lib/${path.basename(modulePath)}_module.dart',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }

    if (implementedCount >= 2) {
      result.addSuccess(
        '模块生命周期管理良好',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证模块依赖管理
  Future<void> _validateModuleDependencies(
    ValidationResult result,
    String modulePath,
  ) async {
    // 检查module.yaml文件
    final moduleConfigFile = File(path.join(modulePath, 'module.yaml'));

    if (!moduleConfigFile.existsSync()) {
      result.addWarning(
        '缺少module.yaml配置文件',
        file: 'module.yaml',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    try {
      final content = await moduleConfigFile.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! Map) {
        result.addError(
          'module.yaml格式错误，必须是有效的YAML映射',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
        return;
      }

      // 检查模块依赖定义
      if (yaml.containsKey('dependencies')) {
        final deps = yaml['dependencies'];

        // 检查核心依赖
        final coreDependencies = [
          'core_services',
          'ui_framework',
        ];

        for (final coreDep in coreDependencies) {
          if (deps is Map && !deps.containsKey(coreDep)) {
            result.addWarning(
              '缺少核心依赖: $coreDep',
              file: 'module.yaml',
              validationType: ValidationType.compliance,
              validatorName: validatorName,
            );
          }
        }

        // 验证核心服务列表
        if (deps is Map && deps.containsKey('core_services')) {
          final coreServices = deps['core_services'];
          if (coreServices is List) {
            final validServices = [
              'logging_service',
              'config_service',
              'cache_service',
              'event_bus_service',
              'auth_service',
              'notification_service',
            ];

            for (final service in coreServices) {
              if (!validServices.contains(service)) {
                result.addError(
                  '核心服务依赖无效: $service',
                  file: 'module.yaml',
                  validationType: ValidationType.compliance,
                  validatorName: validatorName,
                );
              }
            }
          }
        }

        result.addSuccess(
          '模块依赖定义完整',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          'module.yaml中缺少dependencies定义',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    } catch (e) {
      result.addError(
        'module.yaml解析错误: $e',
        file: 'module.yaml',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证模块权限定义
  Future<void> _validateModulePermissions(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleConfigFile = File(path.join(modulePath, 'module.yaml'));

    if (!moduleConfigFile.existsSync()) return;

    try {
      final content = await moduleConfigFile.readAsString();
      final yaml = loadYaml(content);

      if (yaml is! Map) return;

      // 检查权限定义 - 支持Map和List两种格式
      if (yaml.containsKey('permissions')) {
        final permissions = yaml['permissions'];

        if (permissions is Map) {
          // Map格式权限（支持required/optional/dangerous分类）
          for (final entry in permissions.entries) {
            final category = entry.key as String;
            final permList = entry.value;

            if (permList is List) {
              for (final permission in permList) {
                result.addInfo(
                  '检测到权限定义: $category - $permission',
                  file: 'module.yaml',
                  validationType: ValidationType.compliance,
                  validatorName: validatorName,
                );
              }
            }
          }

          result.addSuccess(
            '模块权限定义符合规范',
            file: 'module.yaml',
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        } else if (permissions is List) {
          // List格式权限（传统格式）
          for (final permission in permissions) {
            if (permission is! Map) {
              result.addError(
                '权限定义格式错误: $permission',
                file: 'module.yaml',
                validationType: ValidationType.compliance,
                validatorName: validatorName,
              );
              continue;
            }

            final permMap = permission;
            if (!permMap.containsKey('name') ||
                !permMap.containsKey('description')) {
              result.addWarning(
                '权限定义缺少必需字段: name/description',
                file: 'module.yaml',
                validationType: ValidationType.compliance,
                validatorName: validatorName,
              );
            }
          }

          result.addSuccess(
            '模块权限定义符合规范',
            file: 'module.yaml',
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        }
      } else {
        result.addInfo(
          '模块未定义特殊权限',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }

      // 检查安全约束定义
      if (yaml.containsKey('security')) {
        final security = yaml['security'];
        if (security is Map) {
          final requiredSecurityFields = [
            'encryption_required',
            'audit_logging',
            'sensitive_data_access',
          ];

          for (final field in requiredSecurityFields) {
            if (security.containsKey(field)) {
              result.addSuccess(
                '安全约束配置: $field = ${security[field]}',
                file: 'module.yaml',
                validationType: ValidationType.compliance,
                validatorName: validatorName,
              );
            }
          }
        }
      }
    } catch (e) {
      result.addError(
        '权限配置解析错误: $e',
        file: 'module.yaml',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证平台特定配置
  Future<void> _validatePlatformConfiguration(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleConfigFile = File(path.join(modulePath, 'module.yaml'));

    if (!moduleConfigFile.existsSync()) return;

    final content = await moduleConfigFile.readAsString();
    final yaml = loadYaml(content) as Map;

    // 检查平台配置
    final platformConfigs = ['android', 'ios', 'web', 'desktop'];
    var supportedPlatforms = 0;

    for (final platform in platformConfigs) {
      if (yaml.containsKey(platform)) {
        supportedPlatforms++;
        result.addSuccess(
          '支持$platform平台配置',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }

    if (supportedPlatforms == 0) {
      result.addWarning(
        '未配置任何平台特定设置',
        file: 'module.yaml',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// Task 41.2: 验证API兼容性
  Future<void> _validateApiCompatibility(
    ValidationResult result,
    String modulePath,
  ) async {
    // 检查API版本兼容性
    await _validateApiVersion(result, modulePath);

    // 检查接口签名兼容性
    await _validateInterfaceSignatures(result, modulePath);

    // 检查数据模型兼容性
    await _validateDataModelCompatibility(result, modulePath);

    // 检查事件系统兼容性
    await _validateEventSystemCompatibility(result, modulePath);
  }

  /// 验证API版本兼容性
  Future<void> _validateApiVersion(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) return;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as Map;

    // 检查API版本
    if (yaml.containsKey('version')) {
      final version = yaml['version'] as String;
      final versionParts = version.split('.');

      if (versionParts.length >= 2) {
        final majorVersion = int.tryParse(versionParts[0]);
        if (majorVersion != null && majorVersion > 0) {
          result.addSuccess(
            '模块版本符合API兼容性要求: $version',
            file: 'pubspec.yaml',
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        } else {
          result.addWarning(
            '建议使用稳定版本号(>= 1.0.0)',
            file: 'pubspec.yaml',
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        }
      }
    }

    // 检查核心服务依赖版本
    if (yaml.containsKey('dependencies')) {
      final deps = yaml['dependencies'] as Map;

      if (deps.containsKey('core_services')) {
        result.addSuccess(
          '已依赖核心服务，API兼容性良好',
          file: 'pubspec.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          '建议依赖core_services确保API兼容性',
          file: 'pubspec.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }
  }

  /// 验证接口签名兼容性
  Future<void> _validateInterfaceSignatures(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));

    if (!libDir.existsSync()) return;

    // 查找接口定义文件
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();

        // 检查抽象类和接口定义
        if (content.contains('abstract class') || content.contains('mixin')) {
          // 检查方法签名规范
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trim();

            // 检查异步方法返回类型
            if (line.contains('Future') && line.contains('(')) {
              if (!line.contains('Future<')) {
                result.addWarning(
                  '异步方法应明确返回类型: ${entity.path}:${i + 1}',
                  file: path.relative(entity.path, from: modulePath),
                  line: i + 1,
                  validationType: ValidationType.compliance,
                  validatorName: validatorName,
                );
              }
            }
          }
        }
      }
    }

    result.addSuccess(
      '接口签名兼容性检查完成',
      validationType: ValidationType.compliance,
      validatorName: validatorName,
    );
  }

  /// 验证数据模型兼容性
  Future<void> _validateDataModelCompatibility(
    ValidationResult result,
    String modulePath,
  ) async {
    final modelsDir = Directory(path.join(modulePath, 'lib', 'models'));

    if (!modelsDir.existsSync()) {
      result.addInfo(
        '未找到models目录，跳过数据模型兼容性检查',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    await for (final entity in modelsDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();

        // 检查JSON序列化支持
        if (content.contains('toJson') && content.contains('fromJson')) {
          result.addSuccess(
            '数据模型支持JSON序列化: ${path.basename(entity.path)}',
            file: path.relative(entity.path, from: modulePath),
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        } else if (content.contains('class ')) {
          result.addWarning(
            '数据模型建议实现JSON序列化: ${path.basename(entity.path)}',
            file: path.relative(entity.path, from: modulePath),
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        }
      }
    }
  }

  /// 验证事件系统兼容性
  Future<void> _validateEventSystemCompatibility(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));

    if (!libDir.existsSync()) return;

    var hasEventHandling = false;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();

        // 检查事件处理
        if (content.contains('EventBus') ||
            content.contains('StreamController') ||
            content.contains('Stream<')) {
          hasEventHandling = true;
          result.addSuccess(
            '模块支持事件系统: ${path.basename(entity.path)}',
            file: path.relative(entity.path, from: modulePath),
            validationType: ValidationType.compliance,
            validatorName: validatorName,
          );
        }
      }
    }

    if (!hasEventHandling) {
      result.addInfo(
        '模块未使用事件系统，如需模块间通信建议集成EventBus',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// Task 41.2: 验证接口规范
  Future<void> _validateInterfaceStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    // 检查公共接口导出
    await _validatePublicInterfaceExports(result, modulePath);

    // 检查接口文档
    await _validateInterfaceDocumentation(result, modulePath);

    // 检查错误处理规范
    await _validateErrorHandlingStandards(result, modulePath);
  }

  /// 验证公共接口导出
  Future<void> _validatePublicInterfaceExports(
    ValidationResult result,
    String modulePath,
  ) async {
    final mainLibFile = File(
      path.join(modulePath, 'lib', '${path.basename(modulePath)}.dart'),
    );

    if (!mainLibFile.existsSync()) {
      result.addError(
        '缺少主导出文件: ${path.basename(modulePath)}.dart',
        file: 'lib/${path.basename(modulePath)}.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建主导出文件并导出公共接口',
          fixabilityLevel: FixabilityLevel.manual,
        ),
      );
      return;
    }

    final content = await mainLibFile.readAsString();

    // 检查是否有导出语句
    if (!content.contains('export ')) {
      result.addWarning(
        '主导出文件应包含export语句',
        file: 'lib/${path.basename(modulePath)}.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    } else {
      result.addSuccess(
        '公共接口导出规范正确',
        file: 'lib/${path.basename(modulePath)}.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证接口文档
  Future<void> _validateInterfaceDocumentation(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));

    if (!libDir.existsSync()) return;

    var publicClassCount = 0;
    var documentedClassCount = 0;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          // 检查公共类定义
          if (line.startsWith('class ') && !line.startsWith('class _')) {
            publicClassCount++;

            // 检查前面是否有文档注释
            if (i > 0 && lines[i - 1].trim().startsWith('///')) {
              documentedClassCount++;
            }
          }
        }
      }
    }

    if (publicClassCount > 0) {
      final documentationRate =
          (documentedClassCount / publicClassCount * 100).round();

      if (documentationRate >= 80) {
        result.addSuccess(
          '接口文档覆盖率良好: $documentationRate%',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      } else if (documentationRate >= 50) {
        result.addWarning(
          '接口文档覆盖率偏低: $documentationRate%，建议提升至80%以上',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      } else {
        result.addError(
          '接口文档覆盖率严重不足: $documentationRate%',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }
  }

  /// 验证错误处理规范
  Future<void> _validateErrorHandlingStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));

    if (!libDir.existsSync()) return;

    var hasCustomExceptions = false;
    var hasTryCatchBlocks = false;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();

        // 检查自定义异常
        if (content.contains('Exception') || content.contains('Error')) {
          hasCustomExceptions = true;
        }

        // 检查错误处理
        if (content.contains('try {') && content.contains('catch')) {
          hasTryCatchBlocks = true;
        }
      }
    }

    if (hasCustomExceptions) {
      result.addSuccess(
        '模块定义了适当的异常类型',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }

    if (hasTryCatchBlocks) {
      result.addSuccess(
        '模块实现了错误处理机制',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        '建议添加适当的错误处理',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证模块配置
  Future<void> _validateModuleConfiguration(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleConfigFile = File(path.join(modulePath, 'module.yaml'));

    if (!moduleConfigFile.existsSync()) {
      result.addWarning(
        '建议添加module.yaml配置文件',
        file: 'module.yaml',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    final content = await moduleConfigFile.readAsString();
    final yaml = loadYaml(content) as Map;

    // 检查必需配置项
    final requiredFields = ['name', 'version', 'description', 'author'];
    for (final field in requiredFields) {
      if (!yaml.containsKey(field)) {
        result.addWarning(
          'module.yaml缺少必需字段: $field',
          file: 'module.yaml',
          validationType: ValidationType.compliance,
          validatorName: validatorName,
        );
      }
    }

    result.addSuccess(
      '模块配置验证完成',
      file: 'module.yaml',
      validationType: ValidationType.compliance,
      validatorName: validatorName,
    );
  }

  /// 验证导出规范
  Future<void> _validateExportStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    final mainFile = File(
      path.join(modulePath, 'lib', '${path.basename(modulePath)}.dart'),
    );

    if (!mainFile.existsSync()) return;

    final content = await mainFile.readAsString();
    final lines = content.split('\n');

    var exportCount = 0;
    var hasDocumentation = false;

    for (final line in lines) {
      if (line.trim().startsWith('export ')) {
        exportCount++;
      }
      if (line.trim().startsWith('///')) {
        hasDocumentation = true;
      }
    }

    if (exportCount > 0) {
      result.addSuccess(
        '模块导出了 $exportCount 个公共接口',
        file: 'lib/${path.basename(modulePath)}.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }

    if (hasDocumentation) {
      result.addSuccess(
        '主文件包含文档说明',
        file: 'lib/${path.basename(modulePath)}.dart',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证文档规范
  Future<void> _validateDocumentationStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    final readmeFile = File(path.join(modulePath, 'README.md'));

    if (!readmeFile.existsSync()) {
      result.addWarning(
        '缺少README.md文档',
        file: 'README.md',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    final content = await readmeFile.readAsString();

    // 检查文档内容
    final requiredSections = [
      '## 功能介绍',
      '## 使用方法',
      '## API文档',
    ];

    var foundSections = 0;
    for (final section in requiredSections) {
      if (content.contains(section)) {
        foundSections++;
      }
    }

    if (foundSections >= 2) {
      result.addSuccess(
        'README.md文档内容完整',
        file: 'README.md',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        'README.md建议包含更多标准章节',
        file: 'README.md',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证测试规范
  Future<void> _validateTestingStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    final testDir = Directory(path.join(modulePath, 'test'));

    if (!testDir.existsSync()) {
      result.addWarning(
        '缺少test目录，建议添加单元测试',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    var testFileCount = 0;
    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        testFileCount++;
      }
    }

    if (testFileCount > 0) {
      result.addSuccess(
        '模块包含 $testFileCount 个测试文件',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        '建议添加单元测试文件',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }

  /// 验证国际化规范
  Future<void> _validateInternationalizationStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    final l10nDir = Directory(path.join(modulePath, 'lib', 'l10n'));

    if (!l10nDir.existsSync()) {
      result.addInfo(
        '模块未配置国际化支持',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
      return;
    }

    var arbFileCount = 0;
    await for (final entity in l10nDir.list()) {
      if (entity is File && entity.path.endsWith('.arb')) {
        arbFileCount++;
      }
    }

    if (arbFileCount >= 2) {
      result.addSuccess(
        '模块支持多语言国际化 ($arbFileCount 种语言)',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    } else if (arbFileCount == 1) {
      result.addInfo(
        '模块配置了国际化基础，建议添加更多语言支持',
        validationType: ValidationType.compliance,
        validatorName: validatorName,
      );
    }
  }
}
