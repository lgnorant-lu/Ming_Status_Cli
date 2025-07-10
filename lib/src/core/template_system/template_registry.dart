/*
---------------------------------------------------------------
File name:          template_registry.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板注册表系统 (Enterprise Template Registry System)
---------------------------------------------------------------
Change History:    
    2025/07/10: Initial creation - Phase 2.1 高级模板注册表管理;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 模板搜索查询
///
/// 定义模板搜索的条件和参数
class TemplateSearchQuery {
  /// 创建搜索查询实例
  const TemplateSearchQuery({
    this.keyword,
    this.type,
    this.subType,
    this.platform,
    this.framework,
    this.complexity,
    this.maturity,
    this.tags = const [],
    this.author,
    this.organizationId,
    this.teamId,
    this.minRating,
    this.sortBy = TemplateSortBy.relevance,
    this.sortOrder = SortOrder.descending,
    this.limit = 50,
    this.offset = 0,
  });

  /// 关键词搜索
  final String? keyword;

  /// 模板类型过滤
  final TemplateType? type;

  /// 模板子类型过滤
  final TemplateSubType? subType;

  /// 平台过滤
  final TemplatePlatform? platform;

  /// 框架过滤
  final TemplateFramework? framework;

  /// 复杂度过滤
  final TemplateComplexity? complexity;

  /// 成熟度过滤
  final TemplateMaturity? maturity;

  /// 标签过滤
  final List<String> tags;

  /// 作者过滤
  final String? author;

  /// 组织ID过滤
  final String? organizationId;

  /// 团队ID过滤
  final String? teamId;

  /// 最低评分过滤
  final double? minRating;

  /// 排序方式
  final TemplateSortBy sortBy;

  /// 排序顺序
  final SortOrder sortOrder;

  /// 结果限制数量
  final int limit;

  /// 结果偏移量
  final int offset;
}

/// 模板排序方式
enum TemplateSortBy {
  /// 相关性排序
  relevance,

  /// 名称排序
  name,

  /// 创建时间排序
  createdAt,

  /// 更新时间排序
  updatedAt,

  /// 下载次数排序
  downloadCount,

  /// 评分排序
  rating,
}

/// 排序顺序
enum SortOrder {
  /// 升序
  ascending,

  /// 降序
  descending,
}

/// 模板搜索结果
///
/// 包含搜索结果和分页信息
class TemplateSearchResult {
  /// 创建搜索结果实例
  const TemplateSearchResult({
    required this.templates,
    required this.totalCount,
    required this.query,
    this.suggestions = const [],
  });

  /// 搜索到的模板列表
  final List<TemplateMetadata> templates;

  /// 总结果数量
  final int totalCount;

  /// 搜索查询
  final TemplateSearchQuery query;

  /// 搜索建议
  final List<String> suggestions;

  /// 是否有更多结果
  bool get hasMore => query.offset + templates.length < totalCount;

  /// 当前页码 (从1开始)
  int get currentPage => (query.offset ~/ query.limit) + 1;

  /// 总页数
  int get totalPages => (totalCount / query.limit).ceil();
}

/// 企业级模板注册表
///
/// 提供模板的注册、搜索、管理功能
class TemplateRegistry {
  /// 创建模板注册表实例
  TemplateRegistry({
    required this.registryPath,
    this.cacheEnabled = true,
    this.cacheTimeout = const Duration(hours: 1),
  });

  /// 注册表存储路径
  final String registryPath;

  /// 是否启用缓存
  final bool cacheEnabled;

  /// 缓存超时时间
  final Duration cacheTimeout;

  /// 模板元数据缓存
  final Map<String, TemplateMetadata> _metadataCache = {};

  /// 模板实例缓存
  final Map<String, AdvancedTemplate> _templateCache = {};

  /// 搜索索引缓存
  final Map<String, List<String>> _searchIndex = {};

  /// 缓存时间戳
  final Map<String, DateTime> _cacheTimestamps = {};

  /// 初始化注册表
  ///
  /// 创建必要的目录结构和索引文件
  Future<void> initialize() async {
    try {
      // 创建注册表目录
      final registryDir = Directory(registryPath);
      if (!await registryDir.exists()) {
        await registryDir.create(recursive: true);
      }

      // 创建子目录
      final metadataDir = Directory(path.join(registryPath, 'metadata'));
      final templatesDir = Directory(path.join(registryPath, 'templates'));
      final indexDir = Directory(path.join(registryPath, 'index'));

      await Future.wait([
        metadataDir.create(recursive: true),
        templatesDir.create(recursive: true),
        indexDir.create(recursive: true),
      ]);

      // 构建搜索索引
      await _buildSearchIndex();

      cli_logger.Logger.info('模板注册表初始化完成: $registryPath');
    } catch (e) {
      cli_logger.Logger.error('模板注册表初始化失败', error: e);
      rethrow;
    }
  }

  /// 注册模板
  ///
  /// 将模板添加到注册表中
  Future<void> registerTemplate(AdvancedTemplate template) async {
    try {
      final metadata = template.metadata;

      // 验证模板元数据
      _validateTemplateMetadata(metadata);

      // 保存元数据
      await _saveTemplateMetadata(metadata);

      // 缓存模板
      if (cacheEnabled) {
        _metadataCache[metadata.id] = metadata;
        _templateCache[metadata.id] = template;
        _cacheTimestamps[metadata.id] = DateTime.now();
      }

      // 更新搜索索引
      await _updateSearchIndex(metadata);

      cli_logger.Logger.info('模板注册成功: ${metadata.name} (${metadata.id})');
    } catch (e) {
      cli_logger.Logger.error('模板注册失败', error: e);
      rethrow;
    }
  }

  /// 获取模板元数据
  ///
  /// 根据模板ID获取元数据信息
  Future<TemplateMetadata?> getTemplateMetadata(String templateId) async {
    try {
      // 检查缓存
      if (cacheEnabled && _metadataCache.containsKey(templateId)) {
        final cacheTime = _cacheTimestamps[templateId];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < cacheTimeout) {
          return _metadataCache[templateId];
        }
      }

      // 从文件加载
      final metadataFile =
          File(path.join(registryPath, 'metadata', '$templateId.json'));
      if (!await metadataFile.exists()) {
        return null;
      }

      await metadataFile.readAsString();
      final jsonData = Map<String, dynamic>.from(
        // 这里需要JSON解析，简化处理
        <String, dynamic>{},
      );

      final metadata = TemplateMetadata.fromJson(jsonData);

      // 更新缓存
      if (cacheEnabled) {
        _metadataCache[templateId] = metadata;
        _cacheTimestamps[templateId] = DateTime.now();
      }

      return metadata;
    } catch (e) {
      cli_logger.Logger.error('获取模板元数据失败: $templateId', error: e);
      return null;
    }
  }

  /// 搜索模板
  ///
  /// 根据查询条件搜索模板
  Future<TemplateSearchResult> searchTemplates(
      TemplateSearchQuery query,) async {
    try {
      // 获取所有模板元数据
      final allTemplates = await _getAllTemplateMetadata();

      // 应用过滤条件
      var filteredTemplates = allTemplates.where((template) {
        return _matchesQuery(template, query);
      }).toList();

      // 应用排序
      _sortTemplates(filteredTemplates, query.sortBy, query.sortOrder);

      // 应用分页
      final totalCount = filteredTemplates.length;
      final startIndex = query.offset;
      final endIndex = (startIndex + query.limit).clamp(0, totalCount);

      if (startIndex < totalCount) {
        filteredTemplates = filteredTemplates.sublist(startIndex, endIndex);
      } else {
        filteredTemplates = [];
      }

      return TemplateSearchResult(
        templates: filteredTemplates,
        totalCount: totalCount,
        query: query,
        suggestions: _generateSearchSuggestions(query, allTemplates),
      );
    } catch (e) {
      cli_logger.Logger.error('模板搜索失败', error: e);
      return TemplateSearchResult(
        templates: [],
        totalCount: 0,
        query: query,
      );
    }
  }

  /// 获取模板列表
  ///
  /// 获取指定类型的模板列表
  Future<List<TemplateMetadata>> getTemplatesByType(TemplateType type) async {
    final query = TemplateSearchQuery(type: type);
    final result = await searchTemplates(query);
    return result.templates;
  }

  /// 获取模板列表 (按平台)
  ///
  /// 获取支持指定平台的模板列表
  Future<List<TemplateMetadata>> getTemplatesByPlatform(
      TemplatePlatform platform,) async {
    final query = TemplateSearchQuery(platform: platform);
    final result = await searchTemplates(query);
    return result.templates;
  }

  /// 获取模板列表 (按分类)
  ///
  /// 获取指定分类的模板列表
  Future<List<TemplateMetadata>> getTemplatesByCategory(String category) async {
    final allTemplates = await _getAllTemplateMetadata();
    return allTemplates
        .where((template) => template.category == category)
        .toList();
  }

  /// 清理缓存
  ///
  /// 清理过期的缓存数据
  void clearCache() {
    _metadataCache.clear();
    _templateCache.clear();
    _searchIndex.clear();
    _cacheTimestamps.clear();
    cli_logger.Logger.info('模板注册表缓存已清理');
  }

  /// 验证模板元数据
  void _validateTemplateMetadata(TemplateMetadata metadata) {
    if (metadata.id.isEmpty) {
      throw ArgumentError('模板ID不能为空');
    }
    if (metadata.name.isEmpty) {
      throw ArgumentError('模板名称不能为空');
    }
    if (metadata.version.isEmpty) {
      throw ArgumentError('模板版本不能为空');
    }
  }

  /// 保存模板元数据
  Future<void> _saveTemplateMetadata(TemplateMetadata metadata) async {
    final metadataFile =
        File(path.join(registryPath, 'metadata', '${metadata.id}.json'));
    // 这里需要JSON序列化，简化处理
    await metadataFile.writeAsString('{}');
  }

  /// 构建搜索索引
  Future<void> _buildSearchIndex() async {
    // 实现搜索索引构建逻辑
    cli_logger.Logger.debug('构建搜索索引...');
  }

  /// 更新搜索索引
  Future<void> _updateSearchIndex(TemplateMetadata metadata) async {
    // 实现搜索索引更新逻辑
    cli_logger.Logger.debug('更新搜索索引: ${metadata.id}');
  }

  /// 获取所有模板元数据
  Future<List<TemplateMetadata>> _getAllTemplateMetadata() async {
    // 实现获取所有模板元数据的逻辑
    return [];
  }

  /// 检查模板是否匹配查询条件
  bool _matchesQuery(TemplateMetadata template, TemplateSearchQuery query) {
    // 实现查询匹配逻辑
    return true;
  }

  /// 排序模板列表
  void _sortTemplates(
    List<TemplateMetadata> templates,
    TemplateSortBy sortBy,
    SortOrder sortOrder,
  ) {
    // 实现排序逻辑
  }

  /// 生成搜索建议
  List<String> _generateSearchSuggestions(
    TemplateSearchQuery query,
    List<TemplateMetadata> allTemplates,
  ) {
    // 实现搜索建议生成逻辑
    return [];
  }
}
