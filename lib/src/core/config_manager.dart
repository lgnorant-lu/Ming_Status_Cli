/*
---------------------------------------------------------------
File name:          config_manager.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        配置管理器 (Configuration manager)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础配置管理功能;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:path/path.dart' as path;

import '../models/workspace_config.dart';
import '../models/module_config.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// 配置管理器
/// 负责工作空间和模块配置的加载、保存和管理
class ConfigManager {
  /// 默认配置文件名
  static const String defaultConfigFileName = 'ming_status.yaml';
  static const String moduleConfigFileName = 'module.yaml';
  
  /// 当前工作目录
  final String workingDirectory;
  
  /// 缓存的工作空间配置
  WorkspaceConfig? _cachedWorkspaceConfig;
  
  /// 配置文件路径
  String get configFilePath => path.join(workingDirectory, defaultConfigFileName);

  ConfigManager({String? workingDirectory}) 
      : workingDirectory = workingDirectory ?? Directory.current.path;

  /// 检查是否已初始化工作空间
  bool isWorkspaceInitialized() {
    return FileUtils.fileExists(configFilePath);
  }

  /// 初始化工作空间
  Future<bool> initializeWorkspace({
    required String workspaceName,
    String? description,
    String? author,
  }) async {
    try {
      Logger.info('正在初始化工作空间: $workspaceName');
      
      // 检查是否已存在配置
      if (isWorkspaceInitialized()) {
        Logger.warning('工作空间已存在配置文件');
        return false;
      }
      
      // 创建默认配置
      final config = WorkspaceConfig.defaultConfig().copyWith(
        workspace: WorkspaceInfo(
          name: workspaceName,
          version: '1.0.0',
          description: description ?? 'Ming Status模块工作空间',
        ),
        defaults: DefaultSettings(
          author: author ?? '开发者名称',
          license: 'MIT',
          dartVersion: '^3.2.0',
        ),
      );
      
      // 保存配置文件
      final success = await saveWorkspaceConfig(config);
      if (success) {
        Logger.success('工作空间初始化成功');
        _cachedWorkspaceConfig = config;
        
        // 创建模板目录
        await _createDirectoryStructure();
        
        return true;
      } else {
        Logger.error('工作空间初始化失败：无法保存配置文件');
        return false;
      }
    } catch (e) {
      Logger.error('工作空间初始化异常', error: e);
      return false;
    }
  }

  /// 加载工作空间配置
  Future<WorkspaceConfig?> loadWorkspaceConfig({bool useCache = true}) async {
    try {
      // 使用缓存
      if (useCache && _cachedWorkspaceConfig != null) {
        return _cachedWorkspaceConfig;
      }
      
      // 检查配置文件是否存在
      if (!FileUtils.fileExists(configFilePath)) {
        Logger.warning('工作空间配置文件不存在: $configFilePath');
        return null;
      }
      
      // 读取YAML文件
      final yamlData = await FileUtils.readYamlFile(configFilePath);
      if (yamlData == null) {
        Logger.error('无法解析工作空间配置文件');
        return null;
      }
      
      // 转换为配置对象
      final config = WorkspaceConfig.fromJson(yamlData);
      _cachedWorkspaceConfig = config;
      
      Logger.debug('工作空间配置加载成功');
      return config;
    } catch (e) {
      Logger.error('加载工作空间配置失败', error: e);
      return null;
    }
  }

  /// 保存工作空间配置
  Future<bool> saveWorkspaceConfig(WorkspaceConfig config) async {
    try {
      // 转换为YAML数据
      final yamlData = config.toJson();
      
      // 保存到文件
      final success = await FileUtils.writeYamlFile(configFilePath, yamlData);
      if (success) {
        _cachedWorkspaceConfig = config;
        Logger.debug('工作空间配置保存成功');
        return true;
      } else {
        Logger.error('保存工作空间配置失败');
        return false;
      }
    } catch (e) {
      Logger.error('保存工作空间配置异常', error: e);
      return false;
    }
  }

  /// 更新工作空间配置
  Future<bool> updateWorkspaceConfig(WorkspaceConfig Function(WorkspaceConfig) updater) async {
    try {
      final currentConfig = await loadWorkspaceConfig();
      if (currentConfig == null) {
        Logger.error('无法加载当前配置进行更新');
        return false;
      }
      
      final updatedConfig = updater(currentConfig);
      return await saveWorkspaceConfig(updatedConfig);
    } catch (e) {
      Logger.error('更新工作空间配置异常', error: e);
      return false;
    }
  }

  /// 加载模块配置
  Future<ModuleConfig?> loadModuleConfig(String modulePath) async {
    try {
      final configPath = path.join(modulePath, moduleConfigFileName);
      
      if (!FileUtils.fileExists(configPath)) {
        Logger.warning('模块配置文件不存在: $configPath');
        return null;
      }
      
      final yamlData = await FileUtils.readYamlFile(configPath);
      if (yamlData == null) {
        Logger.error('无法解析模块配置文件: $configPath');
        return null;
      }
      
      // 这里应该根据实际的模块配置结构进行转换
      // 暂时返回一个基础配置
      Logger.debug('模块配置加载成功: $modulePath');
      return ModuleConfig.defaultConfig(
        id: yamlData['id']?.toString() ?? 'unknown',
        name: yamlData['name']?.toString() ?? 'Unknown Module',
        description: yamlData['description']?.toString(),
      );
    } catch (e) {
      Logger.error('加载模块配置失败', error: e);
      return null;
    }
  }

  /// 保存模块配置
  Future<bool> saveModuleConfig(String modulePath, ModuleConfig config) async {
    try {
      final configPath = path.join(modulePath, moduleConfigFileName);
      
      // 创建模块目录
      await FileUtils.createDirectory(modulePath);
      
      // 构建YAML数据
      final yamlData = {
        'id': config.module.id,
        'name': config.module.name,
        'version': config.module.version,
        'description': config.module.description,
        'author': config.module.author,
        'type': config.classification.type.name,
        'categories': config.classification.categories,
        'dependencies': config.dependencies.required,
        'optional_dependencies': config.dependencies.optional,
        'permissions': config.permissions,
        'exports': {
          'services': config.exports.services.map((s) => s.name).toList(),
          'widgets': config.exports.widgets.map((w) => w.name).toList(),
        },
      };
      
      final success = await FileUtils.writeYamlFile(configPath, yamlData);
      if (success) {
        Logger.debug('模块配置保存成功: $modulePath');
        return true;
      } else {
        Logger.error('保存模块配置失败: $modulePath');
        return false;
      }
    } catch (e) {
      Logger.error('保存模块配置异常', error: e);
      return false;
    }
  }

  /// 获取模板路径
  String getTemplatesPath() {
    final config = _cachedWorkspaceConfig;
    if (config?.templates.localPath != null) {
      return path.isAbsolute(config!.templates.localPath!)
          ? config.templates.localPath!
          : path.join(workingDirectory, config.templates.localPath!);
    }
    
    // 默认模板路径
    return path.join(workingDirectory, 'templates');
  }

  /// 列出可用的模板
  List<String> listAvailableTemplates() {
    final templatesPath = getTemplatesPath();
    
    if (!FileUtils.directoryExists(templatesPath)) {
      Logger.warning('模板目录不存在: $templatesPath');
      return [];
    }
    
    final entities = FileUtils.listDirectory(templatesPath);
    final templates = <String>[];
    
    for (final entity in entities) {
      if (entity is Directory) {
        final templateName = path.basename(entity.path);
        templates.add(templateName);
      }
    }
    
    return templates;
  }

  /// 验证模板是否存在
  bool isTemplateAvailable(String templateName) {
    final templatesPath = getTemplatesPath();
    final templatePath = path.join(templatesPath, templateName);
    return FileUtils.directoryExists(templatePath);
  }

  /// 获取模板路径
  String getTemplatePath(String templateName) {
    final templatesPath = getTemplatesPath();
    return path.join(templatesPath, templateName);
  }

  /// 清理缓存
  void clearCache() {
    _cachedWorkspaceConfig = null;
    Logger.debug('配置缓存已清理');
  }

  /// 创建目录结构
  Future<void> _createDirectoryStructure() async {
    final directories = [
      'templates',
      'modules',
      'output',
    ];
    
    for (final dir in directories) {
      final dirPath = path.join(workingDirectory, dir);
      await FileUtils.createDirectory(dirPath);
      Logger.debug('创建目录: $dirPath');
    }
  }

  /// 获取工作空间信息摘要
  Map<String, dynamic> getWorkspaceSummary() {
    final config = _cachedWorkspaceConfig;
    if (config == null) {
      return {'initialized': false};
    }
    
    return {
      'initialized': true,
      'name': config.workspace.name,
      'version': config.workspace.version,
      'description': config.workspace.description,
      'templates_count': listAvailableTemplates().length,
      'templates_path': getTemplatesPath(),
      'config_file': configFilePath,
    };
  }
} 