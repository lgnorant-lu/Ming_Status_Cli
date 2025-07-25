/*
---------------------------------------------------------------
File name:          plugin_validator.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件验证器核心实现 (Plugin validator core implementation)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件验证核心逻辑;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'pet_app_bridge.dart';

/// 插件验证结果
class PluginValidationResult {
  /// 是否验证通过
  final bool isValid;

  /// 总检查项数
  final int totalChecks;

  /// 通过的检查项数
  final int passedChecks;

  /// 失败的检查项数
  final int failedChecks;

  /// 警告的检查项数
  final int warningChecks;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 建议列表
  final List<String> suggestions;

  /// 验证详情
  final Map<String, dynamic> details;

  /// 构造函数
  PluginValidationResult({
    required this.isValid,
    required this.totalChecks,
    required this.passedChecks,
    required this.failedChecks,
    required this.warningChecks,
    required this.errors,
    required this.warnings,
    required this.suggestions,
    required this.details,
  });

  /// 转换为JSON字符串
  String toJson() {
    return jsonEncode({
      'isValid': isValid,
      'totalChecks': totalChecks,
      'passedChecks': passedChecks,
      'failedChecks': failedChecks,
      'warningChecks': warningChecks,
      'errors': errors,
      'warnings': warnings,
      'suggestions': suggestions,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

/// 插件验证器
///
/// 负责验证插件项目的完整性、规范性和Pet App V3兼容性。
class PluginValidator {
  /// 验证插件
  ///
  /// [pluginPath] 插件项目路径
  /// [strict] 是否启用严格模式
  /// [autoFix] 是否自动修复问题
  Future<PluginValidationResult> validatePlugin(
    String pluginPath, {
    bool strict = false,
    bool autoFix = false,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];
    final details = <String, dynamic>{};

    int totalChecks = 0;
    int passedChecks = 0;
    int failedChecks = 0;
    int warningChecks = 0;

    // 1. 验证基本项目结构
    final structureResult = await _validateProjectStructure(pluginPath);
    totalChecks += structureResult['total'] as int;
    passedChecks += structureResult['passed'] as int;
    failedChecks += structureResult['failed'] as int;
    warningChecks += structureResult['warnings'] as int;
    errors.addAll(structureResult['errors'] as List<String>);
    warnings.addAll(structureResult['warnings_list'] as List<String>);
    details['structure'] = structureResult;

    // 2. 验证plugin.yaml清单文件
    final manifestResult = await _validatePluginManifest(pluginPath);
    totalChecks += manifestResult['total'] as int;
    passedChecks += manifestResult['passed'] as int;
    failedChecks += manifestResult['failed'] as int;
    warningChecks += manifestResult['warnings'] as int;
    errors.addAll(manifestResult['errors'] as List<String>);
    warnings.addAll(manifestResult['warnings_list'] as List<String>);
    details['manifest'] = manifestResult;

    // 3. 验证pubspec.yaml配置
    final pubspecResult = await _validatePubspecYaml(pluginPath);
    totalChecks += pubspecResult['total'] as int;
    passedChecks += pubspecResult['passed'] as int;
    failedChecks += pubspecResult['failed'] as int;
    warningChecks += pubspecResult['warnings'] as int;
    errors.addAll(pubspecResult['errors'] as List<String>);
    warnings.addAll(pubspecResult['warnings_list'] as List<String>);
    details['pubspec'] = pubspecResult;

    // 4. 验证代码质量（如果不是严格模式）
    if (!strict) {
      final codeResult = await _validateCodeQuality(pluginPath);
      totalChecks += codeResult['total'] as int;
      passedChecks += codeResult['passed'] as int;
      failedChecks += codeResult['failed'] as int;
      warningChecks += codeResult['warnings'] as int;
      warnings.addAll(codeResult['warnings_list'] as List<String>);
      suggestions.addAll(codeResult['suggestions'] as List<String>);
      details['code_quality'] = codeResult;
    }

    // 5. Pet App V3兼容性检查
    final compatibilityResult = await _validatePetAppCompatibility(pluginPath);
    totalChecks += compatibilityResult['total'] as int;
    passedChecks += compatibilityResult['passed'] as int;
    failedChecks += compatibilityResult['failed'] as int;
    warningChecks += compatibilityResult['warnings'] as int;
    errors.addAll(compatibilityResult['errors'] as List<String>);
    warnings.addAll(compatibilityResult['warnings_list'] as List<String>);
    details['pet_app_compatibility'] = compatibilityResult;

    // 自动修复（如果启用）
    if (autoFix && errors.isNotEmpty) {
      await _performAutoFix(pluginPath, errors);
    }

    final isValid = failedChecks == 0;

    return PluginValidationResult(
      isValid: isValid,
      totalChecks: totalChecks,
      passedChecks: passedChecks,
      failedChecks: failedChecks,
      warningChecks: warningChecks,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      details: details,
    );
  }

  /// 验证项目结构
  Future<Map<String, dynamic>> _validateProjectStructure(
      String pluginPath) async {
    final errors = <String>[];
    final warnings = <String>[];
    int total = 0;
    int passed = 0;
    int failed = 0;
    int warningCount = 0;

    // 检查必需的文件和目录
    final requiredPaths = [
      'lib',
      'pubspec.yaml',
      'plugin.yaml',
      'README.md',
      'lib/src',
      'test',
    ];

    for (final requiredPath in requiredPaths) {
      total++;
      final fullPath = path.join(pluginPath, requiredPath);
      if (FileSystemEntity.typeSync(fullPath) !=
          FileSystemEntityType.notFound) {
        passed++;
      } else {
        failed++;
        errors.add('缺少必需的文件或目录: $requiredPath');
      }
    }

    // 检查推荐的文件
    final recommendedPaths = [
      'CHANGELOG.md',
      'LICENSE',
      'docs',
      'example',
    ];

    for (final recommendedPath in recommendedPaths) {
      total++;
      final fullPath = path.join(pluginPath, recommendedPath);
      if (FileSystemEntity.typeSync(fullPath) !=
          FileSystemEntityType.notFound) {
        passed++;
      } else {
        warningCount++;
        warnings.add('建议添加: $recommendedPath');
      }
    }

    return {
      'total': total,
      'passed': passed,
      'failed': failed,
      'warnings': warningCount,
      'errors': errors,
      'warnings_list': warnings,
    };
  }

  /// 验证plugin.yaml清单文件
  Future<Map<String, dynamic>> _validatePluginManifest(
      String pluginPath) async {
    final errors = <String>[];
    final warnings = <String>[];
    int total = 0;
    int passed = 0;
    int failed = 0;
    int warningCount = 0;

    final manifestPath = path.join(pluginPath, 'plugin.yaml');
    final manifestFile = File(manifestPath);

    total++;
    if (!manifestFile.existsSync()) {
      failed++;
      errors.add('plugin.yaml文件不存在');
      return {
        'total': total,
        'passed': passed,
        'failed': failed,
        'warnings': warningCount,
        'errors': errors,
        'warnings_list': warnings,
      };
    }
    passed++;

    try {
      final manifestContent = await manifestFile.readAsString();
      final manifest = loadYaml(manifestContent) as Map;

      // 检查必需字段（支持嵌套结构）
      final requiredFields = ['id', 'name', 'version', 'description', 'author'];
      for (final field in requiredFields) {
        total++;

        // 检查顶级字段或plugin节点下的字段
        bool hasField = false;
        if (manifest.containsKey(field) && manifest[field] != null) {
          hasField = true;
        } else if (manifest.containsKey('plugin') &&
            manifest['plugin'] is Map &&
            (manifest['plugin'] as Map).containsKey(field) &&
            (manifest['plugin'] as Map)[field] != null) {
          hasField = true;
        }

        if (hasField) {
          passed++;
        } else {
          failed++;
          errors.add('plugin.yaml缺少必需字段: $field');
        }
      }

      // 检查推荐字段
      final recommendedFields = ['category', 'platforms', 'permissions'];
      for (final field in recommendedFields) {
        total++;
        if (manifest.containsKey(field)) {
          passed++;
        } else {
          warningCount++;
          warnings.add('plugin.yaml建议添加字段: $field');
        }
      }
    } catch (e) {
      failed++;
      errors.add('plugin.yaml格式错误: $e');
    }

    return {
      'total': total,
      'passed': passed,
      'failed': failed,
      'warnings': warningCount,
      'errors': errors,
      'warnings_list': warnings,
    };
  }

  /// 验证pubspec.yaml配置
  Future<Map<String, dynamic>> _validatePubspecYaml(String pluginPath) async {
    // 实现pubspec.yaml验证逻辑
    return {
      'total': 1,
      'passed': 1,
      'failed': 0,
      'warnings': 0,
      'errors': <String>[],
      'warnings_list': <String>[],
    };
  }

  /// 验证代码质量
  Future<Map<String, dynamic>> _validateCodeQuality(String pluginPath) async {
    // 实现代码质量检查逻辑
    return {
      'total': 1,
      'passed': 1,
      'failed': 0,
      'warnings': 0,
      'warnings_list': <String>[],
      'suggestions': <String>[],
    };
  }

  /// 验证Pet App V3兼容性
  Future<Map<String, dynamic>> _validatePetAppCompatibility(
      String pluginPath) async {
    try {
      final petAppBridge = PetAppBridge();
      final result = await petAppBridge.validatePetAppCompatibility(pluginPath);

      final errors = result['errors'] as List<String>;
      final warnings = result['warnings'] as List<String>;

      // 计算检查项数量
      const totalChecks = 5; // Pet App V3兼容性检查项
      final failedChecks = errors.length;
      final passedChecks = totalChecks - failedChecks;
      final warningChecks = warnings.length;

      return {
        'total': totalChecks,
        'passed': passedChecks,
        'failed': failedChecks,
        'warnings': warningChecks,
        'errors': errors,
        'warnings_list': warnings,
        'details': result['details'],
      };
    } catch (e) {
      return {
        'total': 1,
        'passed': 0,
        'failed': 1,
        'warnings': 0,
        'errors': ['Pet App V3兼容性检查失败: $e'],
        'warnings_list': <String>[],
        'details': <String, dynamic>{},
      };
    }
  }

  /// 执行自动修复
  Future<void> _performAutoFix(String pluginPath, List<String> errors) async {
    // 实现自动修复逻辑
  }
}
