/*
---------------------------------------------------------------
File name:          template_engine.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        模板引擎管理器 (Template engine manager)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础模板引擎功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:mason/mason.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:ming_status_cli/src/utils/string_utils.dart';
import 'package:path/path.dart' as path;

/// 模板引擎管理器
/// 负责模板的加载、处理和代码生成
class TemplateEngine {
  TemplateEngine({String? workingDirectory})
      : workingDirectory = workingDirectory ?? Directory.current.path;

  /// 配置管理器引用
  final String workingDirectory;

  /// Mason生成器缓存
  final Map<String, MasonGenerator> _generatorCache = {};

  /// 获取可用模板列表
  Future<List<String>> getAvailableTemplates() async {
    try {
      final templatesPath = path.join(workingDirectory, 'templates');

      if (!FileUtils.directoryExists(templatesPath)) {
        cli_logger.Logger.warning('模板目录不存在: $templatesPath');
        return [];
      }

      final entities = FileUtils.listDirectory(templatesPath);
      final templates = <String>[];

      for (final entity in entities) {
        if (entity is Directory) {
          final templateName = path.basename(entity.path);
          // 检查是否是有效的Mason模板
          final brickPath = path.join(entity.path, 'brick.yaml');
          if (FileUtils.fileExists(brickPath)) {
            templates.add(templateName);
          }
        }
      }

      cli_logger.Logger.debug('找到 ${templates.length} 个可用模板');
      return templates;
    } catch (e) {
      cli_logger.Logger.error('获取模板列表失败', error: e);
      return [];
    }
  }

  /// 检查模板是否存在
  bool isTemplateAvailable(String templateName) {
    final templatePath = getTemplatePath(templateName);
    final brickPath = path.join(templatePath, 'brick.yaml');
    return FileUtils.fileExists(brickPath);
  }

  /// 获取模板路径
  String getTemplatePath(String templateName) {
    return path.join(workingDirectory, 'templates', templateName);
  }

  /// 加载模板生成器
  Future<MasonGenerator?> loadTemplate(String templateName) async {
    try {
      // 检查缓存
      if (_generatorCache.containsKey(templateName)) {
        return _generatorCache[templateName];
      }

      // 检查模板是否存在
      if (!isTemplateAvailable(templateName)) {
        cli_logger.Logger.error('模板不存在: $templateName');
        return null;
      }

      final templatePath = getTemplatePath(templateName);
      cli_logger.Logger.debug('正在加载模板: $templatePath');

      // 创建Mason生成器
      final brick = Brick.path(templatePath);
      final generator = await MasonGenerator.fromBrick(brick);

      // 缓存生成器
      _generatorCache[templateName] = generator;

      cli_logger.Logger.success('模板加载成功: $templateName');
      return generator;
    } catch (e) {
      cli_logger.Logger.error('加载模板失败: $templateName', error: e);
      return null;
    }
  }

  /// 生成模块代码
  Future<bool> generateModule({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    bool overwrite = false,
  }) async {
    try {
      cli_logger.Logger.info('正在生成模块: $templateName -> $outputPath');

      // 加载模板
      final generator = await loadTemplate(templateName);
      if (generator == null) {
        cli_logger.Logger.error('无法加载模板: $templateName');
        return false;
      }

      // 检查输出目录
      if (FileUtils.directoryExists(outputPath) && !overwrite) {
        cli_logger.Logger.error('输出目录已存在且未启用覆盖模式: $outputPath');
        return false;
      }

      // 创建输出目录
      await FileUtils.createDirectory(outputPath);

      // 准备生成上下文
      final target = DirectoryGeneratorTarget(Directory(outputPath));

      // 执行代码生成
      await generator.generate(target, vars: variables);

      cli_logger.Logger.success('模块生成完成: $outputPath');
      return true;
    } catch (e) {
      cli_logger.Logger.error('模块生成失败', error: e);
      return false;
    }
  }

  /// 获取模板变量名称列表
  Future<List<String>?> getTemplateVariables(String templateName) async {
    try {
      final generator = await loadTemplate(templateName);
      if (generator == null) {
        return null;
      }

      // Mason的generator.vars实际返回List<String>（变量名列表）
      return generator.vars;
    } catch (e) {
      cli_logger.Logger.error('获取模板变量失败', error: e);
      return null;
    }
  }

  /// 验证模板变量
  Map<String, String> validateTemplateVariables({
    required String templateName,
    required Map<String, dynamic> variables,
  }) {
    final errors = <String, String>{};

    try {
      // 这里可以添加更复杂的验证逻辑
      // 检查必需的变量
      final requiredVars = ['module_id', 'module_name'];
      for (final varName in requiredVars) {
        if (!variables.containsKey(varName) ||
            StringUtils.isBlank(variables[varName]?.toString())) {
          errors[varName] = '必需变量未提供或为空';
        }
      }

      // 验证模块ID格式
      if (variables.containsKey('module_id')) {
        final moduleId = variables['module_id']?.toString() ?? '';
        if (!StringUtils.isValidIdentifier(moduleId)) {
          errors['module_id'] = '模块ID格式无效，必须是有效的标识符';
        }
      }

      // 验证类名格式
      if (variables.containsKey('class_name')) {
        final className = variables['class_name']?.toString() ?? '';
        if (className.isNotEmpty && !StringUtils.isValidClassName(className)) {
          errors['class_name'] = '类名格式无效，必须以大写字母开头';
        }
      }
    } catch (e) {
      cli_logger.Logger.error('验证模板变量时发生异常', error: e);
      errors['_general'] = '验证过程中发生异常: $e';
    }

    return errors;
  }

  /// 预处理模板变量
  Map<String, dynamic> preprocessVariables(Map<String, dynamic> variables) {
    final processed = Map<String, dynamic>.from(variables);

    try {
      // 自动生成相关变量
      if (processed.containsKey('module_id')) {
        final moduleId = processed['module_id'].toString();

        // 生成类名（如果未提供）
        if (!processed.containsKey('class_name') ||
            StringUtils.isBlank(processed['class_name']?.toString())) {
          processed['class_name'] = StringUtils.toPascalCase(moduleId);
        }

        // 生成文件名
        processed['file_name'] = StringUtils.toSnakeCase(moduleId);
        processed['kebab_name'] = StringUtils.toKebabCase(moduleId);
        processed['camel_name'] = StringUtils.toCamelCase(moduleId);
      }

      // 生成时间戳
      final now = DateTime.now();
      processed['generated_date'] = now.toIso8601String().substring(0, 10);
      processed['generated_time'] = now.toIso8601String().substring(11, 19);
      processed['generated_year'] = now.year.toString();

      // 默认作者信息
      if (!processed.containsKey('author') ||
          StringUtils.isBlank(processed['author']?.toString())) {
        processed['author'] = 'Ignorant-lu';
      }

      // 默认版本
      if (!processed.containsKey('version') ||
          StringUtils.isBlank(processed['version']?.toString())) {
        processed['version'] = '1.0.0';
      }
    } catch (e) {
      cli_logger.Logger.error('预处理模板变量时发生异常', error: e);
    }

    return processed;
  }

  /// 创建基础模板
  Future<bool> createBaseTemplate(String templateName) async {
    try {
      final templatePath = getTemplatePath(templateName);

      if (FileUtils.directoryExists(templatePath)) {
        cli_logger.Logger.warning('模板已存在: $templateName');
        return false;
      }

      // 创建模板目录
      await FileUtils.createDirectory(templatePath);

      // 创建brick.yaml文件
      final brickContent = _generateBrickYaml(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');
      await FileUtils.writeFileAsString(brickPath, brickContent);

      // 创建基础模板文件
      await _createBasicTemplateFiles(templatePath);

      cli_logger.Logger.success('基础模板创建成功: $templateName');
      return true;
    } catch (e) {
      cli_logger.Logger.error('创建基础模板失败', error: e);
      return false;
    }
  }

  /// 生成brick.yaml内容
  String _generateBrickYaml(String templateName) {
    return '''
name: $templateName
description: Ming Status CLI生成的模板
version: 0.1.0+1

vars:
  module_id:
    type: string
    description: 模块唯一标识符
    prompt: 请输入模块ID
  module_name:
    type: string
    description: 模块显示名称
    prompt: 请输入模块名称
  author:
    type: string
    description: 作者名称
    default: Ignorant-lu
  description:
    type: string
    description: 模块描述
    default: 模块描述
''';
  }

  /// 创建基础模板文件
  Future<void> _createBasicTemplateFiles(String templatePath) async {
    // 创建__brick__目录
    final brickDir = path.join(templatePath, '__brick__');
    await FileUtils.createDirectory(brickDir);

    // 创建基础模块文件模板
    const moduleTemplate = '''
/*
---------------------------------------------------------------
File name:          {{file_name}}.dart
Author:             {{author}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       3.2+
Description:        {{description}}
---------------------------------------------------------------
*/

/// {{module_name}}模块
class {{class_name}} {
  /// 模块ID
  static const String moduleId = '{{module_id}}';
  
  /// 模块名称
  static const String moduleName = '{{module_name}}';
  
  /// 初始化模块
  void initialize() {
    // TODO: 实现模块初始化逻辑
  }
}
''';

    final moduleFilePath = path.join(brickDir, '{{file_name}}.dart');
    await FileUtils.writeFileAsString(moduleFilePath, moduleTemplate);

    cli_logger.Logger.debug('基础模板文件创建完成');
  }

  /// 清理缓存
  void clearCache() {
    _generatorCache.clear();
    cli_logger.Logger.debug('模板引擎缓存已清理');
  }

  /// 获取模板信息
  Future<Map<String, dynamic>?> getTemplateInfo(String templateName) async {
    try {
      final templatePath = getTemplatePath(templateName);
      final brickPath = path.join(templatePath, 'brick.yaml');

      if (!FileUtils.fileExists(brickPath)) {
        return null;
      }

      final yamlData = await FileUtils.readYamlFile(brickPath);
      return yamlData;
    } catch (e) {
      cli_logger.Logger.error('获取模板信息失败', error: e);
      return null;
    }
  }
}
