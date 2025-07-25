/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_config.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件配置管理
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件配置管理;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../types/{{plugin_name.snakeCase()}}_types.dart';
import '../constants/{{plugin_name.snakeCase()}}_constants.dart';
import '../exceptions/{{plugin_name.snakeCase()}}_exceptions.dart';

/// {{plugin_name.titleCase()}}插件配置管理器
/// 
/// 负责插件配置的加载、保存、验证和管理
class {{plugin_name.pascalCase()}}Config {
  /// 当前配置数据
  {{plugin_name.pascalCase()}}ConfigData _configData;

  /// 配置文件路径
  String? _configFilePath;

  /// 配置变更控制器
  final StreamController<{{plugin_name.pascalCase()}}ConfigData> _configController =
      StreamController<{{plugin_name.pascalCase()}}ConfigData>.broadcast();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 创建配置管理器实例
  {{plugin_name.pascalCase()}}Config({
    {{plugin_name.pascalCase()}}ConfigData? initialConfig,
    String? configFilePath,
  }) : _configData = initialConfig ?? _getDefaultConfig(),
       _configFilePath = configFilePath;

  /// 获取当前配置数据
  {{plugin_name.pascalCase()}}ConfigData get current => _configData;

  /// 配置变更流
  Stream<{{plugin_name.pascalCase()}}ConfigData> get configChanges => _configController.stream;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 配置文件路径
  String? get configFilePath => _configFilePath;

