/*
---------------------------------------------------------------
File name:          registry_index.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        注册表索引系统 (Registry Index System)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:math';
import 'package:ming_status_cli/src/core/registry/metadata_standard.dart';

/// 搜索结果项
class SearchResultItem {
  const SearchResultItem({
    required this.metadata,
    required this.relevanceScore,
    required this.matchedFields,
    required this.highlights,
  });

  /// 模板元数据
  final TemplateMetadataV2 metadata;

  /// 相关性评分 (0.0 - 1.0)
  final double relevanceScore;

  /// 匹配的字段
  final List<String> matchedFields;

  /// 高亮片段
  final Map<String, String> highlights;
}

/// 搜索结果
class SearchResult {
  const SearchResult({
    required this.items,
    required this.totalCount,
    required this.searchTime,
    required this.suggestions,
    required this.facets,
  });

  /// 结果项列表
  final List<SearchResultItem> items;

  /// 总数量
  final int totalCount;

  /// 搜索时间 (毫秒)
  final int searchTime;

  /// 建议的搜索词
  final List<String> suggestions;

  /// 分面统计
  final Map<String, Map<String, int>> facets;
}

/// 搜索查询
class SearchQuery {
  const SearchQuery({
    this.text,
    this.tags,
    this.author,
    this.complexities,
    this.maturities,
    this.platforms,
    this.licenses,
    this.createdRange,
    this.updatedRange,
    this.sortBy = 'relevance',
    this.ascending = false,
    this.offset = 0,
    this.limit = 20,
  });

  /// 搜索文本
  final String? text;

  /// 标签过滤
  final List<String>? tags;

  /// 作者过滤
  final String? author;

  /// 复杂度过滤
  final List<TemplateComplexity>? complexities;

  /// 成熟度过滤
  final List<TemplateMaturity>? maturities;

  /// 平台过滤
  final List<String>? platforms;

  /// 许可证过滤
  final List<String>? licenses;

  /// 创建时间范围
  final DateTimeRange? createdRange;

  /// 更新时间范围
  final DateTimeRange? updatedRange;

  /// 排序字段
  final String sortBy;

  /// 排序方向
  final bool ascending;

  /// 分页偏移
  final int offset;

  /// 分页大小
  final int limit;
}

/// 时间范围
class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// 索引条目
class IndexEntry {
  const IndexEntry({
    required this.templateId,
    required this.content,
    required this.fieldWeights,
    required this.termFrequency,
    required this.lastUpdated,
  });

  /// 模板ID
  final String templateId;

  /// 索引的文本内容
  final String content;

  /// 字段权重
  final Map<String, double> fieldWeights;

  /// 词频统计
  final Map<String, int> termFrequency;

  /// 最后更新时间
  final DateTime lastUpdated;
}

/// 推荐算法类型
enum RecommendationAlgorithm {
  /// 协同过滤
  collaborative,

  /// 内容推荐
  contentBased,

  /// 混合推荐
  hybrid,
}

/// 注册表索引系统
class RegistryIndex {
  /// 索引数据存储
  final Map<String, TemplateMetadataV2> _templates = {};

  /// 全文索引
  final Map<String, IndexEntry> _textIndex = {};

  /// 标签索引
  final Map<String, Set<String>> _tagIndex = {};

  /// 作者索引
  final Map<String, Set<String>> _authorIndex = {};

  /// 平台索引
  final Map<String, Set<String>> _platformIndex = {};

  /// 搜索历史
  final List<String> _searchHistory = [];

  /// 推荐缓存
  final Map<String, List<String>> _recommendationCache = {};

  /// 添加模板到索引
  Future<void> addTemplate(TemplateMetadataV2 metadata) async {
    _templates[metadata.id] = metadata;

    // 构建全文索引
    await _buildTextIndex(metadata);

    // 构建标签索引
    _buildTagIndex(metadata);

    // 构建作者索引
    _buildAuthorIndex(metadata);

    // 构建平台索引
    _buildPlatformIndex(metadata);

    // 清除相关推荐缓存
    _clearRecommendationCache();
  }

  /// 从索引中移除模板
  Future<void> removeTemplate(String templateId) async {
    final metadata = _templates.remove(templateId);
    if (metadata == null) return;

    // 清理各种索引
    _textIndex.remove(templateId);
    _removeFromTagIndex(metadata);
    _removeFromAuthorIndex(metadata);
    _removeFromPlatformIndex(metadata);

    // 清除推荐缓存
    _clearRecommendationCache();
  }

  /// 更新模板索引
  Future<void> updateTemplate(TemplateMetadataV2 metadata) async {
    await removeTemplate(metadata.id);
    await addTemplate(metadata);
  }

  /// 搜索模板
  Future<SearchResult> search(SearchQuery query) async {
    final startTime = DateTime.now();

    // 获取候选模板
    var candidates = _getCandidates(query);

    // 文本搜索
    if (query.text != null && query.text!.isNotEmpty) {
      candidates = _performTextSearch(query.text!, candidates);
    }

    // 应用过滤器
    candidates = _applyFilters(query, candidates);

    // 计算相关性评分
    final scoredResults = await _calculateRelevanceScores(query, candidates);

    // 排序
    _sortResults(scoredResults, query.sortBy, query.ascending);

    // 分页
    final paginatedResults =
        _paginateResults(scoredResults, query.offset, query.limit);

    // 生成搜索建议
    final suggestions = _generateSuggestions(query.text);

    // 计算分面统计
    final facets = _calculateFacets(candidates);

    final searchTime = DateTime.now().difference(startTime).inMilliseconds;

    // 记录搜索历史
    if (query.text != null && query.text!.isNotEmpty) {
      _recordSearchHistory(query.text!);
    }

    return SearchResult(
      items: paginatedResults,
      totalCount: scoredResults.length,
      searchTime: searchTime,
      suggestions: suggestions,
      facets: facets,
    );
  }

  /// 获取推荐模板
  Future<List<TemplateMetadataV2>> getRecommendations(
    String templateId, {
    RecommendationAlgorithm algorithm = RecommendationAlgorithm.hybrid,
    int limit = 10,
  }) async {
    final cacheKey = '${templateId}_${algorithm.name}_$limit';

    // 检查缓存
    if (_recommendationCache.containsKey(cacheKey)) {
      return _recommendationCache[cacheKey]!
          .map((id) => _templates[id]!)
          .toList();
    }

    final recommendations =
        await _generateRecommendations(templateId, algorithm, limit);

    // 缓存结果
    _recommendationCache[cacheKey] = recommendations;

    return recommendations.map((id) => _templates[id]!).toList();
  }

  /// 获取热门模板
  List<TemplateMetadataV2> getPopularTemplates({int limit = 10}) {
    // 简单实现：按创建时间排序
    final templates = _templates.values.toList();
    templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return templates.take(limit).toList();
  }

  /// 获取最新模板
  List<TemplateMetadataV2> getLatestTemplates({int limit = 10}) {
    final templates = _templates.values.toList();
    templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return templates.take(limit).toList();
  }

  /// 获取索引统计信息
  Map<String, dynamic> getIndexStats() {
    return {
      'totalTemplates': _templates.length,
      'totalTags': _tagIndex.length,
      'totalAuthors': _authorIndex.length,
      'totalPlatforms': _platformIndex.length,
      'indexSize': _textIndex.length,
      'searchHistorySize': _searchHistory.length,
      'recommendationCacheSize': _recommendationCache.length,
    };
  }

  /// 重建索引
  Future<void> rebuildIndex() async {
    _textIndex.clear();
    _tagIndex.clear();
    _authorIndex.clear();
    _platformIndex.clear();
    _recommendationCache.clear();

    for (final metadata in _templates.values) {
      await _buildTextIndex(metadata);
      _buildTagIndex(metadata);
      _buildAuthorIndex(metadata);
      _buildPlatformIndex(metadata);
    }
  }

  /// 构建全文索引
  Future<void> _buildTextIndex(TemplateMetadataV2 metadata) async {
    final content = _extractSearchableContent(metadata);
    final terms = _tokenizeText(content);
    final termFreq = _calculateTermFrequency(terms);

    final entry = IndexEntry(
      templateId: metadata.id,
      content: content,
      fieldWeights: {
        'name': 3.0,
        'description': 2.0,
        'tags': 2.5,
        'keywords': 2.0,
        'author': 1.5,
      },
      termFrequency: termFreq,
      lastUpdated: DateTime.now(),
    );

    _textIndex[metadata.id] = entry;
  }

  /// 提取可搜索内容
  String _extractSearchableContent(TemplateMetadataV2 metadata) {
    final buffer = StringBuffer();
    buffer.write('${metadata.name} ');
    buffer.write('${metadata.description} ');
    buffer.write('${metadata.tags.join(' ')} ');
    buffer.write('${metadata.keywords.join(' ')} ');
    buffer.write('${metadata.author} ');
    return buffer.toString().toLowerCase();
  }

  /// 文本分词
  List<String> _tokenizeText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 2)
        .toList();
  }

  /// 计算词频
  Map<String, int> _calculateTermFrequency(List<String> terms) {
    final freq = <String, int>{};
    for (final term in terms) {
      freq[term] = (freq[term] ?? 0) + 1;
    }
    return freq;
  }

  /// 构建标签索引
  void _buildTagIndex(TemplateMetadataV2 metadata) {
    for (final tag in metadata.tags) {
      _tagIndex
          .putIfAbsent(tag.toLowerCase(), () => <String>{})
          .add(metadata.id);
    }
  }

  /// 构建作者索引
  void _buildAuthorIndex(TemplateMetadataV2 metadata) {
    _authorIndex
        .putIfAbsent(metadata.author.toLowerCase(), () => <String>{})
        .add(metadata.id);
  }

  /// 构建平台索引
  void _buildPlatformIndex(TemplateMetadataV2 metadata) {
    for (final platform in metadata.compatibility.platforms) {
      _platformIndex
          .putIfAbsent(platform.toLowerCase(), () => <String>{})
          .add(metadata.id);
    }
  }

  /// 获取候选模板
  Set<String> _getCandidates(SearchQuery query) {
    Set<String>? candidates;

    // 标签过滤
    if (query.tags != null && query.tags!.isNotEmpty) {
      for (final tag in query.tags!) {
        final tagCandidates = _tagIndex[tag.toLowerCase()] ?? <String>{};
        candidates = candidates?.intersection(tagCandidates) ?? tagCandidates;
      }
    }

    // 作者过滤
    if (query.author != null) {
      final authorCandidates =
          _authorIndex[query.author!.toLowerCase()] ?? <String>{};
      candidates =
          candidates?.intersection(authorCandidates) ?? authorCandidates;
    }

    // 平台过滤
    if (query.platforms != null && query.platforms!.isNotEmpty) {
      final platformCandidates = <String>{};
      for (final platform in query.platforms!) {
        platformCandidates
            .addAll(_platformIndex[platform.toLowerCase()] ?? <String>{});
      }
      candidates =
          candidates?.intersection(platformCandidates) ?? platformCandidates;
    }

    return candidates ?? _templates.keys.toSet();
  }

  /// 执行文本搜索
  Set<String> _performTextSearch(String text, Set<String> candidates) {
    final searchTerms = _tokenizeText(text.toLowerCase());
    final results = <String, double>{};

    for (final templateId in candidates) {
      final entry = _textIndex[templateId];
      if (entry == null) continue;

      var score = 0;
      for (final term in searchTerms) {
        final tf = entry.termFrequency[term] ?? 0;
        if (tf > 0) {
          // 简单的TF-IDF评分
          final idf = log(_templates.length / _getDocumentFrequency(term));
          score += (tf * idf).toInt();
        }
      }

      if (score > 0) {
        results[templateId] = score.toDouble();
      }
    }

    return results.keys.toSet();
  }

  /// 获取文档频率
  int _getDocumentFrequency(String term) {
    var count = 0;
    for (final entry in _textIndex.values) {
      if (entry.termFrequency.containsKey(term)) {
        count++;
      }
    }
    return max(1, count);
  }

  /// 应用过滤器
  Set<String> _applyFilters(SearchQuery query, Set<String> candidates) {
    return candidates.where((templateId) {
      final metadata = _templates[templateId];
      if (metadata == null) return false;

      // 复杂度过滤
      if (query.complexities != null &&
          !query.complexities!.contains(metadata.complexity)) {
        return false;
      }

      // 成熟度过滤
      if (query.maturities != null &&
          !query.maturities!.contains(metadata.maturity)) {
        return false;
      }

      // 许可证过滤
      if (query.licenses != null &&
          !query.licenses!.contains(metadata.license.spdxId)) {
        return false;
      }

      // 时间范围过滤
      if (query.createdRange != null) {
        if (metadata.createdAt.isBefore(query.createdRange!.start) ||
            metadata.createdAt.isAfter(query.createdRange!.end)) {
          return false;
        }
      }

      if (query.updatedRange != null) {
        if (metadata.updatedAt.isBefore(query.updatedRange!.start) ||
            metadata.updatedAt.isAfter(query.updatedRange!.end)) {
          return false;
        }
      }

      return true;
    }).toSet();
  }

  /// 计算相关性评分
  Future<List<SearchResultItem>> _calculateRelevanceScores(
    SearchQuery query,
    Set<String> candidates,
  ) async {
    final results = <SearchResultItem>[];

    for (final templateId in candidates) {
      final metadata = _templates[templateId];
      if (metadata == null) continue;

      var score = 1.0;
      final matchedFields = <String>[];
      final highlights = <String, String>{};

      // 文本匹配评分
      if (query.text != null && query.text!.isNotEmpty) {
        final textScore = _calculateTextScore(query.text!, metadata);
        score = score * textScore;
        if (textScore > 0.1) {
          matchedFields.add('text');
          highlights['description'] =
              _generateHighlight(metadata.description, query.text!);
        }
      }

      // 标签匹配评分
      if (query.tags != null) {
        final tagScore = _calculateTagScore(query.tags!, metadata.tags);
        score = score * (1.0 + tagScore);
        if (tagScore > 0) {
          matchedFields.add('tags');
        }
      }

      results.add(
        SearchResultItem(
          metadata: metadata,
          relevanceScore: score,
          matchedFields: matchedFields,
          highlights: highlights,
        ),
      );
    }

    return results;
  }

  /// 计算文本评分
  double _calculateTextScore(String query, TemplateMetadataV2 metadata) {
    final queryTerms = _tokenizeText(query.toLowerCase());
    final entry = _textIndex[metadata.id];
    if (entry == null) return 0;

    var score = 0;
    for (final term in queryTerms) {
      final tf = entry.termFrequency[term] ?? 0;
      if (tf > 0) {
        score += tf;
      }
    }

    return score / queryTerms.length;
  }

  /// 计算标签评分
  double _calculateTagScore(List<String> queryTags, List<String> templateTags) {
    final querySet = queryTags.map((t) => t.toLowerCase()).toSet();
    final templateSet = templateTags.map((t) => t.toLowerCase()).toSet();
    final intersection = querySet.intersection(templateSet);

    return intersection.length / queryTags.length;
  }

  /// 生成高亮片段
  String _generateHighlight(String text, String query) {
    // 简单实现：返回包含查询词的片段
    final queryTerms = _tokenizeText(query.toLowerCase());
    for (final term in queryTerms) {
      final index = text.toLowerCase().indexOf(term);
      if (index != -1) {
        final start = max(0, index - 50);
        final end = min(text.length, index + term.length + 50);
        return '...${text.substring(start, end)}...';
      }
    }
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  /// 排序结果
  void _sortResults(
    List<SearchResultItem> results,
    String sortBy,
    bool ascending,
  ) {
    results.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'relevance':
          comparison = b.relevanceScore.compareTo(a.relevanceScore);
        case 'name':
          comparison = a.metadata.name.compareTo(b.metadata.name);
        case 'created':
          comparison = a.metadata.createdAt.compareTo(b.metadata.createdAt);
        case 'updated':
          comparison = a.metadata.updatedAt.compareTo(b.metadata.updatedAt);
        default:
          comparison = b.relevanceScore.compareTo(a.relevanceScore);
      }
      return ascending ? comparison : -comparison;
    });
  }

  /// 分页结果
  List<SearchResultItem> _paginateResults(
    List<SearchResultItem> results,
    int offset,
    int limit,
  ) {
    final start = min(offset, results.length);
    final end = min(offset + limit, results.length);
    return results.sublist(start, end);
  }

  /// 生成搜索建议
  List<String> _generateSuggestions(String? query) {
    if (query == null || query.isEmpty) return [];

    // 简单实现：基于搜索历史生成建议
    final suggestions = <String>[];
    final queryLower = query.toLowerCase();

    for (final historyItem in _searchHistory.reversed) {
      if (historyItem.toLowerCase().contains(queryLower) &&
          historyItem != query &&
          suggestions.length < 5) {
        suggestions.add(historyItem);
      }
    }

    return suggestions;
  }

  /// 计算分面统计
  Map<String, Map<String, int>> _calculateFacets(Set<String> candidates) {
    final facets = <String, Map<String, int>>{
      'complexity': <String, int>{},
      'maturity': <String, int>{},
      'platforms': <String, int>{},
      'licenses': <String, int>{},
    };

    for (final templateId in candidates) {
      final metadata = _templates[templateId];
      if (metadata == null) continue;

      // 复杂度分面
      final complexity = metadata.complexity.name;
      facets['complexity']![complexity] =
          (facets['complexity']![complexity] ?? 0) + 1;

      // 成熟度分面
      final maturity = metadata.maturity.name;
      facets['maturity']![maturity] = (facets['maturity']![maturity] ?? 0) + 1;

      // 平台分面
      for (final platform in metadata.compatibility.platforms) {
        facets['platforms']![platform] =
            (facets['platforms']![platform] ?? 0) + 1;
      }

      // 许可证分面
      final license = metadata.license.spdxId;
      facets['licenses']![license] = (facets['licenses']![license] ?? 0) + 1;
    }

    return facets;
  }

  /// 记录搜索历史
  void _recordSearchHistory(String query) {
    _searchHistory.add(query);
    if (_searchHistory.length > 100) {
      _searchHistory.removeAt(0);
    }
  }

  /// 生成推荐
  Future<List<String>> _generateRecommendations(
    String templateId,
    RecommendationAlgorithm algorithm,
    int limit,
  ) async {
    final template = _templates[templateId];
    if (template == null) return [];

    switch (algorithm) {
      case RecommendationAlgorithm.contentBased:
        return _generateContentBasedRecommendations(template, limit);
      case RecommendationAlgorithm.collaborative:
        return _generateCollaborativeRecommendations(templateId, limit);
      case RecommendationAlgorithm.hybrid:
        final contentBased =
            _generateContentBasedRecommendations(template, limit ~/ 2);
        final collaborative =
            _generateCollaborativeRecommendations(templateId, limit ~/ 2);
        return [...contentBased, ...collaborative].take(limit).toList();
    }
  }

  /// 基于内容的推荐
  List<String> _generateContentBasedRecommendations(
    TemplateMetadataV2 template,
    int limit,
  ) {
    final scores = <String, double>{};

    for (final candidate in _templates.values) {
      if (candidate.id == template.id) continue;

      var score = 0.0;

      // 标签相似度
      final tagSimilarity = _calculateTagScore(template.tags, candidate.tags);
      score += tagSimilarity * 0.4;

      // 复杂度相似度
      if (template.complexity == candidate.complexity) {
        score += 0.2;
      }

      // 平台相似度
      final platformSimilarity = _calculateTagScore(
        template.compatibility.platforms,
        candidate.compatibility.platforms,
      );
      score += platformSimilarity * 0.3;

      // 作者相似度
      if (template.author == candidate.author) {
        score += 0.1;
      }

      if (score > 0.1) {
        scores[candidate.id] = score;
      }
    }

    final sortedIds = scores.keys.toList();
    sortedIds.sort((a, b) => scores[b]!.compareTo(scores[a]!));

    return sortedIds.take(limit).toList();
  }

  /// 协同过滤推荐
  List<String> _generateCollaborativeRecommendations(
    String templateId,
    int limit,
  ) {
    // 简单实现：基于相似用户的行为
    // 这里需要用户行为数据，暂时返回随机推荐
    final candidates = _templates.keys.where((id) => id != templateId).toList();
    candidates.shuffle();
    return candidates.take(limit).toList();
  }

  /// 清除推荐缓存
  void _clearRecommendationCache() {
    _recommendationCache.clear();
  }

  /// 从标签索引中移除
  void _removeFromTagIndex(TemplateMetadataV2 metadata) {
    for (final tag in metadata.tags) {
      _tagIndex[tag.toLowerCase()]?.remove(metadata.id);
      if (_tagIndex[tag.toLowerCase()]?.isEmpty == true) {
        _tagIndex.remove(tag.toLowerCase());
      }
    }
  }

  /// 从作者索引中移除
  void _removeFromAuthorIndex(TemplateMetadataV2 metadata) {
    _authorIndex[metadata.author.toLowerCase()]?.remove(metadata.id);
    if (_authorIndex[metadata.author.toLowerCase()]?.isEmpty == true) {
      _authorIndex.remove(metadata.author.toLowerCase());
    }
  }

  /// 从平台索引中移除
  void _removeFromPlatformIndex(TemplateMetadataV2 metadata) {
    for (final platform in metadata.compatibility.platforms) {
      _platformIndex[platform.toLowerCase()]?.remove(metadata.id);
      if (_platformIndex[platform.toLowerCase()]?.isEmpty == true) {
        _platformIndex.remove(platform.toLowerCase());
      }
    }
  }
}
