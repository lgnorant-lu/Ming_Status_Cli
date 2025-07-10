/*
---------------------------------------------------------------
File name:          library_index.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        高级索引系统 (Advanced Library Index System)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板库管理系统;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/creation/template_library_manager.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 索引类型
enum IndexType {
  /// 名称索引
  name,
  
  /// 描述索引
  description,
  
  /// 标签索引
  tags,
  
  /// 作者索引
  author,
  
  /// 分类索引
  category,
  
  /// 复合索引
  composite,
}

/// 搜索权重配置
class SearchWeights {
  /// 创建搜索权重配置实例
  const SearchWeights({
    this.nameWeight = 1.0,
    this.descriptionWeight = 0.8,
    this.tagsWeight = 0.9,
    this.authorWeight = 0.6,
    this.categoryWeight = 0.7,
    this.downloadWeight = 0.3,
    this.ratingWeight = 0.4,
    this.freshnessWeight = 0.2,
  });

  /// 名称权重
  final double nameWeight;
  
  /// 描述权重
  final double descriptionWeight;
  
  /// 标签权重
  final double tagsWeight;
  
  /// 作者权重
  final double authorWeight;
  
  /// 分类权重
  final double categoryWeight;
  
  /// 下载次数权重
  final double downloadWeight;
  
  /// 评分权重
  final double ratingWeight;
  
  /// 新鲜度权重
  final double freshnessWeight;
}

/// 索引条目
class IndexEntry {
  /// 创建索引条目实例
  const IndexEntry({
    required this.templateId,
    required this.libraryId,
    required this.terms,
    required this.score,
    this.metadata = const {},
  });

  /// 模板ID
  final String templateId;
  
  /// 库ID
  final String libraryId;
  
  /// 索引词条
  final List<String> terms;
  
  /// 索引评分
  final double score;
  
  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 搜索结果
class SearchResult {
  /// 创建搜索结果实例
  const SearchResult({
    required this.templateId,
    required this.libraryId,
    required this.score,
    required this.relevance,
    this.highlights = const [],
    this.explanation,
  });

  /// 模板ID
  final String templateId;
  
  /// 库ID
  final String libraryId;
  
  /// 搜索评分
  final double score;
  
  /// 相关性评分
  final double relevance;
  
  /// 高亮词条
  final List<String> highlights;
  
  /// 评分解释
  final String? explanation;
}

/// 推荐结果
class RecommendationResult {
  /// 创建推荐结果实例
  const RecommendationResult({
    required this.templateId,
    required this.libraryId,
    required this.score,
    required this.reason,
    this.confidence = 0.0,
    this.metadata = const {},
  });

  /// 模板ID
  final String templateId;
  
  /// 库ID
  final String libraryId;
  
  /// 推荐评分
  final double score;
  
  /// 推荐原因
  final String reason;
  
  /// 置信度
  final double confidence;
  
  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 索引统计信息
class IndexStatistics {
  /// 创建索引统计信息实例
  const IndexStatistics({
    required this.totalEntries,
    required this.totalTerms,
    required this.averageTermsPerEntry,
    required this.indexSize,
    required this.lastUpdateTime,
    this.buildTime,
    this.queryCount = 0,
    this.averageQueryTime,
  });

  /// 总条目数
  final int totalEntries;
  
  /// 总词条数
  final int totalTerms;
  
  /// 平均每条目词条数
  final double averageTermsPerEntry;
  
  /// 索引大小 (字节)
  final int indexSize;
  
  /// 最后更新时间
  final DateTime lastUpdateTime;
  
  /// 构建耗时
  final Duration? buildTime;
  
  /// 查询次数
  final int queryCount;
  
  /// 平均查询时间
  final Duration? averageQueryTime;
}

/// 高级索引系统
class LibraryIndex {
  /// 创建索引系统实例
  LibraryIndex({
    String? indexPath,
    this.searchWeights = const SearchWeights(),
    this.enableIncrementalUpdate = true,
    this.maxCacheSize = 1000,
    this.enableQueryCache = true,
  }) : _indexPath = indexPath ?? _getDefaultIndexPath();

  /// 索引文件路径
  final String _indexPath;
  
  /// 搜索权重配置
  final SearchWeights searchWeights;
  
  /// 是否启用增量更新
  final bool enableIncrementalUpdate;
  
  /// 最大缓存大小
  final int maxCacheSize;
  
  /// 是否启用查询缓存
  final bool enableQueryCache;

  /// 索引数据
  final Map<IndexType, Map<String, List<IndexEntry>>> _indexes = {};
  
  /// 反向索引
  final Map<String, Set<String>> _inverseIndex = {};
  
  /// 查询缓存
  final Map<String, List<SearchResult>> _queryCache = {};
  
  /// 使用历史
  final Map<String, int> _usageHistory = {};
  
  /// 索引统计
  IndexStatistics? _statistics;
  
  /// 最后更新时间
  DateTime? _lastUpdateTime;

  /// 初始化索引系统
  Future<void> initialize() async {
    try {
      cli_logger.Logger.debug('初始化高级索引系统');
      
      await _loadIndexData();
      await _buildInverseIndex();
      
      cli_logger.Logger.info('高级索引系统初始化完成');
    } catch (e) {
      cli_logger.Logger.error('高级索引系统初始化失败', error: e);
      rethrow;
    }
  }

  /// 构建索引
  Future<void> buildIndex(List<TemplateLibraryEntry> templates) async {
    final startTime = DateTime.now();
    
    try {
      cli_logger.Logger.debug('开始构建索引: ${templates.length}个模板');
      
      // 清空现有索引
      _indexes.clear();
      _inverseIndex.clear();
      
      // 初始化索引类型
      for (final type in IndexType.values) {
        _indexes[type] = {};
      }
      
      // 构建各类型索引
      for (final template in templates) {
        await _indexTemplate(template);
      }
      
      // 构建反向索引
      await _buildInverseIndex();
      
      // 保存索引数据
      await _saveIndexData();
      
      // 更新统计信息
      await _updateStatistics(startTime);
      
      _lastUpdateTime = DateTime.now();
      
      cli_logger.Logger.info('索引构建完成: ${_getTotalEntries()}个条目');
    } catch (e) {
      cli_logger.Logger.error('索引构建失败', error: e);
      rethrow;
    }
  }

  /// 增量更新索引
  Future<void> updateIndex(List<TemplateLibraryEntry> templates) async {
    if (!enableIncrementalUpdate) {
      await buildIndex(templates);
      return;
    }
    
    try {
      cli_logger.Logger.debug('增量更新索引: ${templates.length}个模板');
      
      for (final template in templates) {
        // 移除旧索引
        await _removeTemplateFromIndex(template.id);
        
        // 添加新索引
        await _indexTemplate(template);
      }
      
      // 重建反向索引
      await _buildInverseIndex();
      
      // 保存索引数据
      await _saveIndexData();
      
      _lastUpdateTime = DateTime.now();
      
      cli_logger.Logger.info('增量索引更新完成');
    } catch (e) {
      cli_logger.Logger.error('增量索引更新失败', error: e);
    }
  }

  /// 全文搜索
  Future<List<SearchResult>> search(
    String query, {
    int limit = 20,
    double minScore = 0.1,
    List<String>? libraryIds,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final cacheKey = _generateCacheKey(query, limit, minScore, libraryIds, filters);
      
      // 检查查询缓存
      if (enableQueryCache && _queryCache.containsKey(cacheKey)) {
        cli_logger.Logger.debug('使用缓存搜索结果: $query');
        return _queryCache[cacheKey]!;
      }
      
      cli_logger.Logger.debug('执行全文搜索: $query');
      
      final results = await _performSearch(query, limit, minScore, libraryIds, filters);
      
      // 缓存结果
      if (enableQueryCache && _queryCache.length < maxCacheSize) {
        _queryCache[cacheKey] = results;
      }
      
      // 更新使用历史
      _updateUsageHistory(query);
      
      cli_logger.Logger.info('搜索完成: 找到${results.length}个结果');
      return results;
    } catch (e) {
      cli_logger.Logger.error('搜索失败: $query', error: e);
      return [];
    }
  }

  /// 智能推荐
  Future<List<RecommendationResult>> recommend({
    String? userId,
    List<String>? usageHistory,
    Map<String, dynamic>? context,
    int limit = 10,
  }) async {
    try {
      cli_logger.Logger.debug('生成智能推荐');
      
      final recommendations = <RecommendationResult>[];
      
      // 基于使用历史的推荐
      if (usageHistory != null && usageHistory.isNotEmpty) {
        final historyRecommendations = await _recommendByHistory(usageHistory, limit ~/ 2);
        recommendations.addAll(historyRecommendations);
      }
      
      // 基于流行度的推荐
      final popularRecommendations = await _recommendByPopularity(limit - recommendations.length);
      recommendations.addAll(popularRecommendations);
      
      // 基于上下文的推荐
      if (context != null && context.isNotEmpty) {
        final contextRecommendations = await _recommendByContext(context, limit);
        recommendations.addAll(contextRecommendations);
      }
      
      // 去重和排序
      final uniqueRecommendations = _deduplicateRecommendations(recommendations);
      uniqueRecommendations.sort((a, b) => b.score.compareTo(a.score));
      
      final result = uniqueRecommendations.take(limit).toList();
      
      cli_logger.Logger.info('推荐生成完成: ${result.length}个推荐');
      return result;
    } catch (e) {
      cli_logger.Logger.error('推荐生成失败', error: e);
      return [];
    }
  }

  /// 获取索引统计信息
  IndexStatistics? getStatistics() {
    return _statistics;
  }

  /// 清理缓存
  void clearCache() {
    _queryCache.clear();
    cli_logger.Logger.debug('索引缓存已清理');
  }

  /// 获取默认索引路径
  static String _getDefaultIndexPath() {
    final homeDir = Platform.environment['HOME'] ?? 
                   Platform.environment['USERPROFILE'] ?? 
                   '.';
    return '$homeDir/.ming/index';
  }

  /// 索引模板
  Future<void> _indexTemplate(TemplateLibraryEntry template) async {
    // 名称索引
    final nameTerms = _tokenize(template.name);
    _addToIndex(IndexType.name, template.name.toLowerCase(), IndexEntry(
      templateId: template.id,
      libraryId: 'unknown', // 这里需要从模板获取库ID
      terms: nameTerms,
      score: _calculateNameScore(template),
    ),);
    
    // 描述索引
    if (template.description != null) {
      final descTerms = _tokenize(template.description!);
      _addToIndex(IndexType.description, template.description!.toLowerCase(), IndexEntry(
        templateId: template.id,
        libraryId: 'unknown',
        terms: descTerms,
        score: _calculateDescriptionScore(template),
      ),);
    }
    
    // 标签索引
    for (final tag in template.tags) {
      _addToIndex(IndexType.tags, tag.toLowerCase(), IndexEntry(
        templateId: template.id,
        libraryId: 'unknown',
        terms: [tag],
        score: _calculateTagScore(template),
      ),);
    }
    
    // 作者索引
    if (template.author != null) {
      _addToIndex(IndexType.author, template.author!.toLowerCase(), IndexEntry(
        templateId: template.id,
        libraryId: 'unknown',
        terms: [template.author!],
        score: _calculateAuthorScore(template),
      ),);
    }
    
    // 分类索引
    if (template.category != null) {
      _addToIndex(IndexType.category, template.category!.toLowerCase(), IndexEntry(
        templateId: template.id,
        libraryId: 'unknown',
        terms: [template.category!],
        score: _calculateCategoryScore(template),
      ),);
    }
  }

  /// 分词
  List<String> _tokenize(String text) {
    // 简单的分词实现
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 2)
        .toList();
  }

  /// 添加到索引
  void _addToIndex(IndexType type, String key, IndexEntry entry) {
    _indexes[type] ??= {};
    _indexes[type]![key] ??= [];
    _indexes[type]![key]!.add(entry);
  }

  /// 计算名称评分
  double _calculateNameScore(TemplateLibraryEntry template) {
    return searchWeights.nameWeight * 
           (1.0 + template.downloadCount / 1000.0) * 
           (template.rating / 5.0);
  }

  /// 计算描述评分
  double _calculateDescriptionScore(TemplateLibraryEntry template) {
    return searchWeights.descriptionWeight * 
           (1.0 + template.downloadCount / 1000.0) * 
           (template.rating / 5.0);
  }

  /// 计算标签评分
  double _calculateTagScore(TemplateLibraryEntry template) {
    return searchWeights.tagsWeight * 
           (1.0 + template.downloadCount / 1000.0) * 
           (template.rating / 5.0);
  }

  /// 计算作者评分
  double _calculateAuthorScore(TemplateLibraryEntry template) {
    return searchWeights.authorWeight * 
           (1.0 + template.downloadCount / 1000.0) * 
           (template.rating / 5.0);
  }

  /// 计算分类评分
  double _calculateCategoryScore(TemplateLibraryEntry template) {
    return searchWeights.categoryWeight * 
           (1.0 + template.downloadCount / 1000.0) * 
           (template.rating / 5.0);
  }

  /// 构建反向索引
  Future<void> _buildInverseIndex() async {
    _inverseIndex.clear();
    
    for (final typeIndexes in _indexes.values) {
      for (final entries in typeIndexes.values) {
        for (final entry in entries) {
          for (final term in entry.terms) {
            _inverseIndex[term] ??= {};
            _inverseIndex[term]!.add(entry.templateId);
          }
        }
      }
    }
  }

  /// 执行搜索
  Future<List<SearchResult>> _performSearch(
    String query,
    int limit,
    double minScore,
    List<String>? libraryIds,
    Map<String, dynamic>? filters,
  ) async {
    final queryTerms = _tokenize(query);
    final results = <SearchResult>[];
    final scoreMap = <String, double>{};
    
    // 搜索各个索引
    for (final term in queryTerms) {
      for (final type in IndexType.values) {
        final typeIndex = _indexes[type];
        if (typeIndex != null) {
          for (final key in typeIndex.keys) {
            if (key.contains(term)) {
              final entries = typeIndex[key]!;
              for (final entry in entries) {
                final currentScore = scoreMap[entry.templateId] ?? 0.0;
                scoreMap[entry.templateId] = currentScore + entry.score;
              }
            }
          }
        }
      }
    }
    
    // 转换为搜索结果
    for (final entry in scoreMap.entries) {
      if (entry.value >= minScore) {
        results.add(SearchResult(
          templateId: entry.key,
          libraryId: 'unknown', // 需要从索引条目获取
          score: entry.value,
          relevance: _calculateRelevance(entry.key, queryTerms),
          highlights: _findHighlights(entry.key, queryTerms),
        ),);
      }
    }
    
    // 排序和限制
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// 计算相关性
  double _calculateRelevance(String templateId, List<String> queryTerms) {
    // 简单的相关性计算
    return 1; // 这里可以实现更复杂的相关性算法
  }

  /// 查找高亮词条
  List<String> _findHighlights(String templateId, List<String> queryTerms) {
    // 简单的高亮实现
    return queryTerms;
  }

  /// 基于历史推荐
  Future<List<RecommendationResult>> _recommendByHistory(
    List<String> history,
    int limit,
  ) async {
    // 基于使用历史的推荐算法
    return [];
  }

  /// 基于流行度推荐
  Future<List<RecommendationResult>> _recommendByPopularity(int limit) async {
    // 基于流行度的推荐算法
    return [];
  }

  /// 基于上下文推荐
  Future<List<RecommendationResult>> _recommendByContext(
    Map<String, dynamic> context,
    int limit,
  ) async {
    // 基于上下文的推荐算法
    return [];
  }

  /// 去重推荐结果
  List<RecommendationResult> _deduplicateRecommendations(
    List<RecommendationResult> recommendations,
  ) {
    final seen = <String>{};
    final unique = <RecommendationResult>[];
    
    for (final rec in recommendations) {
      if (!seen.contains(rec.templateId)) {
        seen.add(rec.templateId);
        unique.add(rec);
      }
    }
    
    return unique;
  }

  /// 生成缓存键
  String _generateCacheKey(
    String query,
    int limit,
    double minScore,
    List<String>? libraryIds,
    Map<String, dynamic>? filters,
  ) {
    return '$query:$limit:$minScore:${libraryIds?.join(',')}:$filters';
  }

  /// 更新使用历史
  void _updateUsageHistory(String query) {
    _usageHistory[query] = (_usageHistory[query] ?? 0) + 1;
  }

  /// 移除模板索引
  Future<void> _removeTemplateFromIndex(String templateId) async {
    for (final typeIndex in _indexes.values) {
      for (final entries in typeIndex.values) {
        entries.removeWhere((entry) => entry.templateId == templateId);
      }
    }
  }

  /// 获取总条目数
  int _getTotalEntries() {
    var total = 0;
    for (final typeIndex in _indexes.values) {
      for (final entries in typeIndex.values) {
        total += entries.length;
      }
    }
    return total;
  }

  /// 加载索引数据
  Future<void> _loadIndexData() async {
    // 实现索引数据加载
  }

  /// 保存索引数据
  Future<void> _saveIndexData() async {
    // 实现索引数据保存
  }

  /// 更新统计信息
  Future<void> _updateStatistics(DateTime startTime) async {
    final totalEntries = _getTotalEntries();
    final totalTerms = _inverseIndex.length;
    final buildTime = DateTime.now().difference(startTime);
    
    _statistics = IndexStatistics(
      totalEntries: totalEntries,
      totalTerms: totalTerms,
      averageTermsPerEntry: totalEntries > 0 ? totalTerms / totalEntries : 0.0,
      indexSize: 0, // 需要计算实际大小
      lastUpdateTime: DateTime.now(),
      buildTime: buildTime,
    );
  }
}
