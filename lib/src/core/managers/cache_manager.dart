/*
---------------------------------------------------------------
File name:          cache_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        缓存管理器 (Cache manager)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 缓存管理器功能;
---------------------------------------------------------------
*/

import 'dart:math' as math;

import 'package:mason/mason.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

// ==================== Task 36.* 模板系统最终优化实现 ====================

/// 预编译模板数据结构
class PrecompiledTemplate {
  /// 创建预编译模板实例
  PrecompiledTemplate({
    required this.templateName,
    required this.generator,
    required this.metadata,
    required this.variables,
    required this.compilationTime,
    required this.lastAccessed,
  });

  /// 模板名称
  final String templateName;
  /// Mason生成器实例
  final MasonGenerator generator;
  /// 模板元数据
  final Map<String, dynamic> metadata;
  /// 模板变量列表
  final List<String> variables;  // 修复类型错误：使用List<String>而不是List<BrickVariableProperties>
  /// 编译时间
  final DateTime compilationTime;
  /// 最后访问时间
  DateTime lastAccessed;
  
  /// 缓存过期时间
  static const Duration cacheExpiry = Duration(hours: 2);
  
  /// 是否已过期
  bool get isExpired => 
      DateTime.now().difference(compilationTime) > cacheExpiry;
}

/// 缓存访问统计
class CacheAccessStats {
  /// 创建缓存访问统计实例
  CacheAccessStats({
    this.hitCount = 0,
    this.missCount = 0,
    this.precompileCount = 0,
  });

  /// 缓存命中次数
  int hitCount;
  /// 缓存未命中次数
  int missCount;
  /// 预编译次数
  int precompileCount;
  
  /// 缓存命中率（命中次数 / 总访问次数）
  double get hitRate => 
      hitCount + missCount > 0 ? hitCount / (hitCount + missCount) : 0.0;
}

/// Task 36.1: 高级模板缓存和预编译优化系统
class AdvancedTemplateCacheManager {
  /// 创建高级模板缓存管理器实例
  AdvancedTemplateCacheManager(this.templateEngine);

  /// 模板引擎实例（使用动态类型避免循环依赖）
  final dynamic templateEngine;
  
  /// 预编译模板缓存
  final Map<String, PrecompiledTemplate> _precompiledCache = {};
  
  /// 缓存访问统计
  final Map<String, CacheAccessStats> _cacheStats = {};
  
  /// 预热任务队列
  final Set<String> _preheatingQueue = {};
  
  /// 缓存配置
  /// 最大缓存大小
  static const int maxCacheSize = 50;
  /// 预热任务间隔时间
  static const Duration preheatingInterval = Duration(minutes: 5);
  /// 缓存过期时间
  static const Duration cacheExpiry = Duration(hours: 2);

  /// 预编译单个模板
  Future<PrecompiledTemplate?> precompileTemplate(String templateName) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      cli_logger.Logger.debug('开始预编译模板: $templateName');
      
      // 检查现有缓存
      if (_precompiledCache.containsKey(templateName)) {
        final cached = _precompiledCache[templateName]!;
        if (!cached.isExpired) {
          cached.lastAccessed = DateTime.now();
          _updateStats(templateName, hit: true);
          cli_logger.Logger.debug('使用已预编译的模板: $templateName');
          return cached;
        }
      }

      // 加载并预编译模板
      final dynamic generatorResult = await templateEngine.loadTemplate(templateName);
      if (generatorResult == null) {
        _updateStats(templateName, miss: true);
        return null;
      }
      final generator = generatorResult as MasonGenerator;

      // 获取模板元数据
      final dynamic metadataResult = await templateEngine.getTemplateInfo(templateName);
      final metadata = (metadataResult as Map<String, dynamic>?) ?? <String, dynamic>{};
      
      // 获取变量定义
      final dynamic variablesResult = generator.vars;
      final variables = (variablesResult as List<dynamic>).cast<String>();

