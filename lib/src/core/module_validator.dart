/*
---------------------------------------------------------------
File name:          module_validator.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        模块验证器 (Module validator)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础模块验证功能;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/utils/string_utils.dart';
import 'package:path/path.dart' as path;

/// 模块验证器
/// 负责验证模块的结构、配置和代码规范
class ModuleValidator {
  /// 验证模块结构和配置
  Future<ValidationResult> validateModule(String modulePath) async {
    final result = ValidationResult();

    try {
      Logger.info('开始验证模块: $modulePath');

      // 1. 验证基础结构
      await _validateBasicStructure(modulePath, result);

      // 2. 验证配置文件
      await _validateConfiguration(modulePath, result);

      // 3. 验证代码结构
      await _validateCodeStructure(modulePath, result);

      // 4. 验证依赖关系
      await _validateDependencies(modulePath, result);

      // 5. 验证命名规范
      await _validateNamingConventions(modulePath, result);

      result.markCompleted();

      if (result.isValid) {
        Logger.success('模块验证通过: $modulePath');
      } else {
        Logger.warning('模块验证存在问题，请检查错误信息');
      }
    } catch (e) {
      result.addError('验证过程中发生异常: $e');
      Logger.error('模块验证异常', error: e);
    }

    return result;
  }

  /// 验证基础目录结构
  Future<void> _validateBasicStructure(
      String modulePath, ValidationResult result,) async {
    // 检查模块目录是否存在
    if (!FileUtils.directoryExists(modulePath)) {
      result.addError('模块目录不存在', file: modulePath);
      return;
    }

    // 必需的文件和目录
    final requiredItems = [
      'lib/', // Dart代码目录
      'pubspec.yaml', // 包配置文件
      'module.yaml', // 模块配置文件
    ];

    for (final item in requiredItems) {
      final itemPath = path.join(modulePath, item);
      final isDirectory = item.endsWith('/');

      if (isDirectory) {
        if (!FileUtils.directoryExists(
            itemPath.substring(0, itemPath.length - 1),)) {
          result.addError('必需目录不存在: $item', file: itemPath);
        } else {
          result.addSuccess('目录结构正确: $item');
        }
      } else {
        if (!FileUtils.fileExists(itemPath)) {
          result.addError('必需文件不存在: $item', file: itemPath);
        } else {
          result.addSuccess('文件存在: $item');
        }
      }
    }

    // 推荐的目录结构
    final recommendedItems = [
      'test/', // 测试目录
      'example/', // 示例目录
      'README.md', // 说明文档
      'CHANGELOG.md', // 变更日志
    ];

    for (final item in recommendedItems) {
      final itemPath = path.join(modulePath, item);
      final isDirectory = item.endsWith('/');

      if (isDirectory) {
        if (!FileUtils.directoryExists(
            itemPath.substring(0, itemPath.length - 1),)) {
          result.addWarning('推荐目录缺失: $item', file: itemPath);
        }
      } else {
        if (!FileUtils.fileExists(itemPath)) {
          result.addWarning('推荐文件缺失: $item', file: itemPath);
        }
      }
    }
  }

  /// 验证配置文件
  Future<void> _validateConfiguration(
      String modulePath, ValidationResult result,) async {
    // 验证module.yaml
    await _validateModuleConfig(modulePath, result);

    // 验证pubspec.yaml
    await _validatePubspecConfig(modulePath, result);
  }

  /// 验证模块配置文件
  Future<void> _validateModuleConfig(
      String modulePath, ValidationResult result,) async {
    final configPath = path.join(modulePath, 'module.yaml');

    if (!FileUtils.fileExists(configPath)) {
      result.addError('模块配置文件不存在', file: configPath);
      return;
    }

    try {
      final yamlData = await FileUtils.readYamlFile(configPath);
      if (yamlData == null) {
        result.addError('无法解析模块配置文件', file: configPath);
        return;
      }

      // 验证必需字段
      final requiredFields = ['id', 'name', 'version', 'description', 'author'];
      for (final field in requiredFields) {
        if (!yamlData.containsKey(field) || yamlData[field] == null) {
          result.addError('缺少必需字段: $field', file: configPath);
        } else {
          final value = yamlData[field]?.toString().trim() ?? '';
          if (value.isEmpty) {
            result.addError('字段值为空: $field', file: configPath);
          }
        }
      }

      // 验证模块ID格式
      if (yamlData.containsKey('id')) {
        final moduleId = yamlData['id'].toString();
        if (!StringUtils.isValidIdentifier(moduleId)) {
          result.addError('模块ID格式无效: $moduleId', file: configPath);
        } else if (!moduleId.startsWith('com.')) {
          result.addWarning('建议使用完整的包名格式: com.company.module_name',
              file: configPath,);
        }
      }

      // 验证版本格式
      if (yamlData.containsKey('version')) {
        final version = yamlData['version'].toString();
        if (!RegExp(r'^\d+\.\d+\.\d+(\+\d+)?$').hasMatch(version)) {
          result.addError('版本号格式无效: $version', file: configPath);
        }
      }

      result.addSuccess('模块配置文件格式正确');
    } catch (e) {
      result.addError('解析模块配置文件失败: $e', file: configPath);
    }
  }

  /// 验证pubspec.yaml配置
  Future<void> _validatePubspecConfig(
      String modulePath, ValidationResult result,) async {
    final pubspecPath = path.join(modulePath, 'pubspec.yaml');

    if (!FileUtils.fileExists(pubspecPath)) {
      result.addError('pubspec.yaml文件不存在', file: pubspecPath);
      return;
    }

    try {
      final yamlData = await FileUtils.readYamlFile(pubspecPath);
      if (yamlData == null) {
        result.addError('无法解析pubspec.yaml文件', file: pubspecPath);
        return;
      }

      // 验证基本字段
      final requiredFields = ['name', 'version', 'description'];
      for (final field in requiredFields) {
        if (!yamlData.containsKey(field)) {
          result.addError('pubspec.yaml缺少字段: $field', file: pubspecPath);
        }
      }

      // 验证Dart SDK版本
      if (yamlData.containsKey('environment') &&
          yamlData['environment'] is Map &&
          (yamlData['environment'] as Map)['sdk'] != null) {
        result.addSuccess('Dart SDK版本已指定');
      } else {
        result.addWarning('建议指定Dart SDK版本约束', file: pubspecPath);
      }

      result.addSuccess('pubspec.yaml配置基本正确');
    } catch (e) {
      result.addError('解析pubspec.yaml失败: $e', file: pubspecPath);
    }
  }

  /// 验证代码结构
  Future<void> _validateCodeStructure(
      String modulePath, ValidationResult result,) async {
    final libPath = path.join(modulePath, 'lib');

    if (!FileUtils.directoryExists(libPath)) {
      result.addError('lib目录不存在', file: libPath);
      return;
    }

    // 查找Dart文件
    final dartFiles = FileUtils.findFiles(libPath, '.dart');

    if (dartFiles.isEmpty) {
      result.addError('lib目录中没有找到Dart文件', file: libPath);
      return;
    }

    // 验证主模块文件
    final moduleFiles = dartFiles
        .where(
          (file) =>
              path.basename(file).endsWith('_module.dart') ||
              path.basename(file) == '${path.basename(modulePath)}.dart',
        )
        .toList();

    if (moduleFiles.isEmpty) {
      result.addWarning('建议创建主模块文件（以_module.dart结尾）', file: libPath);
    }

    // 验证代码文件命名
    for (final file in dartFiles) {
      final fileName = path.basenameWithoutExtension(file);
      if (!StringUtils.isValidPackageName(fileName)) {
        result.addWarning('文件名不符合命名规范: $fileName', file: file);
      }
    }

    result.addSuccess('代码结构基本正确，共发现 ${dartFiles.length} 个Dart文件');
  }

  /// 验证依赖关系
  Future<void> _validateDependencies(
      String modulePath, ValidationResult result,) async {
    final pubspecPath = path.join(modulePath, 'pubspec.yaml');

    try {
      final yamlData = await FileUtils.readYamlFile(pubspecPath);
      if (yamlData == null) return;

      // 检查是否有依赖
      if (yamlData.containsKey('dependencies') &&
          yamlData['dependencies'] is Map) {
        final deps = yamlData['dependencies'] as Map;
        result.addInfo('发现 ${deps.length} 个依赖包');

        // 检查是否有常见的必需依赖
        final recommendedDeps = ['flutter', 'meta'];
        for (final dep in recommendedDeps) {
          if (!deps.containsKey(dep)) {
            result.addInfo('可能需要添加依赖: $dep');
          }
        }
      }

      // 检查开发依赖
      if (yamlData.containsKey('dev_dependencies') &&
          yamlData['dev_dependencies'] is Map) {
        final devDeps = yamlData['dev_dependencies'] as Map;
        result.addInfo('发现 ${devDeps.length} 个开发依赖');

        // 检查测试依赖
        if (!devDeps.containsKey('test')) {
          result.addWarning('建议添加test依赖进行单元测试');
        }
      }
    } catch (e) {
      result.addWarning('验证依赖关系时发生错误: $e');
    }
  }

  /// 验证命名规范
  Future<void> _validateNamingConventions(
      String modulePath, ValidationResult result,) async {
    // 验证模块目录名
    final moduleName = path.basename(modulePath);
    if (!StringUtils.isValidPackageName(moduleName)) {
      result.addError('模块目录名不符合命名规范: $moduleName');
    }

    // 验证文件命名规范
    final libPath = path.join(modulePath, 'lib');
    if (FileUtils.directoryExists(libPath)) {
      final dartFiles = FileUtils.findFiles(libPath, '.dart');

      for (final file in dartFiles) {
        final fileName = path.basenameWithoutExtension(file);

        // 检查文件名格式
        if (!StringUtils.isValidPackageName(fileName)) {
          result.addWarning('文件名不符合snake_case规范: $fileName', file: file);
        }

        // 检查文件内容的类名
        await _validateFileNaming(file, result);
      }
    }
  }

  /// 验证文件内容命名
  Future<void> _validateFileNaming(
      String filePath, ValidationResult result,) async {
    try {
      final content = await FileUtils.readFileAsString(filePath);
      if (content == null) return;

      // 查找类定义
      final classRegex =
          RegExp(r'class\s+([A-Za-z_][A-Za-z0-9_]*)', multiLine: true);
      final matches = classRegex.allMatches(content);

      for (final match in matches) {
        final className = match.group(1)!;
        if (!StringUtils.isValidClassName(className)) {
          result.addWarning('类名不符合PascalCase规范: $className', file: filePath);
        }
      }
    } catch (e) {
      // 文件读取或解析错误，不影响整体验证
      result.addInfo('无法验证文件内容命名: ${path.basename(filePath)}');
    }
  }

  /// 快速验证（仅检查关键项）
  Future<bool> quickValidate(String modulePath) async {
    try {
      // 检查基本结构
      if (!FileUtils.directoryExists(modulePath)) return false;
      
      // pubspec.yaml是必需的（Dart项目基本要求）
      if (!FileUtils.fileExists(path.join(modulePath, 'pubspec.yaml'))) {
        return false;
      }
      
      // lib目录是必需的
      if (!FileUtils.directoryExists(path.join(modulePath, 'lib'))) {
        return false;
      }

      // module.yaml是可选的（仅针对特定模块化项目）
      // 不再强制要求module.yaml文件

      return true;
    } catch (e) {
      return false;
    }
  }
}
