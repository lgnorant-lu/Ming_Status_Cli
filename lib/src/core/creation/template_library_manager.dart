/*
---------------------------------------------------------------
File name:          template_library_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板库管理器 (Enterprise Template Library Manager)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板创建工具;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板来源类型
enum TemplateSourceType {
  /// 本地文件系统
  local,

  /// Git仓库
  git,

  /// HTTP/HTTPS URL
  http,

  /// 企业内部仓库
  enterprise,

  /// 公共模板库
  public,
}

/// 模板版本信息
class TemplateVersion {
  /// 创建模板版本信息实例
  const TemplateVersion({
    required this.version,
    required this.releaseDate,
    this.changelog,
    this.downloadUrl,
    this.checksum,
    this.isStable = true,
    this.metadata = const {},
  });

  /// 版本号
  final String version;

  /// 发布日期
  final DateTime releaseDate;

  /// 更新日志
  final String? changelog;

  /// 下载URL
  final String? downloadUrl;

  /// 校验和
  final String? checksum;

  /// 是否稳定版本
  final bool isStable;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 模板库条目
class TemplateLibraryEntry {
  /// 创建模板库条目实例
  const TemplateLibraryEntry({
    required this.id,
    required this.name,
    required this.sourceType,
    required this.sourceUrl,
    this.description,
    this.author,
    this.category,
    this.tags = const [],
    this.versions = const [],
    this.currentVersion,
    this.downloadCount = 0,
    this.rating = 0.0,
    this.lastUpdated,
    this.metadata = const {},
  });

  /// 模板ID
  final String id;

  /// 模板名称
  final String name;

  /// 来源类型
  final TemplateSourceType sourceType;

  /// 来源URL
  final String sourceUrl;

  /// 模板描述
  final String? description;

  /// 作者
  final String? author;

  /// 分类
  final String? category;

  /// 标签
  final List<String> tags;

  /// 版本列表
  final List<TemplateVersion> versions;

  /// 当前版本
  final String? currentVersion;

  /// 下载次数
  final int downloadCount;

  /// 评分 (0.0-5.0)
  final double rating;

  /// 最后更新时间
  final DateTime? lastUpdated;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 获取最新版本
  TemplateVersion? get latestVersion {
    if (versions.isEmpty) return null;

    final stableVersions = versions.where((v) => v.isStable).toList();
    if (stableVersions.isNotEmpty) {
      stableVersions.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      return stableVersions.first;
    }

    final sortedVersions = versions.toList();
    sortedVersions.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return sortedVersions.first;
  }

  /// 获取指定版本
  TemplateVersion? getVersion(String version) {
    return versions.firstWhere(
      (v) => v.version == version,
      orElse: () => throw ArgumentError('版本不存在: $version'),
    );
  }
}

/// 模板库查询条件
class TemplateLibraryQuery {
  /// 创建模板库查询条件实例
  const TemplateLibraryQuery({
    this.category,
    this.tags = const [],
    this.author,
    this.namePattern,
    this.sourceType,
    this.minRating,
    this.sortBy = TemplateSortBy.popularity,
    this.sortOrder = SortOrder.descending,
    this.limit,
    this.offset = 0,
  });

  /// 分类过滤
  final String? category;

  /// 标签过滤
  final List<String> tags;

  /// 作者过滤
  final String? author;

  /// 名称模式匹配
  final String? namePattern;

  /// 来源类型过滤
  final TemplateSourceType? sourceType;

  /// 最小评分
  final double? minRating;

  /// 排序方式
  final TemplateSortBy sortBy;

  /// 排序顺序
  final SortOrder sortOrder;

  /// 结果限制数量
  final int? limit;

  /// 结果偏移量
  final int offset;
}

/// 模板排序方式
enum TemplateSortBy {
  /// 名称
  name,

  /// 创建时间
  createdAt,

  /// 更新时间
  updatedAt,

  /// 下载次数
  downloadCount,

  /// 评分
  rating,

  /// 流行度
  popularity,
}

/// 排序顺序
enum SortOrder {
  /// 升序
  ascending,

  /// 降序
  descending,
}

/// 模板下载结果
class TemplateDownloadResult {
  /// 创建模板下载结果实例
  const TemplateDownloadResult({
    required this.success,
    required this.localPath,
    this.version,
    this.downloadTime,
    this.fileSize,
    this.error,
  });

  /// 是否成功
  final bool success;

  /// 本地路径
  final String localPath;

  /// 下载的版本
  final String? version;

  /// 下载时间
  final DateTime? downloadTime;

  /// 文件大小 (字节)
  final int? fileSize;

  /// 错误信息
  final String? error;
}

/// 企业级模板库管理器
class TemplateLibraryManager {
  /// 创建模板库管理器实例
  TemplateLibraryManager({
    String? libraryPath,
    this.enableCaching = true,
    this.cacheTimeout = const Duration(hours: 1),
    this.maxConcurrentDownloads = 3,
  }) : _libraryPath = libraryPath ?? _getDefaultLibraryPath();

  /// 模板库路径
  final String _libraryPath;

  /// 是否启用缓存
  final bool enableCaching;

  /// 缓存超时时间
  final Duration cacheTimeout;

  /// 最大并发下载数
  final int maxConcurrentDownloads;

  /// 模板库条目缓存
  final Map<String, TemplateLibraryEntry> _libraryCache = {};

  /// 缓存时间
  DateTime? _cacheTime;

  /// 当前下载任务数
  int _activeDownloads = 0;

  /// 初始化模板库
  Future<void> initialize() async {
    try {
      cli_logger.Logger.debug('初始化模板库管理器');

      final libraryDir = Directory(_libraryPath);
      if (!await libraryDir.exists()) {
        await libraryDir.create(recursive: true);
      }

      // 加载本地模板库索引
      await _loadLocalLibrary();

      cli_logger.Logger.info('模板库管理器初始化完成');
    } catch (e) {
      cli_logger.Logger.error('模板库管理器初始化失败', error: e);
      rethrow;
    }
  }

  /// 搜索模板
  Future<List<TemplateLibraryEntry>> searchTemplates(
    TemplateLibraryQuery query,
  ) async {
    try {
      cli_logger.Logger.debug('搜索模板: ${query.namePattern ?? 'all'}');

      // 确保缓存有效
      await _ensureCacheValid();

      var results = _libraryCache.values.toList();

      // 应用过滤条件
      if (query.category != null) {
        results = results.where((t) => t.category == query.category).toList();
      }

      if (query.tags.isNotEmpty) {
        results = results
            .where((t) => query.tags.any((tag) => t.tags.contains(tag)))
            .toList();
      }

      if (query.author != null) {
        results = results.where((t) => t.author == query.author).toList();
      }

      if (query.namePattern != null) {
        final pattern = RegExp(query.namePattern!, caseSensitive: false);
        results = results
            .where((t) =>
                pattern.hasMatch(t.name) ||
                (t.description != null && pattern.hasMatch(t.description!)),)
            .toList();
      }

      if (query.sourceType != null) {
        results =
            results.where((t) => t.sourceType == query.sourceType).toList();
      }

      if (query.minRating != null) {
        results = results.where((t) => t.rating >= query.minRating!).toList();
      }

      // 排序
      _sortResults(results, query.sortBy, query.sortOrder);

      // 分页
      final startIndex = query.offset;
      final endIndex = query.limit != null
          ? (startIndex + query.limit!).clamp(0, results.length)
          : results.length;

      final pagedResults = results.sublist(startIndex, endIndex);

      cli_logger.Logger.info('搜索完成: 找到${pagedResults.length}个模板');
      return pagedResults;
    } catch (e) {
      cli_logger.Logger.error('搜索模板失败', error: e);
      return [];
    }
  }

  /// 获取模板详情
  Future<TemplateLibraryEntry?> getTemplate(String templateId) async {
    await _ensureCacheValid();
    return _libraryCache[templateId];
  }

  /// 下载模板
  Future<TemplateDownloadResult> downloadTemplate({
    required String templateId,
    String? version,
    String? targetPath,
  }) async {
    try {
      // 检查并发下载限制
      if (_activeDownloads >= maxConcurrentDownloads) {
        return const TemplateDownloadResult(
          success: false,
          localPath: '',
          error: '达到最大并发下载数限制',
        );
      }

      _activeDownloads++;

      cli_logger.Logger.debug('开始下载模板: $templateId');

      final template = await getTemplate(templateId);
      if (template == null) {
        return const TemplateDownloadResult(
          success: false,
          localPath: '',
          error: '模板不存在',
        );
      }

      // 确定下载版本
      final targetVersion = version ?? template.latestVersion?.version;
      if (targetVersion == null) {
        return const TemplateDownloadResult(
          success: false,
          localPath: '',
          error: '无可用版本',
        );
      }

      final templateVersion = template.getVersion(targetVersion);
      if (templateVersion == null) {
        return TemplateDownloadResult(
          success: false,
          localPath: '',
          error: '版本不存在: $targetVersion',
        );
      }

      // 确定本地路径
      final localPath =
          targetPath ?? '$_libraryPath/templates/${template.id}/$targetVersion';

      // 执行下载
      final downloadResult = await _performDownload(
        template,
        templateVersion,
        localPath,
      );

      return downloadResult;
    } catch (e) {
      cli_logger.Logger.error('下载模板失败: $templateId', error: e);
      return TemplateDownloadResult(
        success: false,
        localPath: '',
        error: '下载失败: $e',
      );
    } finally {
      _activeDownloads--;
    }
  }

  /// 添加模板到库
  Future<bool> addTemplate(TemplateLibraryEntry template) async {
    try {
      _libraryCache[template.id] = template;
      await _saveLocalLibrary();

      cli_logger.Logger.info('添加模板到库: ${template.name}');
      return true;
    } catch (e) {
      cli_logger.Logger.error('添加模板失败', error: e);
      return false;
    }
  }

  /// 移除模板
  Future<bool> removeTemplate(String templateId) async {
    try {
      _libraryCache.remove(templateId);
      await _saveLocalLibrary();

      // 删除本地文件
      final templateDir = Directory('$_libraryPath/templates/$templateId');
      if (await templateDir.exists()) {
        await templateDir.delete(recursive: true);
      }

      cli_logger.Logger.info('移除模板: $templateId');
      return true;
    } catch (e) {
      cli_logger.Logger.error('移除模板失败', error: e);
      return false;
    }
  }

  /// 更新模板库索引
  Future<void> updateLibraryIndex() async {
    try {
      cli_logger.Logger.debug('更新模板库索引');

      // 这里可以从远程源更新模板库索引
      // 目前只是刷新缓存
      _cacheTime = null;
      await _loadLocalLibrary();

      cli_logger.Logger.info('模板库索引更新完成');
    } catch (e) {
      cli_logger.Logger.error('更新模板库索引失败', error: e);
    }
  }

  /// 获取默认模板库路径
  static String _getDefaultLibraryPath() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$homeDir/.ming/templates';
  }

  /// 确保缓存有效
  Future<void> _ensureCacheValid() async {
    if (!enableCaching) {
      await _loadLocalLibrary();
      return;
    }

    if (_cacheTime == null ||
        DateTime.now().difference(_cacheTime!).compareTo(cacheTimeout) > 0) {
      await _loadLocalLibrary();
    }
  }

  /// 加载本地模板库
  Future<void> _loadLocalLibrary() async {
    try {
      final indexFile = File('$_libraryPath/index.json');
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;

        _libraryCache.clear();

        if (data['templates'] is List) {
          for (final templateData in data['templates'] as List) {
            if (templateData is Map<String, dynamic>) {
              final template = _parseTemplateEntry(templateData);
              _libraryCache[template.id] = template;
            }
          }
        }
      }

      _cacheTime = DateTime.now();
    } catch (e) {
      cli_logger.Logger.error('加载本地模板库失败', error: e);
    }
  }

  /// 保存本地模板库
  Future<void> _saveLocalLibrary() async {
    try {
      final indexFile = File('$_libraryPath/index.json');
      final indexDir = Directory(indexFile.parent.path);

      if (!await indexDir.exists()) {
        await indexDir.create(recursive: true);
      }

      final data = {
        'version': '1.0.0',
        'updated_at': DateTime.now().toIso8601String(),
        'templates': _libraryCache.values
            .map(_serializeTemplateEntry)
            .toList(),
      };

      final json = jsonEncode(data);
      await indexFile.writeAsString(json);
    } catch (e) {
      cli_logger.Logger.error('保存本地模板库失败', error: e);
    }
  }

  /// 解析模板条目
  TemplateLibraryEntry _parseTemplateEntry(Map<String, dynamic> data) {
    final versions = <TemplateVersion>[];
    if (data['versions'] is List) {
      for (final versionData in data['versions'] as List) {
        if (versionData is Map<String, dynamic>) {
          versions.add(_parseTemplateVersion(versionData));
        }
      }
    }

    return TemplateLibraryEntry(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      sourceType: _parseSourceType(data['source_type']?.toString() ?? 'local'),
      sourceUrl: data['source_url']?.toString() ?? '',
      description: data['description']?.toString(),
      author: data['author']?.toString(),
      category: data['category']?.toString(),
      tags: data['tags'] is List
          ? List<String>.from(data['tags'] as List)
          : const [],
      versions: versions,
      currentVersion: data['current_version']?.toString(),
      downloadCount:
          data['download_count'] is int ? data['download_count'] as int : 0,
      rating: data['rating'] is num ? (data['rating'] as num).toDouble() : 0.0,
      lastUpdated: data['last_updated'] is String
          ? DateTime.tryParse(data['last_updated'] as String)
          : null,
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
    );
  }

  /// 解析模板版本
  TemplateVersion _parseTemplateVersion(Map<String, dynamic> data) {
    return TemplateVersion(
      version: data['version']?.toString() ?? '',
      releaseDate: data['release_date'] is String
          ? DateTime.tryParse(data['release_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      changelog: data['changelog']?.toString(),
      downloadUrl: data['download_url']?.toString(),
      checksum: data['checksum']?.toString(),
      isStable: data['is_stable'] == true,
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : const {},
    );
  }

  /// 解析来源类型
  TemplateSourceType _parseSourceType(String sourceType) {
    switch (sourceType.toLowerCase()) {
      case 'git':
        return TemplateSourceType.git;
      case 'http':
      case 'https':
        return TemplateSourceType.http;
      case 'enterprise':
        return TemplateSourceType.enterprise;
      case 'public':
        return TemplateSourceType.public;
      case 'local':
      default:
        return TemplateSourceType.local;
    }
  }

  /// 序列化模板条目
  Map<String, dynamic> _serializeTemplateEntry(TemplateLibraryEntry template) {
    return {
      'id': template.id,
      'name': template.name,
      'source_type': template.sourceType.name,
      'source_url': template.sourceUrl,
      if (template.description != null) 'description': template.description,
      if (template.author != null) 'author': template.author,
      if (template.category != null) 'category': template.category,
      if (template.tags.isNotEmpty) 'tags': template.tags,
      'versions':
          template.versions.map(_serializeTemplateVersion).toList(),
      if (template.currentVersion != null)
        'current_version': template.currentVersion,
      'download_count': template.downloadCount,
      'rating': template.rating,
      if (template.lastUpdated != null)
        'last_updated': template.lastUpdated!.toIso8601String(),
      if (template.metadata.isNotEmpty) 'metadata': template.metadata,
    };
  }

  /// 序列化模板版本
  Map<String, dynamic> _serializeTemplateVersion(TemplateVersion version) {
    return {
      'version': version.version,
      'release_date': version.releaseDate.toIso8601String(),
      if (version.changelog != null) 'changelog': version.changelog,
      if (version.downloadUrl != null) 'download_url': version.downloadUrl,
      if (version.checksum != null) 'checksum': version.checksum,
      'is_stable': version.isStable,
      if (version.metadata.isNotEmpty) 'metadata': version.metadata,
    };
  }

  /// 排序结果
  void _sortResults(
    List<TemplateLibraryEntry> results,
    TemplateSortBy sortBy,
    SortOrder sortOrder,
  ) {
    results.sort((a, b) {
      var comparison = 0;

      switch (sortBy) {
        case TemplateSortBy.name:
          comparison = a.name.compareTo(b.name);
        case TemplateSortBy.downloadCount:
          comparison = a.downloadCount.compareTo(b.downloadCount);
        case TemplateSortBy.rating:
          comparison = a.rating.compareTo(b.rating);
        case TemplateSortBy.updatedAt:
          final aTime = a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aTime.compareTo(bTime);
        case TemplateSortBy.popularity:
          // 综合评分：下载次数 * 评分
          final aScore = a.downloadCount * a.rating;
          final bScore = b.downloadCount * b.rating;
          comparison = aScore.compareTo(bScore);
        case TemplateSortBy.createdAt:
          // 使用第一个版本的发布时间作为创建时间
          final aTime = a.versions.isNotEmpty
              ? a.versions.first.releaseDate
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.versions.isNotEmpty
              ? b.versions.first.releaseDate
              : DateTime.fromMillisecondsSinceEpoch(0);
          comparison = aTime.compareTo(bTime);
      }

      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
  }

  /// 执行下载
  Future<TemplateDownloadResult> _performDownload(
    TemplateLibraryEntry template,
    TemplateVersion version,
    String localPath,
  ) async {
    final startTime = DateTime.now();

    try {
      switch (template.sourceType) {
        case TemplateSourceType.local:
          return await _downloadFromLocal(template, version, localPath);
        case TemplateSourceType.git:
          return await _downloadFromGit(template, version, localPath);
        case TemplateSourceType.http:
          return await _downloadFromHttp(template, version, localPath);
        case TemplateSourceType.enterprise:
        case TemplateSourceType.public:
          return await _downloadFromRemote(template, version, localPath);
      }
    } catch (e) {
      return TemplateDownloadResult(
        success: false,
        localPath: localPath,
        version: version.version,
        downloadTime: startTime,
        error: '下载失败: $e',
      );
    }
  }

  /// 从本地下载
  Future<TemplateDownloadResult> _downloadFromLocal(
    TemplateLibraryEntry template,
    TemplateVersion version,
    String localPath,
  ) async {
    // 本地模板直接复制
    final sourceDir = Directory(template.sourceUrl);
    final targetDir = Directory(localPath);

    if (!await sourceDir.exists()) {
      return TemplateDownloadResult(
        success: false,
        localPath: localPath,
        version: version.version,
        error: '源目录不存在: ${template.sourceUrl}',
      );
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 复制文件
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path
            .replaceFirst(template.sourceUrl, '')
            .replaceFirst(RegExp(r'^[/\\]'), '');
        final targetFile = File('$localPath/$relativePath');
        final targetFileDir = Directory(targetFile.parent.path);

        if (!await targetFileDir.exists()) {
          await targetFileDir.create(recursive: true);
        }

        await entity.copy(targetFile.path);
      }
    }

    return TemplateDownloadResult(
      success: true,
      localPath: localPath,
      version: version.version,
      downloadTime: DateTime.now(),
    );
  }

  /// 从Git下载
  Future<TemplateDownloadResult> _downloadFromGit(
    TemplateLibraryEntry template,
    TemplateVersion version,
    String localPath,
  ) async {
    // 使用git clone下载
    final result = await Process.run(
      'git',
      [
        'clone',
        '--depth',
        '1',
        '--branch',
        version.version,
        template.sourceUrl,
        localPath,
      ],
    );

    if (result.exitCode == 0) {
      return TemplateDownloadResult(
        success: true,
        localPath: localPath,
        version: version.version,
        downloadTime: DateTime.now(),
      );
    } else {
      return TemplateDownloadResult(
        success: false,
        localPath: localPath,
        version: version.version,
        error: 'Git clone失败: ${result.stderr}',
      );
    }
  }

  /// 从HTTP下载
  Future<TemplateDownloadResult> _downloadFromHttp(
    TemplateLibraryEntry template,
    TemplateVersion version,
    String localPath,
  ) async {
    // HTTP下载实现
    // 这里提供基础框架
    return TemplateDownloadResult(
      success: false,
      localPath: localPath,
      version: version.version,
      error: 'HTTP下载暂未实现',
    );
  }

  /// 从远程下载
  Future<TemplateDownloadResult> _downloadFromRemote(
    TemplateLibraryEntry template,
    TemplateVersion version,
    String localPath,
  ) async {
    // 远程下载实现
    // 这里提供基础框架
    return TemplateDownloadResult(
      success: false,
      localPath: localPath,
      version: version.version,
      error: '远程下载暂未实现',
    );
  }
}
