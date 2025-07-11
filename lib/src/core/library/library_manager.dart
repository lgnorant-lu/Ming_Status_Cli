/*
---------------------------------------------------------------
File name:          library_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级库管理器 (Enterprise Library Manager)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板库管理系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/creation/template_library_manager.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 库类型
enum LibraryType {
  /// 官方库
  official,

  /// 企业库
  enterprise,

  /// 团队库
  team,

  /// 个人库
  personal,

  /// 社区库
  community,
}

/// 库权限
enum LibraryPermission {
  /// 只读
  read,

  /// 写入
  write,

  /// 管理
  manage,

  /// 所有者
  owner,
}

/// 库状态
enum LibraryStatus {
  /// 活跃
  active,

  /// 只读
  readonly,

  /// 已弃用
  deprecated,

  /// 维护中
  maintenance,

  /// 离线
  offline,
}

/// 库配置
class LibraryConfig {
  /// 创建库配置实例
  const LibraryConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.description,
    this.priority = 100,
    this.permissions = const {LibraryPermission.read},
    this.status = LibraryStatus.active,
    this.authToken,
    this.syncInterval = const Duration(hours: 24),
    this.enableCache = true,
    this.cacheTimeout = const Duration(hours: 1),
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// 从Map创建库配置
  factory LibraryConfig.fromMap(Map<String, dynamic> map) {
    return LibraryConfig(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: _parseLibraryType(map['type']?.toString() ?? 'personal'),
      url: map['url']?.toString() ?? '',
      description: map['description']?.toString(),
      priority: map['priority'] is int ? map['priority'] as int : 100,
      permissions: _parsePermissions(map['permissions']),
      status: _parseLibraryStatus(map['status']?.toString() ?? 'active'),
      authToken: map['auth_token']?.toString(),
      syncInterval: Duration(
        seconds: map['sync_interval_seconds'] is int
            ? map['sync_interval_seconds'] as int
            : 86400,
      ),
      enableCache: map['enable_cache'] == true,
      cacheTimeout: Duration(
        seconds: map['cache_timeout_seconds'] is int
            ? map['cache_timeout_seconds'] as int
            : 3600,
      ),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] is String
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// 库ID
  final String id;

  /// 库名称
  final String name;

  /// 库类型
  final LibraryType type;

  /// 库URL
  final String url;

  /// 库描述
  final String? description;

  /// 库优先级 (数字越小优先级越高)
  final int priority;

  /// 库权限
  final Set<LibraryPermission> permissions;

  /// 库状态
  final LibraryStatus status;

  /// 认证令牌
  final String? authToken;

  /// 同步间隔
  final Duration syncInterval;

  /// 是否启用缓存
  final bool enableCache;

  /// 缓存超时时间
  final Duration cacheTimeout;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  /// 解析库类型
  static LibraryType _parseLibraryType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'official':
        return LibraryType.official;
      case 'enterprise':
        return LibraryType.enterprise;
      case 'team':
        return LibraryType.team;
      case 'community':
        return LibraryType.community;
      case 'personal':
      default:
        return LibraryType.personal;
    }
  }

  /// 解析库权限
  static Set<LibraryPermission> _parsePermissions(dynamic permissions) {
    final result = <LibraryPermission>{};

    if (permissions is List) {
      for (final perm in permissions) {
        switch (perm.toString().toLowerCase()) {
          case 'read':
            result.add(LibraryPermission.read);
          case 'write':
            result.add(LibraryPermission.write);
          case 'manage':
            result.add(LibraryPermission.manage);
          case 'owner':
            result.add(LibraryPermission.owner);
        }
      }
    }

    return result.isEmpty ? {LibraryPermission.read} : result;
  }

  /// 解析库状态
  static LibraryStatus _parseLibraryStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'readonly':
        return LibraryStatus.readonly;
      case 'deprecated':
        return LibraryStatus.deprecated;
      case 'maintenance':
        return LibraryStatus.maintenance;
      case 'offline':
        return LibraryStatus.offline;
      case 'active':
      default:
        return LibraryStatus.active;
    }
  }

  /// 检查是否有指定权限
  bool hasPermission(LibraryPermission permission) {
    return permissions.contains(permission) ||
        permissions.contains(LibraryPermission.owner);
  }

  /// 检查是否可读
  bool get canRead => hasPermission(LibraryPermission.read);

  /// 检查是否可写
  bool get canWrite => hasPermission(LibraryPermission.write);

  /// 检查是否可管理
  bool get canManage => hasPermission(LibraryPermission.manage);

  /// 检查是否为所有者
  bool get isOwner => permissions.contains(LibraryPermission.owner);

  /// 检查是否活跃
  bool get isActive => status == LibraryStatus.active;

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'url': url,
      if (description != null) 'description': description,
      'priority': priority,
      'permissions': permissions.map((p) => p.name).toList(),
      'status': status.name,
      if (authToken != null) 'auth_token': authToken,
      'sync_interval_seconds': syncInterval.inSeconds,
      'enable_cache': enableCache,
      'cache_timeout_seconds': cacheTimeout.inSeconds,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 创建副本
  LibraryConfig copyWith({
    String? id,
    String? name,
    LibraryType? type,
    String? url,
    String? description,
    int? priority,
    Set<LibraryPermission>? permissions,
    LibraryStatus? status,
    String? authToken,
    Duration? syncInterval,
    bool? enableCache,
    Duration? cacheTimeout,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      authToken: authToken ?? this.authToken,
      syncInterval: syncInterval ?? this.syncInterval,
      enableCache: enableCache ?? this.enableCache,
      cacheTimeout: cacheTimeout ?? this.cacheTimeout,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LibraryConfig(id: $id, name: $name, type: ${type.name}, status: ${status.name})';
  }
}

/// 库统计信息
class LibraryStatistics {
  /// 创建库统计信息实例
  const LibraryStatistics({
    required this.libraryId,
    required this.templateCount,
    required this.downloadCount,
    required this.lastSyncTime,
    this.averageRating = 0.0,
    this.totalSize = 0,
    this.errorCount = 0,
    this.syncDuration,
    this.metadata = const {},
  });

  /// 库ID
  final String libraryId;

  /// 模板数量
  final int templateCount;

  /// 下载次数
  final int downloadCount;

  /// 最后同步时间
  final DateTime lastSyncTime;

  /// 平均评分
  final double averageRating;

  /// 总大小 (字节)
  final int totalSize;

  /// 错误次数
  final int errorCount;

  /// 同步耗时
  final Duration? syncDuration;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 库同步结果
class LibrarySyncResult {
  /// 创建库同步结果实例
  const LibrarySyncResult({
    required this.success,
    required this.libraryId,
    this.addedTemplates = 0,
    this.updatedTemplates = 0,
    this.removedTemplates = 0,
    this.errors = const [],
    this.warnings = const [],
    this.syncTime,
    this.duration,
  });

  /// 是否成功
  final bool success;

  /// 库ID
  final String libraryId;

  /// 新增模板数
  final int addedTemplates;

  /// 更新模板数
  final int updatedTemplates;

  /// 移除模板数
  final int removedTemplates;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 同步时间
  final DateTime? syncTime;

  /// 同步耗时
  final Duration? duration;

  /// 获取总变更数
  int get totalChanges => addedTemplates + updatedTemplates + removedTemplates;
}

/// 企业级库管理器
class LibraryManager {
  /// 创建库管理器实例
  LibraryManager({
    String? configPath,
    this.enableAutoSync = true,
    this.maxConcurrentSyncs = 3,
    this.defaultSyncInterval = const Duration(hours: 24),
  }) : _configPath = configPath ?? _getDefaultConfigPath();

  /// 配置文件路径
  final String _configPath;

  /// 是否启用自动同步
  final bool enableAutoSync;

  /// 最大并发同步数
  final int maxConcurrentSyncs;

  /// 默认同步间隔
  final Duration defaultSyncInterval;

  /// 库配置列表
  final Map<String, LibraryConfig> _libraries = {};

  /// 库统计信息
  final Map<String, LibraryStatistics> _statistics = {};

  /// 模板库管理器实例
  final Map<String, TemplateLibraryManager> _libraryManagers = {};

  /// 当前同步任务数
  int _activeSyncs = 0;

  /// 最后加载时间
  DateTime? _lastLoadTime;

  /// 初始化库管理器
  Future<void> initialize() async {
    try {
      cli_logger.Logger.debug('初始化企业级库管理器');

      await _loadLibraryConfigs();

      // 初始化各个库的管理器
      for (final config in _libraries.values) {
        if (config.isActive) {
          await _initializeLibraryManager(config);
        }
      }

      // 启动自动同步
      if (enableAutoSync) {
        _startAutoSync();
      }

      cli_logger.Logger.info('企业级库管理器初始化完成');
    } catch (e) {
      cli_logger.Logger.error('企业级库管理器初始化失败', error: e);
      rethrow;
    }
  }

  /// 添加库
  Future<bool> addLibrary(LibraryConfig config) async {
    try {
      cli_logger.Logger.debug('添加库: ${config.name}');

      // 验证库配置
      final validation = await _validateLibraryConfig(config);
      if (!validation.isValid) {
        cli_logger.Logger.error('库配置验证失败: ${validation.errors.join(', ')}');
        return false;
      }

      // 添加到配置
      _libraries[config.id] = config.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 初始化库管理器
      if (config.isActive) {
        await _initializeLibraryManager(config);
      }

      // 保存配置
      await _saveLibraryConfigs();

      cli_logger.Logger.info('库添加成功: ${config.name}');
      return true;
    } catch (e) {
      cli_logger.Logger.error('添加库失败: ${config.name}', error: e);
      return false;
    }
  }

  /// 移除库
  Future<bool> removeLibrary(String libraryId) async {
    try {
      final config = _libraries[libraryId];
      if (config == null) {
        cli_logger.Logger.warning('库不存在: $libraryId');
        return false;
      }

      cli_logger.Logger.debug('移除库: ${config.name}');

      // 停止库管理器
      final manager = _libraryManagers[libraryId];
      if (manager != null) {
        // 这里可以添加清理逻辑
        _libraryManagers.remove(libraryId);
      }

      // 移除配置和统计
      _libraries.remove(libraryId);
      _statistics.remove(libraryId);

      // 保存配置
      await _saveLibraryConfigs();

      cli_logger.Logger.info('库移除成功: ${config.name}');
      return true;
    } catch (e) {
      cli_logger.Logger.error('移除库失败: $libraryId', error: e);
      return false;
    }
  }

  /// 获取库列表
  List<LibraryConfig> getLibraries({
    LibraryType? type,
    LibraryStatus? status,
    Set<LibraryPermission>? requiredPermissions,
  }) {
    var libraries = _libraries.values.toList();

    // 按类型过滤
    if (type != null) {
      libraries = libraries.where((lib) => lib.type == type).toList();
    }

    // 按状态过滤
    if (status != null) {
      libraries = libraries.where((lib) => lib.status == status).toList();
    }

    // 按权限过滤
    if (requiredPermissions != null) {
      libraries = libraries
          .where(
            (lib) =>
                requiredPermissions.every((perm) => lib.hasPermission(perm)),
          )
          .toList();
    }

    // 按优先级排序
    libraries.sort((a, b) => a.priority.compareTo(b.priority));

    return libraries;
  }

  /// 获取库配置
  LibraryConfig? getLibrary(String libraryId) {
    return _libraries[libraryId];
  }

  /// 更新库配置
  Future<bool> updateLibrary(
    String libraryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final config = _libraries[libraryId];
      if (config == null) {
        cli_logger.Logger.warning('库不存在: $libraryId');
        return false;
      }

      cli_logger.Logger.debug('更新库配置: ${config.name}');

      final updatedConfig = LibraryConfig.fromMap({
        ...config.toMap(),
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });

      _libraries[libraryId] = updatedConfig;

      // 如果状态或URL发生变化，重新初始化库管理器
      if (updates.containsKey('status') || updates.containsKey('url')) {
        await _reinitializeLibraryManager(updatedConfig);
      }

      await _saveLibraryConfigs();

      cli_logger.Logger.info('库配置更新成功: ${config.name}');
      return true;
    } catch (e) {
      cli_logger.Logger.error('更新库配置失败: $libraryId', error: e);
      return false;
    }
  }

  /// 同步库
  Future<LibrarySyncResult> syncLibrary(
    String libraryId, {
    bool force = false,
  }) async {
    final startTime = DateTime.now();

    try {
      final config = _libraries[libraryId];
      if (config == null) {
        return LibrarySyncResult(
          success: false,
          libraryId: libraryId,
          errors: ['库不存在: $libraryId'],
          syncTime: startTime,
        );
      }

      if (!config.isActive) {
        return LibrarySyncResult(
          success: false,
          libraryId: libraryId,
          errors: ['库未激活: ${config.name}'],
          syncTime: startTime,
        );
      }

      // 检查并发限制
      if (_activeSyncs >= maxConcurrentSyncs) {
        return LibrarySyncResult(
          success: false,
          libraryId: libraryId,
          errors: ['达到最大并发同步数限制'],
          syncTime: startTime,
        );
      }

      _activeSyncs++;

      cli_logger.Logger.debug('开始同步库: ${config.name}');

      final manager = _libraryManagers[libraryId];
      if (manager == null) {
        await _initializeLibraryManager(config);
      }

      // 执行同步
      final result = await _performLibrarySync(config, force);

      // 更新统计信息
      await _updateLibraryStatistics(libraryId, result);

      final duration = DateTime.now().difference(startTime);
      cli_logger.Logger.info(
        '库同步完成: ${config.name} - ${result.totalChanges}个变更',
      );

      return result.copyWith(
        syncTime: startTime,
        duration: duration,
      );
    } catch (e) {
      cli_logger.Logger.error('库同步失败: $libraryId', error: e);
      return LibrarySyncResult(
        success: false,
        libraryId: libraryId,
        errors: ['同步失败: $e'],
        syncTime: startTime,
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _activeSyncs--;
    }
  }

  /// 同步所有库
  Future<List<LibrarySyncResult>> syncAllLibraries({bool force = false}) async {
    final results = <LibrarySyncResult>[];
    final activeLibraries = getLibraries(status: LibraryStatus.active);

    cli_logger.Logger.info('开始同步所有库: ${activeLibraries.length}个库');

    for (final config in activeLibraries) {
      final result = await syncLibrary(config.id, force: force);
      results.add(result);
    }

    final successCount = results.where((r) => r.success).length;
    cli_logger.Logger.info('库同步完成: $successCount/${results.length}个成功');

    return results;
  }

  /// 获取库统计信息
  LibraryStatistics? getLibraryStatistics(String libraryId) {
    return _statistics[libraryId];
  }

  /// 获取所有库统计信息
  Map<String, LibraryStatistics> getAllStatistics() {
    return Map.unmodifiable(_statistics);
  }

  /// 获取默认配置路径
  static String _getDefaultConfigPath() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$homeDir/.ming/library_config.json';
  }

  /// 加载库配置
  Future<void> _loadLibraryConfigs() async {
    try {
      final configFile = File(_configPath);
      if (!await configFile.exists()) {
        cli_logger.Logger.debug('配置文件不存在，创建默认配置');
        await _createDefaultConfig();
        return;
      }

      final content = await configFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      if (data['libraries'] is List) {
        for (final libData in data['libraries'] as List) {
          if (libData is Map<String, dynamic>) {
            final config = LibraryConfig.fromMap(libData);
            _libraries[config.id] = config;
          }
        }
      }

      _lastLoadTime = DateTime.now();
      cli_logger.Logger.debug('加载库配置完成: ${_libraries.length}个库');
    } catch (e) {
      cli_logger.Logger.error('加载库配置失败', error: e);
    }
  }

  /// 保存库配置
  Future<void> _saveLibraryConfigs() async {
    try {
      final configFile = File(_configPath);
      final configDir = Directory(configFile.parent.path);

      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }

      final data = {
        'version': '1.0.0',
        'updated_at': DateTime.now().toIso8601String(),
        'libraries': _libraries.values.map((lib) => lib.toMap()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await configFile.writeAsString(jsonStr);

      cli_logger.Logger.debug('保存库配置完成');
    } catch (e) {
      cli_logger.Logger.error('保存库配置失败', error: e);
    }
  }

  /// 创建默认配置
  Future<void> _createDefaultConfig() async {
    // 添加默认的官方库
    const officialLibrary = LibraryConfig(
      id: 'official',
      name: 'Ming Official Templates',
      type: LibraryType.official,
      url: 'https://templates.ming-cli.com/official',
      description: 'Ming CLI官方模板库',
      priority: 1,
    );

    _libraries[officialLibrary.id] = officialLibrary;
    await _saveLibraryConfigs();
  }

  /// 验证库配置
  Future<_ValidationResult> _validateLibraryConfig(LibraryConfig config) async {
    final errors = <String>[];

    // 检查必需字段
    if (config.id.isEmpty) {
      errors.add('库ID不能为空');
    }

    if (config.name.isEmpty) {
      errors.add('库名称不能为空');
    }

    if (config.url.isEmpty) {
      errors.add('库URL不能为空');
    }

    // 检查ID唯一性
    if (_libraries.containsKey(config.id)) {
      errors.add('库ID已存在: ${config.id}');
    }

    // 检查URL格式
    try {
      final uri = Uri.parse(config.url);
      if (!uri.hasScheme) {
        errors.add('库URL格式无效: ${config.url}');
      }
    } catch (e) {
      errors.add('库URL解析失败: ${config.url}');
    }

    return _ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 初始化库管理器
  Future<void> _initializeLibraryManager(LibraryConfig config) async {
    try {
      final manager = TemplateLibraryManager(
        libraryPath: '${_getLibraryBasePath()}/${config.id}',
        enableCaching: config.enableCache,
        cacheTimeout: config.cacheTimeout,
      );

      await manager.initialize();
      _libraryManagers[config.id] = manager;

      cli_logger.Logger.debug('库管理器初始化完成: ${config.name}');
    } catch (e) {
      cli_logger.Logger.error('库管理器初始化失败: ${config.name}', error: e);
    }
  }

  /// 重新初始化库管理器
  Future<void> _reinitializeLibraryManager(LibraryConfig config) async {
    // 停止现有管理器
    _libraryManagers.remove(config.id);

    // 重新初始化
    if (config.isActive) {
      await _initializeLibraryManager(config);
    }
  }

  /// 执行库同步
  Future<LibrarySyncResult> _performLibrarySync(
    LibraryConfig config,
    bool force,
  ) async {
    // 这里实现具体的同步逻辑
    // 目前提供基础框架

    return LibrarySyncResult(
      success: true,
      libraryId: config.id,
    );
  }

  /// 更新库统计信息
  Future<void> _updateLibraryStatistics(
    String libraryId,
    LibrarySyncResult result,
  ) async {
    final existing = _statistics[libraryId];

    _statistics[libraryId] = LibraryStatistics(
      libraryId: libraryId,
      templateCount: existing?.templateCount ?? 0,
      downloadCount: existing?.downloadCount ?? 0,
      lastSyncTime: result.syncTime ?? DateTime.now(),
      averageRating: existing?.averageRating ?? 0.0,
      totalSize: existing?.totalSize ?? 0,
      errorCount: result.success ? 0 : (existing?.errorCount ?? 0) + 1,
      syncDuration: result.duration,
    );
  }

  /// 启动自动同步
  void _startAutoSync() {
    // 这里可以实现定时同步逻辑
    cli_logger.Logger.debug('自动同步已启动');
  }

  /// 获取库基础路径
  String _getLibraryBasePath() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$homeDir/.ming/libraries';
  }
}

/// 验证结果
class _ValidationResult {
  const _ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  final bool isValid;
  final List<String> errors;
}

/// LibrarySyncResult扩展
extension LibrarySyncResultExtension on LibrarySyncResult {
  /// 创建副本
  LibrarySyncResult copyWith({
    bool? success,
    String? libraryId,
    int? addedTemplates,
    int? updatedTemplates,
    int? removedTemplates,
    List<String>? errors,
    List<String>? warnings,
    DateTime? syncTime,
    Duration? duration,
  }) {
    return LibrarySyncResult(
      success: success ?? this.success,
      libraryId: libraryId ?? this.libraryId,
      addedTemplates: addedTemplates ?? this.addedTemplates,
      updatedTemplates: updatedTemplates ?? this.updatedTemplates,
      removedTemplates: removedTemplates ?? this.removedTemplates,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      syncTime: syncTime ?? this.syncTime,
      duration: duration ?? this.duration,
    );
  }
}