  /// 加载配置
  /// 
  /// 从文件或默认值加载配置
  Future<void> load() async {
    try {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 开始加载配置...');

      // 确定配置文件路径
      _configFilePath ??= await _getDefaultConfigFilePath();
      
      // 检查配置文件是否存在
      final configFile = File(_configFilePath!);
      if (await configFile.exists()) {
        // 从文件加载配置
        await _loadFromFile(configFile);
        debugPrint('[{{plugin_name.pascalCase()}}Config] 从文件加载配置成功: $_configFilePath');
      } else {
        // 使用默认配置
        _configData = _getDefaultConfig();
        debugPrint('[{{plugin_name.pascalCase()}}Config] 使用默认配置');
        
        // 保存默认配置到文件
        await _saveToFile();
        debugPrint('[{{plugin_name.pascalCase()}}Config] 默认配置已保存到文件');
      }

      // 验证配置
      final validationResult = _validateConfig(_configData);
      if (!validationResult.isSuccess) {
        throw {{plugin_name.pascalCase()}}Exception(
          '配置验证失败: ${validationResult.message}',
        );
      }

      _isInitialized = true;
      _notifyConfigChange();
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置加载完成');
    } catch (e, stackTrace) {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置加载失败: $e');
      debugPrint('[{{plugin_name.pascalCase()}}Config] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('配置加载失败: $e');
    }
  }

  /// 保存配置
  /// 
  /// 将当前配置保存到文件
  Future<void> save() async {
    try {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 开始保存配置...');
      
      if (_configFilePath == null) {
        _configFilePath = await _getDefaultConfigFilePath();
      }

      await _saveToFile();
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置保存成功: $_configFilePath');
    } catch (e, stackTrace) {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置保存失败: $e');
      debugPrint('[{{plugin_name.pascalCase()}}Config] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('配置保存失败: $e');
    }
  }

  /// 更新配置
  /// 
  /// [newConfig] 新的配置数据
  /// [saveToFile] 是否立即保存到文件
  Future<void> update(
    {{plugin_name.pascalCase()}}ConfigData newConfig, {
    bool saveToFile = true,
  }) async {
    try {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 开始更新配置...');

      // 验证新配置
      final validationResult = _validateConfig(newConfig);
      if (!validationResult.isSuccess) {
        throw {{plugin_name.pascalCase()}}Exception(
          '配置验证失败: ${validationResult.message}',
        );
      }

      // 更新配置数据
      _configData = newConfig;

      // 保存到文件
      if (saveToFile) {
        await save();
      }

      // 通知配置变更
      _notifyConfigChange();
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置更新完成');
    } catch (e, stackTrace) {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置更新失败: $e');
      debugPrint('[{{plugin_name.pascalCase()}}Config] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('配置更新失败: $e');
    }
  }

  /// 重置为默认配置
  /// 
  /// [saveToFile] 是否立即保存到文件
  Future<void> resetToDefault({bool saveToFile = true}) async {
    try {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 重置为默认配置...');
      
      await update(_getDefaultConfig(), saveToFile: saveToFile);
      
      debugPrint('[{{plugin_name.pascalCase()}}Config] 重置为默认配置完成');
    } catch (e, stackTrace) {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 重置配置失败: $e');
      debugPrint('[{{plugin_name.pascalCase()}}Config] 堆栈跟踪: $stackTrace');
      throw {{plugin_name.pascalCase()}}Exception('重置配置失败: $e');
    }
  }

  /// 获取配置的Map表示
  Map<String, dynamic> toMap() {
    return _configData.toMap();
  }

  /// 从Map创建配置
  void fromMap(Map<String, dynamic> map) {
    _configData = {{plugin_name.pascalCase()}}ConfigData.fromMap(map);
    _notifyConfigChange();
  }

  /// 销毁配置管理器
  Future<void> dispose() async {
    try {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 销毁配置管理器...');
      
      // 保存当前配置
      if (_isInitialized) {
        await save();
      }

      // 关闭控制器
      await _configController.close();
      
      _isInitialized = false;
      debugPrint('[{{plugin_name.pascalCase()}}Config] 配置管理器销毁完成');
    } catch (e, stackTrace) {
      debugPrint('[{{plugin_name.pascalCase()}}Config] 销毁配置管理器失败: $e');
      debugPrint('[{{plugin_name.pascalCase()}}Config] 堆栈跟踪: $stackTrace');
    }
  }

  // ============================================================================
  // 私有方法
  // ============================================================================

  /// 获取默认配置
  static {{plugin_name.pascalCase()}}ConfigData _getDefaultConfig() {
    return {{plugin_name.pascalCase()}}ConfigData(
      enabled: {{plugin_name.pascalCase()}}Constants.defaultEnabled,
      autoStart: {{plugin_name.pascalCase()}}Constants.defaultAutoStart,
      debugMode: {{plugin_name.pascalCase()}}Constants.defaultDebugMode,
      logLevel: {{plugin_name.pascalCase()}}LogLevel.values.firstWhere(
        (level) => level.name == {{plugin_name.pascalCase()}}Constants.defaultLogLevel,
        orElse: () => {{plugin_name.pascalCase()}}LogLevel.info,
      ),
      maxRetries: {{plugin_name.pascalCase()}}Constants.defaultMaxRetries,
      timeout: Duration(
        milliseconds: {{plugin_name.pascalCase()}}Constants.defaultTimeoutMs,
      ),
      customSettings: const <String, dynamic>{},
    );
  }

  /// 获取默认配置文件路径
  Future<String> _getDefaultConfigFilePath() async {
    // 获取应用数据目录
    String appDataDir;
    if (kIsWeb) {
      // Web平台使用本地存储
      appDataDir = 'web_storage';
    } else {
      // 其他平台使用文档目录
      final documentsDir = Directory.current; // 简化实现
      appDataDir = path.join(
        documentsDir.path,
        {{plugin_name.pascalCase()}}Constants.configDirectory,
      );
    }

    // 确保目录存在
    final configDir = Directory(appDataDir);
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    return path.join(appDataDir, {{plugin_name.pascalCase()}}Constants.defaultConfigFileName);
  }

  /// 从文件加载配置
  Future<void> _loadFromFile(File configFile) async {
    try {
      final content = await configFile.readAsString();
      final Map<String, dynamic> configMap = jsonDecode(content);
      _configData = {{plugin_name.pascalCase()}}ConfigData.fromMap(configMap);
    } catch (e) {
      throw {{plugin_name.pascalCase()}}Exception('配置文件格式错误: $e');
    }
  }

  /// 保存配置到文件
  Future<void> _saveToFile() async {
    if (_configFilePath == null) {
      throw {{plugin_name.pascalCase()}}Exception('配置文件路径未设置');
    }

    try {
      final configFile = File(_configFilePath!);
      
      // 确保目录存在
      final configDir = configFile.parent;
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }

      // 保存配置
      final configJson = jsonEncode(_configData.toMap());
      await configFile.writeAsString(configJson);
    } catch (e) {
      throw {{plugin_name.pascalCase()}}Exception('配置文件写入失败: $e');
    }
  }

  /// 验证配置
  {{plugin_name.pascalCase()}}Result<void> _validateConfig({{plugin_name.pascalCase()}}ConfigData config) {
    try {
      // 验证重试次数
      if (config.maxRetries < 0 || config.maxRetries > 10) {
        return {{plugin_name.pascalCase()}}Result.failure(
          {{plugin_name.pascalCase()}}Exception('最大重试次数必须在0-10之间'),
          message: '无效的重试次数配置',
        );
      }

      // 验证超时时间
      if (config.timeout.inMilliseconds < 1000 || config.timeout.inMilliseconds > 300000) {
        return {{plugin_name.pascalCase()}}Result.failure(
          {{plugin_name.pascalCase()}}Exception('超时时间必须在1-300秒之间'),
          message: '无效的超时时间配置',
        );
      }

      // 验证自定义设置
      if (config.customSettings.length > 100) {
        return {{plugin_name.pascalCase()}}Result.failure(
          {{plugin_name.pascalCase()}}Exception('自定义设置项不能超过100个'),
          message: '自定义设置过多',
        );
      }

      return {{plugin_name.pascalCase()}}Result.success(null, message: '配置验证通过');
    } catch (e) {
      return {{plugin_name.pascalCase()}}Result.failure(
        e,
        message: '配置验证过程中发生错误',
      );
    }
  }

  /// 通知配置变更
  void _notifyConfigChange() {
    if (!_configController.isClosed) {
      _configController.add(_configData);
    }
  }
}
