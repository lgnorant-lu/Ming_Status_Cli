/*
---------------------------------------------------------------
File name:          extension_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.3 - 扩展管理器
                    管理和协调所有扩展的生命周期
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 扩展管理器;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/interfaces/extension_interface.dart';
import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:ming_status_cli/src/version.dart';

/// 扩展管理器
class ExtensionManager {
  factory ExtensionManager() => _instance;
  ExtensionManager._internal();
  static final ExtensionManager _instance = ExtensionManager._internal();

  /// 已注册的扩展
  final Map<String, Extension> _extensions = {};
  
  /// 扩展配置
  final Map<String, Map<String, dynamic>> _extensionConfigs = {};
  
  /// 扩展依赖图
  final Map<String, List<String>> _dependencyGraph = {};
  
  /// 扩展加载顺序
  final List<String> _loadOrder = [];
  
  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化扩展管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('初始化扩展管理器...');
    
    // 加载扩展配置
    await _loadExtensionConfigs();
    
    // 发现可用扩展
    await _discoverExtensions();
    
    // 解析依赖关系
    _resolveDependencies();
    
    // 按依赖顺序加载扩展
    await _loadExtensionsInOrder();
    
    _isInitialized = true;
    Logger.info('扩展管理器初始化完成');
  }

  /// 注册扩展
  Future<void> registerExtension(Extension extension) async {
    final metadata = extension.metadata;
    
    // 检查扩展是否已注册
    if (_extensions.containsKey(metadata.id)) {
      throw StateError('扩展 ${metadata.id} 已经注册');
    }
    
    // 检查版本兼容性
    if (!extension.isCompatible(packageVersion)) {
      throw StateError('扩展 ${metadata.id} 与当前CLI版本不兼容');
    }
    
    // 检查依赖
    await _checkDependencies(metadata);
    
    // 注册扩展
    _extensions[metadata.id] = extension;
    _dependencyGraph[metadata.id] = metadata.dependencies;
    
    // 初始化扩展
    final config = _extensionConfigs[metadata.id] ?? {};
    await extension.initialize(config);
    
    Logger.info('扩展已注册: ${metadata.name} v${metadata.version}');
  }

  /// 注销扩展
  Future<void> unregisterExtension(String extensionId) async {
    final extension = _extensions[extensionId];
    if (extension == null) {
      Logger.warning('尝试注销不存在的扩展: $extensionId');
      return;
    }
    
    // 检查是否有其他扩展依赖此扩展
    final dependents = _findDependents(extensionId);
    if (dependents.isNotEmpty) {
      throw StateError('无法注销扩展 $extensionId，以下扩展依赖它: ${dependents.join(', ')}');
    }
    
    // 销毁扩展
    await extension.dispose();
    
    // 移除扩展
    _extensions.remove(extensionId);
    _dependencyGraph.remove(extensionId);
    _loadOrder.remove(extensionId);
    
    Logger.info('扩展已注销: $extensionId');
  }

  /// 获取扩展
  T? getExtension<T extends Extension>(String extensionId) {
    final extension = _extensions[extensionId];
    if (extension is T) {
      return extension;
    }
    return null;
  }

  /// 获取指定类型的所有扩展
  List<T> getExtensionsByType<T extends Extension>() {
    return _extensions.values
        .whereType<T>()
        .toList();
  }

  /// 获取模板扩展
  List<TemplateExtension> getTemplateExtensions() {
    return getExtensionsByType<TemplateExtension>();
  }

  /// 获取验证器扩展
  List<ValidatorExtension> getValidatorExtensions() {
    return getExtensionsByType<ValidatorExtension>();
  }

  /// 获取生成器扩展
  List<GeneratorExtension> getGeneratorExtensions() {
    return getExtensionsByType<GeneratorExtension>();
  }

  /// 获取命令扩展
  List<CommandExtension> getCommandExtensions() {
    return getExtensionsByType<CommandExtension>();
  }

  /// 获取提供者扩展
  List<ProviderExtension> getProviderExtensions() {
    return getExtensionsByType<ProviderExtension>();
  }

  /// 获取中间件扩展
  List<MiddlewareExtension> getMiddlewareExtensions() {
    return getExtensionsByType<MiddlewareExtension>()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 检查扩展是否存在
  bool hasExtension(String extensionId) {
    return _extensions.containsKey(extensionId);
  }

  /// 获取所有扩展信息
  List<ExtensionInfo> getAllExtensions() {
    return _extensions.values.map((extension) {
      return ExtensionInfo(
        metadata: extension.metadata,
        status: extension.status,
        loadOrder: _loadOrder.indexOf(extension.metadata.id),
      );
    }).toList();
  }

  /// 重新加载扩展
  Future<void> reloadExtension(String extensionId) async {
    final extension = _extensions[extensionId];
    if (extension == null) {
      throw StateError('扩展不存在: $extensionId');
    }
    
    // 销毁当前扩展
    await extension.dispose();
    
    // 重新初始化
    final config = _extensionConfigs[extensionId] ?? {};
    await extension.initialize(config);
    
    Logger.info('扩展已重新加载: $extensionId');
  }

  /// 重新加载所有扩展
  Future<void> reloadAllExtensions() async {
    Logger.info('重新加载所有扩展...');
    
    // 按相反顺序销毁扩展
    for (final extensionId in _loadOrder.reversed) {
      final extension = _extensions[extensionId];
      if (extension != null) {
        await extension.dispose();
      }
    }
    
    // 重新加载配置
    await _loadExtensionConfigs();
    
    // 按正确顺序重新初始化扩展
    for (final extensionId in _loadOrder) {
      final extension = _extensions[extensionId];
      if (extension != null) {
        final config = _extensionConfigs[extensionId] ?? {};
        await extension.initialize(config);
      }
    }
    
    Logger.info('所有扩展重新加载完成');
  }

  /// 获取扩展统计信息
  ExtensionStats getStats() {
    final stats = ExtensionStats();
    
    for (final extension in _extensions.values) {
      stats.totalExtensions++;
      
      switch (extension.status) {
        case ExtensionStatus.active:
          stats.activeExtensions++;
        case ExtensionStatus.inactive:
          stats.inactiveExtensions++;
        case ExtensionStatus.error:
          stats.errorExtensions++;
        default:
          break;
      }
      
      switch (extension.metadata.type) {
        case ExtensionType.template:
          stats.templateExtensions++;
        case ExtensionType.validator:
          stats.validatorExtensions++;
        case ExtensionType.generator:
          stats.generatorExtensions++;
        case ExtensionType.command:
          stats.commandExtensions++;
        case ExtensionType.provider:
          stats.providerExtensions++;
        case ExtensionType.middleware:
          stats.middlewareExtensions++;
      }
    }
    
    return stats;
  }

  /// 加载扩展配置
  Future<void> _loadExtensionConfigs() async {
    // 从配置文件加载扩展配置
    // 这里是预留接口，Phase 2实现
    Logger.debug('加载扩展配置 (Phase 2功能)');
  }

  /// 发现可用扩展
  Future<void> _discoverExtensions() async {
    // 扫描扩展目录，发现可用扩展
    // 这里是预留接口，Phase 2实现
    Logger.debug('发现可用扩展 (Phase 2功能)');
  }

  /// 解析依赖关系
  void _resolveDependencies() {
    // 使用拓扑排序解析依赖关系
    final visited = <String>{};
    final visiting = <String>{};
    
    void visit(String extensionId) {
      if (visiting.contains(extensionId)) {
        throw StateError('检测到循环依赖: $extensionId');
      }
      
      if (visited.contains(extensionId)) {
        return;
      }
      
      visiting.add(extensionId);
      
      final dependencies = _dependencyGraph[extensionId] ?? [];
      for (final dependency in dependencies) {
        visit(dependency);
      }
      
      visiting.remove(extensionId);
      visited.add(extensionId);
      _loadOrder.add(extensionId);
    }
    
    for (final extensionId in _dependencyGraph.keys) {
      if (!visited.contains(extensionId)) {
        visit(extensionId);
      }
    }
  }

  /// 按依赖顺序加载扩展
  Future<void> _loadExtensionsInOrder() async {
    // 按解析的顺序加载扩展
    // 这里是预留接口，Phase 2实现
    Logger.debug('按依赖顺序加载扩展 (Phase 2功能)');
  }

  /// 检查依赖
  Future<void> _checkDependencies(ExtensionMetadata metadata) async {
    for (final dependency in metadata.dependencies) {
      if (!_extensions.containsKey(dependency)) {
        throw StateError('扩展 ${metadata.id} 依赖的扩展 $dependency 未找到');
      }
    }
  }

  /// 查找依赖此扩展的其他扩展
  List<String> _findDependents(String extensionId) {
    final dependents = <String>[];
    
    for (final entry in _dependencyGraph.entries) {
      if (entry.value.contains(extensionId)) {
        dependents.add(entry.key);
      }
    }
    
    return dependents;
  }

  /// 销毁扩展管理器
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    Logger.info('销毁扩展管理器...');
    
    // 按相反顺序销毁所有扩展
    for (final extensionId in _loadOrder.reversed) {
      final extension = _extensions[extensionId];
      if (extension != null) {
        try {
          await extension.dispose();
        } catch (e) {
          Logger.error('销毁扩展失败: $extensionId - $e');
        }
      }
    }
    
    // 清理状态
    _extensions.clear();
    _extensionConfigs.clear();
    _dependencyGraph.clear();
    _loadOrder.clear();
    _isInitialized = false;
    
    Logger.info('扩展管理器已销毁');
  }
}

/// 扩展信息
class ExtensionInfo {

  const ExtensionInfo({
    required this.metadata,
    required this.status,
    required this.loadOrder,
  });
  /// 扩展元数据
  final ExtensionMetadata metadata;
  
  /// 扩展状态
  final ExtensionStatus status;
  
  /// 加载顺序
  final int loadOrder;

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'status': status.name,
      'loadOrder': loadOrder,
    };
  }
}

/// 扩展统计信息
class ExtensionStats {
  /// 总扩展数
  int totalExtensions = 0;
  
  /// 活跃扩展数
  int activeExtensions = 0;
  
  /// 非活跃扩展数
  int inactiveExtensions = 0;
  
  /// 错误扩展数
  int errorExtensions = 0;
  
  /// 模板扩展数
  int templateExtensions = 0;
  
  /// 验证器扩展数
  int validatorExtensions = 0;
  
  /// 生成器扩展数
  int generatorExtensions = 0;
  
  /// 命令扩展数
  int commandExtensions = 0;
  
  /// 提供者扩展数
  int providerExtensions = 0;
  
  /// 中间件扩展数
  int middlewareExtensions = 0;

  Map<String, dynamic> toJson() {
    return {
      'totalExtensions': totalExtensions,
      'activeExtensions': activeExtensions,
      'inactiveExtensions': inactiveExtensions,
      'errorExtensions': errorExtensions,
      'templateExtensions': templateExtensions,
      'validatorExtensions': validatorExtensions,
      'generatorExtensions': generatorExtensions,
      'commandExtensions': commandExtensions,
      'providerExtensions': providerExtensions,
      'middlewareExtensions': middlewareExtensions,
    };
  }
}
