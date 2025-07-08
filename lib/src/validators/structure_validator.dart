/*
---------------------------------------------------------------
File name:          structure_validator.dart
Author:             Ignorant-lu
Date created:       2025/07/03
Last modified:      2025/07/03
Dart Version:       3.32.4
Description:        模块结构验证器 - 验证项目文件结构和组织规范
---------------------------------------------------------------
Change History:
    2025/07/03: Initial creation - 模块结构验证器实现;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:ming_status_cli/src/core/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';

/// 模块结构验证器
/// 验证项目的文件结构、目录组织和命名规范
class StructureValidator extends ModuleValidator {
  @override
  String get validatorName => 'structure';

  @override
  List<ValidationType> get supportedTypes => [ValidationType.structure];

  @override
  int get priority => 10; // 结构验证优先级最高

  @override
  Future<ValidationResult> validate(
    String modulePath,
    ValidationContext context,
  ) async {
    final result = ValidationResult(strictMode: context.strictMode);
    
    try {
      // 基础文件结构验证
      await _validateBasicStructure(result, modulePath);
      
      // pubspec.yaml验证
      await _validatePubspecYaml(result, modulePath);
      
      // 源码目录验证
      await _validateSourceStructure(result, modulePath);
      
      // 测试目录验证
      await _validateTestStructure(result, modulePath);
      
      // 文档文件验证
      await _validateDocumentation(result, modulePath);
      
      // 命名规范验证
      await _validateNamingConventions(result, modulePath);
      
      // Git忽略文件验证
      await _validateGitIgnore(result, modulePath);
      
      // Pet App平台标准验证
      await _validatePetAppPlatformStandards(result, modulePath);
      
    } catch (e) {
      result.addError(
        '结构验证过程发生异常: $e',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
    
    result.markCompleted();
    return result;
  }

  /// 验证基础文件结构
  Future<void> _validateBasicStructure(
    ValidationResult result,
    String modulePath,
  ) async {
    final requiredDirs = ['lib'];
    final recommendedDirs = ['test', 'doc', 'example'];
    final requiredFiles = ['pubspec.yaml'];
    final recommendedFiles = ['README.md', 'CHANGELOG.md'];

    // 检查必需目录
    for (final dirName in requiredDirs) {
      final dir = Directory(path.join(modulePath, dirName));
      if (await dir.exists()) {
        result.addSuccess(
          '必需目录存在: $dirName/',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addError(
          '缺少必需目录: $dirName/',
          validationType: ValidationType.structure,
          validatorName: validatorName,
          fixSuggestion: FixSuggestion(
            description: '创建 $dirName 目录',
            fixabilityLevel: FixabilityLevel.automatic,
            command: 'mkdir -p $dirName',
          ),
        );
      }
    }

    // 检查推荐目录
    for (final dirName in recommendedDirs) {
      final dir = Directory(path.join(modulePath, dirName));
      if (await dir.exists()) {
        result.addSuccess(
          '推荐目录存在: $dirName/',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          '缺少推荐目录: $dirName/',
          validationType: ValidationType.structure,
          validatorName: validatorName,
          fixSuggestion: FixSuggestion(
            description: '创建 $dirName 目录',
            fixabilityLevel: FixabilityLevel.suggested,
            command: 'mkdir -p $dirName',
          ),
        );
      }
    }

    // 检查必需文件
    for (final fileName in requiredFiles) {
      final file = File(path.join(modulePath, fileName));
      if (await file.exists()) {
        result.addSuccess(
          '必需文件存在: $fileName',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addError(
          '缺少必需文件: $fileName',
          validationType: ValidationType.structure,
          validatorName: validatorName,
          fixSuggestion: FixSuggestion(
            description: '创建 $fileName 文件',
            fixabilityLevel: FixabilityLevel.manual,
            codeExample: '''
name: my_package
version: 1.0.0
description: A new Dart package
environment:
  sdk: '>=3.0.0 <4.0.0'
''',
          ),
        );
      }
    }

    // 检查推荐文件
    for (final fileName in recommendedFiles) {
      final file = File(path.join(modulePath, fileName));
      if (await file.exists()) {
        result.addSuccess(
          '推荐文件存在: $fileName',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          '缺少推荐文件: $fileName',
          validationType: ValidationType.structure,
          validatorName: validatorName,
          fixSuggestion: FixSuggestion(
            description: '创建 $fileName 文件',
            fixabilityLevel: FixabilityLevel.suggested,
          ),
        );
      }
    }
  }

  /// 验证pubspec.yaml文件
  Future<void> _validatePubspecYaml(
    ValidationResult result,
    String modulePath,
  ) async {
    final pubspecFile = File(path.join(modulePath, 'pubspec.yaml'));
    
    if (!await pubspecFile.exists()) {
      return; // 已在基础结构验证中处理
    }

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as Map;

      // 检查必需字段
      final requiredFields = ['name', 'version', 'description'];
      for (final field in requiredFields) {
        if (yaml.containsKey(field) && yaml[field] != null) {
          result.addSuccess(
            'pubspec.yaml包含必需字段: $field',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        } else {
          result.addError(
            'pubspec.yaml缺少必需字段: $field',
            file: 'pubspec.yaml',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      }

      // 检查environment字段
      if (yaml.containsKey('environment')) {
        final env = yaml['environment'] as Map?;
        if (env?.containsKey('sdk') == true) {
          result.addSuccess(
            'pubspec.yaml包含SDK约束',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        } else {
          result.addWarning(
            'pubspec.yaml缺少SDK约束',
            file: 'pubspec.yaml',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      } else {
        result.addWarning(
          'pubspec.yaml缺少environment字段',
          file: 'pubspec.yaml',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }

    } catch (e) {
      result.addError(
        'pubspec.yaml格式错误: $e',
        file: 'pubspec.yaml',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }

  /// 验证源码目录结构
  Future<void> _validateSourceStructure(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    
    if (!await libDir.exists()) {
      return; // 已在基础结构验证中处理
    }

    // 检查lib目录结构
    final srcDir = Directory(path.join(modulePath, 'lib', 'src'));
    if (await srcDir.exists()) {
      result.addSuccess(
        'lib/src/ 目录结构规范',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
      
      // 检查src子目录组织
      await _validateSrcSubdirectories(result, srcDir.path);
    } else {
      result.addInfo(
        '未使用 lib/src/ 目录结构（可选）',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }

    // 检查主库文件
    await _validateMainLibraryFile(result, libDir.path);
  }

  /// 验证src子目录组织
  Future<void> _validateSrcSubdirectories(
    ValidationResult result,
    String srcPath,
  ) async {
    final commonDirs = ['models', 'services', 'utils', 'widgets', 'screens'];
    var hasOrganization = false;

    for (final dirName in commonDirs) {
      final dir = Directory(path.join(srcPath, dirName));
      if (await dir.exists()) {
        hasOrganization = true;
        result.addSuccess(
          '良好的目录组织: src/$dirName/',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    }

    if (!hasOrganization) {
      result.addInfo(
        'src/ 目录可以进一步按功能组织',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }

  /// 验证主库文件
  Future<void> _validateMainLibraryFile(
    ValidationResult result,
    String libPath,
  ) async {
    // 查找主库文件（通常与包名同名）
    await for (final entity in Directory(libPath).list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        if (!fileName.startsWith('_')) {
          result.addSuccess(
            '主库文件存在: $fileName',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
          return;
        }
      }
    }

    result.addWarning(
      'lib/ 目录下缺少主库文件',
      validationType: ValidationType.structure,
      validatorName: validatorName,
    );
  }

  /// 验证测试目录结构
  Future<void> _validateTestStructure(
    ValidationResult result,
    String modulePath,
  ) async {
    final testDir = Directory(path.join(modulePath, 'test'));
    
    if (!await testDir.exists()) {
      result.addWarning(
        '缺少测试目录',
        validationType: ValidationType.structure,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建测试目录和示例测试文件',
          fixabilityLevel: FixabilityLevel.suggested,
        ),
      );
      return;
    }

    var hasTests = false;
    await for (final entity in testDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        hasTests = true;
        break;
      }
    }

    if (hasTests) {
      result.addSuccess(
        '包含测试文件',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    } else {
      result.addWarning(
        'test/ 目录存在但没有测试文件',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }

  /// 验证文档文件
  Future<void> _validateDocumentation(
    ValidationResult result,
    String modulePath,
  ) async {
    final readmeFile = File(path.join(modulePath, 'README.md'));
    
    if (await readmeFile.exists()) {
      final content = await readmeFile.readAsString();
      if (content.length > 100) {
        result.addSuccess(
          'README.md 内容充实',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          'README.md 内容较少',
          file: 'README.md',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    }

    // 检查API文档
    final docDir = Directory(path.join(modulePath, 'doc'));
    if (await docDir.exists()) {
      result.addSuccess(
        '包含文档目录',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }

  /// 验证命名规范
  Future<void> _validateNamingConventions(
    ValidationResult result,
    String modulePath,
  ) async {
    // 验证目录命名（snake_case）
    await _validateDirectoryNaming(result, modulePath);
    
    // 验证文件命名（snake_case）
    await _validateFileNaming(result, modulePath);
  }

  /// 验证目录命名规范
  Future<void> _validateDirectoryNaming(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!await libDir.exists()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is Directory) {
        final dirName = path.basename(entity.path);
        if (_isValidSnakeCase(dirName)) {
          result.addSuccess(
            '目录命名规范: $dirName',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        } else {
          result.addWarning(
            '目录命名不规范: $dirName (应使用snake_case)',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      }
    }
  }

  /// 验证文件命名规范
  Future<void> _validateFileNaming(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!await libDir.exists()) return;

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basenameWithoutExtension(entity.path);
        if (_isValidSnakeCase(fileName)) {
          result.addSuccess(
            '文件命名规范: $fileName.dart',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        } else {
          result.addWarning(
            '文件命名不规范: $fileName.dart (应使用snake_case)',
            file: path.relative(entity.path, from: modulePath),
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      }
    }
  }

  /// 验证Git忽略文件
  Future<void> _validateGitIgnore(
    ValidationResult result,
    String modulePath,
  ) async {
    final gitignoreFile = File(path.join(modulePath, '.gitignore'));
    
    if (await gitignoreFile.exists()) {
      final content = await gitignoreFile.readAsString();
      final requiredPatterns = ['.dart_tool/', 'build/', '.packages'];
      final missingPatterns = <String>[];

      for (final pattern in requiredPatterns) {
        if (!content.contains(pattern)) {
          missingPatterns.add(pattern);
        }
      }

      if (missingPatterns.isEmpty) {
        result.addSuccess(
          '.gitignore 配置完整',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      } else {
        result.addWarning(
          '.gitignore 缺少必要忽略规则: ${missingPatterns.join(', ')}',
          file: '.gitignore',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    } else {
      result.addWarning(
        '缺少 .gitignore 文件',
        validationType: ValidationType.structure,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建 .gitignore 文件',
          fixabilityLevel: FixabilityLevel.automatic,
        ),
      );
    }
  }

  /// 检查是否为有效的snake_case命名
  bool _isValidSnakeCase(String name) {
    // 允许字母、数字、下划线，以字母开头
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  /// 验证Pet App平台标准
  Future<void> _validatePetAppPlatformStandards(
    ValidationResult result,
    String modulePath,
  ) async {
    // 检查module.yaml文件
    await _validateModuleYaml(result, modulePath);
    
    // 检查平台标准目录结构
    await _validatePlatformDirectoryStructure(result, modulePath);
    
    // 检查国际化目录
    await _validateInternationalization(result, modulePath);
    
    // 检查示例目录
    await _validateExampleDirectory(result, modulePath);
    
    // 检查资源目录
    await _validateAssetsDirectory(result, modulePath);
  }

  /// 验证module.yaml文件
  Future<void> _validateModuleYaml(
    ValidationResult result,
    String modulePath,
  ) async {
    final moduleYamlFile = File(path.join(modulePath, 'module.yaml'));
    
    if (await moduleYamlFile.exists()) {
      result.addSuccess(
        'Pet App模块配置文件存在: module.yaml',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
      
      // 验证module.yaml内容
      try {
        final content = await moduleYamlFile.readAsString();
        if (content.contains('name:') && content.contains('version:')) {
          result.addSuccess(
            'module.yaml包含必需字段',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        } else {
          result.addWarning(
            'module.yaml缺少必需字段(name, version)',
            file: 'module.yaml',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      } catch (e) {
        result.addError(
          'module.yaml格式错误: $e',
          file: 'module.yaml',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    } else {
      result.addInfo(
        '可选的Pet App模块配置文件: module.yaml',
        validationType: ValidationType.structure,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建module.yaml配置文件',
          fixabilityLevel: FixabilityLevel.suggested,
          codeExample: '''
name: my_module
version: 1.0.0
description: Pet App模块
author: Your Name
platform_version: "^1.0.0"
''',
        ),
      );
    }
  }

  /// 验证平台标准目录结构
  Future<void> _validatePlatformDirectoryStructure(
    ValidationResult result,
    String modulePath,
  ) async {
    final libDir = Directory(path.join(modulePath, 'lib'));
    if (!await libDir.exists()) return;

    final srcDir = Directory(path.join(modulePath, 'lib', 'src'));
    if (await srcDir.exists()) {
      // 检查Pet App平台推荐的子目录组织
      final platformDirs = ['services', 'widgets', 'models', 'utils'];
      var hasPlatformOrganization = false;

      for (final dirName in platformDirs) {
        final dir = Directory(path.join(srcDir.path, dirName));
        if (await dir.exists()) {
          hasPlatformOrganization = true;
          result.addSuccess(
            'Pet App平台标准目录: src/$dirName/',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      }

      if (!hasPlatformOrganization) {
        result.addInfo(
          '建议使用Pet App平台标准目录组织(services, widgets, models, utils)',
          validationType: ValidationType.structure,
          validatorName: validatorName,
          fixSuggestion: const FixSuggestion(
            description: '创建Pet App平台标准目录结构',
            fixabilityLevel: FixabilityLevel.suggested,
            command: 'mkdir -p lib/src/{services,widgets,models,utils}',
          ),
        );
      }
    }
  }

  /// 验证国际化目录
  Future<void> _validateInternationalization(
    ValidationResult result,
    String modulePath,
  ) async {
    final l10nDir = Directory(path.join(modulePath, 'lib', 'l10n'));
    
    if (await l10nDir.exists()) {
      result.addSuccess(
        'Pet App国际化支持: lib/l10n/',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
      
      // 检查ARB文件
      var hasArbFiles = false;
      await for (final entity in l10nDir.list()) {
        if (entity is File && entity.path.endsWith('.arb')) {
          hasArbFiles = true;
          break;
        }
      }
      
      if (hasArbFiles) {
        result.addSuccess(
          '包含ARB国际化文件',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    } else {
      result.addInfo(
        '可添加国际化支持(lib/l10n/)',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }

  /// 验证示例目录
  Future<void> _validateExampleDirectory(
    ValidationResult result,
    String modulePath,
  ) async {
    final exampleDir = Directory(path.join(modulePath, 'example'));
    
    if (await exampleDir.exists()) {
      result.addSuccess(
        'Pet App使用示例: example/',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
      
      // 检查示例文件
      final exampleDart = File(path.join(exampleDir.path, 'main.dart'));
      if (await exampleDart.exists()) {
        result.addSuccess(
          '包含可执行示例',
          validationType: ValidationType.structure,
          validatorName: validatorName,
        );
      }
    } else {
      result.addInfo(
        '建议添加使用示例(example/)',
        validationType: ValidationType.structure,
        validatorName: validatorName,
        fixSuggestion: const FixSuggestion(
          description: '创建example目录和示例文件',
          fixabilityLevel: FixabilityLevel.suggested,
          command: 'mkdir -p example',
        ),
      );
    }
  }

  /// 验证资源目录
  Future<void> _validateAssetsDirectory(
    ValidationResult result,
    String modulePath,
  ) async {
    final assetsDir = Directory(path.join(modulePath, 'assets'));
    
    if (await assetsDir.exists()) {
      result.addSuccess(
        'Pet App资源目录: assets/',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
      
      // 检查常见资源类型
      final resourceTypes = ['images', 'fonts', 'data'];
      for (final type in resourceTypes) {
        final typeDir = Directory(path.join(assetsDir.path, type));
        if (await typeDir.exists()) {
          result.addSuccess(
            '包含$type资源',
            validationType: ValidationType.structure,
            validatorName: validatorName,
          );
        }
      }
    } else {
      result.addInfo(
        '可添加资源目录(assets/)',
        validationType: ValidationType.structure,
        validatorName: validatorName,
      );
    }
  }
}