      // 创建预编译模板
      final precompiled = PrecompiledTemplate(
        templateName: templateName,
        generator: generator,
        metadata: metadata,
        variables: variables,
        compilationTime: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      // 缓存管理
      await _manageCacheSize();
      _precompiledCache[templateName] = precompiled;
      
      _updateStats(templateName, precompile: true);
      
      cli_logger.Logger.success(
        '模板预编译完成: $templateName (${stopwatch.elapsedMilliseconds}ms)',
      );
      
      return precompiled;

    } catch (e) {
      cli_logger.Logger.error('模板预编译失败: $templateName', error: e);
      _updateStats(templateName, miss: true);
      return null;
    }
  }

  /// 批量预编译常用模板
  Future<void> precompileFrequentTemplates() async {
    try {
      final dynamic templatesResult = await templateEngine.getAvailableTemplates();
      final availableTemplates = (templatesResult as List<dynamic>).cast<String>();
      
      // 根据访问统计确定频繁使用的模板
      final frequentTemplates = _getFrequentTemplates(availableTemplates);
      
      cli_logger.Logger.info('开始批量预编译 ${frequentTemplates.length} 个常用模板');
      
      final futures = frequentTemplates.map((template) => 
          _preheatingQueue.add(template) ? precompileTemplate(template) : null,
      ).where((future) => future != null).cast<Future<PrecompiledTemplate?>>();
      
      final results = await Future.wait(futures);
      final successCount = results.where((result) => result != null).length;
      
      cli_logger.Logger.success(
        '批量预编译完成: $successCount/${frequentTemplates.length} 个模板成功',
      );
      
      _preheatingQueue.clear();

    } catch (e) {
      cli_logger.Logger.error('批量预编译失败', error: e);
      _preheatingQueue.clear();
    }
  }

  /// 获取预编译模板（缓存优先）
  Future<PrecompiledTemplate?> getPrecompiledTemplate(String templateName) async {
    // 检查预编译缓存
    if (_precompiledCache.containsKey(templateName)) {
      final cached = _precompiledCache[templateName]!;
      if (!cached.isExpired) {
        cached.lastAccessed = DateTime.now();
        _updateStats(templateName, hit: true);
        return cached;
      } else {
        // 移除过期缓存
        _precompiledCache.remove(templateName);
      }
    }

    // 实时预编译
    return precompileTemplate(templateName);
  }

  /// 缓存预热任务
  Future<void> warmUpCache() async {
    cli_logger.Logger.info('开始缓存预热...');
    
    final stopwatch = Stopwatch()..start();
    
    // 预编译常用模板
    await precompileFrequentTemplates();
    
    // 清理过期缓存
    await _cleanExpiredCache();
    
    cli_logger.Logger.success(
      '缓存预热完成 (${stopwatch.elapsedMilliseconds}ms)',
    );
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStatistics() {
    final totalHits = _cacheStats.values.fold(0, (sum, stats) => sum + stats.hitCount);
    final totalMisses = _cacheStats.values.fold(0, (sum, stats) => sum + stats.missCount);
    final totalPrecompiles = _cacheStats.values.fold(0, (sum, stats) => sum + stats.precompileCount);
    
    return {
      'cache_size': _precompiledCache.length,
      'max_cache_size': maxCacheSize,
      'cache_utilization': _precompiledCache.length / maxCacheSize,
      'total_hits': totalHits,
      'total_misses': totalMisses,
      'total_precompiles': totalPrecompiles,
      'hit_rate': totalHits + totalMisses > 0 
          ? totalHits / (totalHits + totalMisses) 
          : 0.0,
      'templates_in_cache': _precompiledCache.keys.toList(),
      'expired_count': _precompiledCache.values.where((t) => t.isExpired).length,
      'recent_activity': _getRecentCacheActivity(),
    };
  }

  /// 清理缓存
  Future<void> clearCache() async {
    final beforeSize = _precompiledCache.length;
    _precompiledCache.clear();
    _cacheStats.clear();
    _preheatingQueue.clear();
    
    cli_logger.Logger.info('缓存已清理，移除了 $beforeSize 个预编译模板');
  }

  // 私有辅助方法

  /// 更新缓存统计
  void _updateStats(String templateName, {bool hit = false, bool miss = false, bool precompile = false}) {
    final stats = _cacheStats.putIfAbsent(templateName, CacheAccessStats.new);
    
    if (hit) stats.hitCount++;
    if (miss) stats.missCount++;
    if (precompile) stats.precompileCount++;
  }

  /// 管理缓存大小
  Future<void> _manageCacheSize() async {
    if (_precompiledCache.length >= maxCacheSize) {
      // 移除最旧的和最少使用的模板
      final sortedTemplates = _precompiledCache.entries.toList()
        ..sort((a, b) {
          // 首先按过期状态排序
          if (a.value.isExpired && !b.value.isExpired) return -1;
          if (!a.value.isExpired && b.value.isExpired) return 1;
          
          // 然后按最后访问时间排序
          return a.value.lastAccessed.compareTo(b.value.lastAccessed);
        });

      // 移除25%的旧缓存
      final removeCount = (maxCacheSize * 0.25).ceil();
      for (var i = 0; i < removeCount && i < sortedTemplates.length; i++) {
        final templateName = sortedTemplates[i].key;
        _precompiledCache.remove(templateName);
        cli_logger.Logger.debug('移除旧缓存: $templateName');
      }
    }
  }

  /// 获取频繁使用的模板
  List<String> _getFrequentTemplates(List<String> availableTemplates) {
    // 根据访问统计排序
    final templatesWithStats = availableTemplates.map((template) {
      final stats = _cacheStats[template];
      final score = stats != null 
          ? stats.hitCount + stats.missCount + stats.precompileCount
          : 0;
      return MapEntry(template, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 返回前70%或至少前3个
    final topCount = math.max(3, (availableTemplates.length * 0.7).ceil());
    return templatesWithStats
        .take(topCount)
        .map((entry) => entry.key)
        .toList();
  }

  /// 清理过期缓存
  Future<void> _cleanExpiredCache() async {
    final expiredTemplates = _precompiledCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final templateName in expiredTemplates) {
      _precompiledCache.remove(templateName);
    }

    if (expiredTemplates.isNotEmpty) {
      cli_logger.Logger.debug('清理了 ${expiredTemplates.length} 个过期缓存');
    }
  }

  /// 获取最近缓存活动
  List<Map<String, dynamic>> _getRecentCacheActivity() {
    return _precompiledCache.entries
        .map((entry) => {
          'template': entry.key,
          'last_accessed': entry.value.lastAccessed.toIso8601String(),
          'compilation_time': entry.value.compilationTime.toIso8601String(),
          'is_expired': entry.value.isExpired,
        },)
        .toList()
      ..sort((a, b) => (b['last_accessed']! as String)
          .compareTo(a['last_accessed']! as String),);
  }
}

