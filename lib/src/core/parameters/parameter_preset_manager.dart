/*
---------------------------------------------------------------
File name:          parameter_preset_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级参数预设管理器 (Enterprise Parameter Preset Manager)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.2 企业级参数化系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 预设类型
enum PresetType {
  /// 团队预设
  team,

  /// 环境预设
  environment,

  /// 项目类型预设
  projectType,

  /// 个人预设
  personal,

  /// 全局预设
  global,
}

/// 预设范围
enum PresetScope {
  /// 用户级别
  user,

  /// 项目级别
  project,

  /// 团队级别
  team,

  /// 组织级别
  organization,

  /// 全局级别
  global,
}

/// 参数预设
class ParameterPreset {
  /// 创建参数预设实例
  const ParameterPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.scope,
    required this.parameters,
    this.description,
    this.version = '1.0.0',
    this.author,
    this.tags = const [],
    this.parentPresetId,
    this.overrides = const {},
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// 从Map创建预设
  factory ParameterPreset.fromMap(Map<String, dynamic> map) {
    return ParameterPreset(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: _parsePresetType(map['type']?.toString() ?? 'personal'),
      scope: _parsePresetScope(map['scope']?.toString() ?? 'user'),
      parameters: map['parameters'] is Map
          ? Map<String, dynamic>.from(map['parameters'] as Map)
          : const {},
      description: map['description']?.toString(),
      version: map['version']?.toString() ?? '1.0.0',
      author: map['author']?.toString(),
      tags: map['tags'] is List
          ? List<String>.from(map['tags'] as List)
          : const [],
      parentPresetId: map['parent_preset_id']?.toString(),
      overrides: map['overrides'] is Map
          ? Map<String, dynamic>.from(map['overrides'] as Map)
          : const {},
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

  /// 预设ID
  final String id;

  /// 预设名称
  final String name;

  /// 预设类型
  final PresetType type;

  /// 预设范围
  final PresetScope scope;

  /// 参数值映射
  final Map<String, dynamic> parameters;

  /// 预设描述
  final String? description;

  /// 预设版本
  final String version;

  /// 创建者
  final String? author;

  /// 标签列表
  final List<String> tags;

  /// 父预设ID (用于继承)
  final String? parentPresetId;

  /// 覆盖参数 (覆盖父预设的参数)
  final Map<String, dynamic> overrides;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  /// 解析预设类型
  static PresetType _parsePresetType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'team':
        return PresetType.team;
      case 'environment':
        return PresetType.environment;
      case 'project_type':
      case 'projecttype':
        return PresetType.projectType;
      case 'global':
        return PresetType.global;
      case 'personal':
      default:
        return PresetType.personal;
    }
  }

  /// 解析预设范围
  static PresetScope _parsePresetScope(String scopeStr) {
    switch (scopeStr.toLowerCase()) {
      case 'project':
        return PresetScope.project;
      case 'team':
        return PresetScope.team;
      case 'organization':
        return PresetScope.organization;
      case 'global':
        return PresetScope.global;
      case 'user':
      default:
        return PresetScope.user;
    }
  }

  /// 获取有效参数值 (合并父预设和覆盖)
  Map<String, dynamic> getEffectiveParameters([ParameterPreset? parentPreset]) {
    final effectiveParams = <String, dynamic>{};

    // 1. 添加父预设参数
    if (parentPreset != null) {
      effectiveParams.addAll(parentPreset.parameters);
    }

    // 2. 添加当前预设参数
    effectiveParams.addAll(parameters);

    // 3. 应用覆盖
    effectiveParams.addAll(overrides);

    return effectiveParams;
  }

  /// 检查是否有父预设
  bool get hasParent => parentPresetId != null;

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'scope': scope.name,
      'parameters': parameters,
      if (description != null) 'description': description,
      'version': version,
      if (author != null) 'author': author,
      if (tags.isNotEmpty) 'tags': tags,
      if (parentPresetId != null) 'parent_preset_id': parentPresetId,
      if (overrides.isNotEmpty) 'overrides': overrides,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// 创建副本
  ParameterPreset copyWith({
    String? id,
    String? name,
    PresetType? type,
    PresetScope? scope,
    Map<String, dynamic>? parameters,
    String? description,
    String? version,
    String? author,
    List<String>? tags,
    String? parentPresetId,
    Map<String, dynamic>? overrides,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParameterPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      parameters: parameters ?? this.parameters,
      description: description ?? this.description,
      version: version ?? this.version,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      parentPresetId: parentPresetId ?? this.parentPresetId,
      overrides: overrides ?? this.overrides,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ParameterPreset(id: $id, name: $name, type: ${type.name}, scope: ${scope.name})';
  }
}

/// 预设查询条件
class PresetQuery {
  /// 创建预设查询条件实例
  const PresetQuery({
    this.type,
    this.scope,
    this.author,
    this.tags = const [],
    this.namePattern,
    this.limit,
    this.offset = 0,
  });

  /// 预设类型过滤
  final PresetType? type;

  /// 预设范围过滤
  final PresetScope? scope;

  /// 作者过滤
  final String? author;

  /// 标签过滤
  final List<String> tags;

  /// 名称模式匹配
  final String? namePattern;

  /// 结果限制数量
  final int? limit;

  /// 结果偏移量
  final int offset;
}

/// 企业级参数预设管理器
class ParameterPresetManager {
  /// 创建参数预设管理器实例
  ParameterPresetManager({
    String? presetDirectory,
    this.enableVersionControl = true,
    this.enableInheritance = true,
    this.maxVersionHistory = 10,
  }) : _presetDirectory = presetDirectory ?? _getDefaultPresetDirectory();

  /// 预设存储目录
  final String _presetDirectory;

  /// 是否启用版本控制
  final bool enableVersionControl;

  /// 是否启用继承
  final bool enableInheritance;

  /// 最大版本历史数量
  final int maxVersionHistory;

  /// 内存中的预设缓存
  final Map<String, ParameterPreset> _presetCache = {};

  /// 预设继承关系缓存
  final Map<String, List<String>> _inheritanceCache = {};

  /// 创建新预设
  Future<ParameterPreset> createPreset({
    required String name,
    required PresetType type,
    required PresetScope scope,
    required Map<String, dynamic> parameters,
    String? description,
    String? author,
    List<String> tags = const [],
    String? parentPresetId,
    Map<String, dynamic> overrides = const {},
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final id = _generatePresetId(name, type, scope);
      final now = DateTime.now();

      final preset = ParameterPreset(
        id: id,
        name: name,
        type: type,
        scope: scope,
        parameters: parameters,
        description: description,
        author: author,
        tags: tags,
        parentPresetId: parentPresetId,
        overrides: overrides,
        metadata: metadata,
        createdAt: now,
        updatedAt: now,
      );

      await _savePreset(preset);
      _presetCache[id] = preset;

      // 更新继承关系缓存
      if (parentPresetId != null) {
        _inheritanceCache.putIfAbsent(parentPresetId, () => []).add(id);
      }

      cli_logger.Logger.info('创建参数预设: $name ($id)');
      return preset;
    } catch (e) {
      cli_logger.Logger.error('创建参数预设失败', error: e);
      rethrow;
    }
  }

  /// 获取预设
  Future<ParameterPreset?> getPreset(String id) async {
    // 先从缓存获取
    if (_presetCache.containsKey(id)) {
      return _presetCache[id];
    }

    // 从文件加载
    try {
      final preset = await _loadPreset(id);
      if (preset != null) {
        _presetCache[id] = preset;
      }
      return preset;
    } catch (e) {
      cli_logger.Logger.error('获取参数预设失败: $id', error: e);
      return null;
    }
  }

  /// 更新预设
  Future<ParameterPreset> updatePreset(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final existingPreset = await getPreset(id);
    if (existingPreset == null) {
      throw ArgumentError('预设不存在: $id');
    }

    try {
      // 创建版本备份
      if (enableVersionControl) {
        await _createVersionBackup(existingPreset);
      }

      final updatedPreset = existingPreset.copyWith(
        name: updates['name']?.toString(),
        description: updates['description']?.toString(),
        parameters: updates['parameters'] is Map
            ? Map<String, dynamic>.from(updates['parameters'] as Map)
            : null,
        tags: updates['tags'] is List
            ? List<String>.from(updates['tags'] as List)
            : null,
        overrides: updates['overrides'] is Map
            ? Map<String, dynamic>.from(updates['overrides'] as Map)
            : null,
        metadata: updates['metadata'] is Map
            ? Map<String, dynamic>.from(updates['metadata'] as Map)
            : null,
        updatedAt: DateTime.now(),
      );

      await _savePreset(updatedPreset);
      _presetCache[id] = updatedPreset;

      cli_logger.Logger.info('更新参数预设: $id');
      return updatedPreset;
    } catch (e) {
      cli_logger.Logger.error('更新参数预设失败: $id', error: e);
      rethrow;
    }
  }

  /// 删除预设
  Future<bool> deletePreset(String id) async {
    try {
      // 检查是否有子预设依赖
      final children = _inheritanceCache[id] ?? [];
      if (children.isNotEmpty) {
        throw Exception('无法删除预设 $id，存在 ${children.length} 个子预设依赖');
      }

      await _deletePresetFile(id);
      _presetCache.remove(id);

      // 清理继承关系缓存
      _inheritanceCache.remove(id);
      for (final entry in _inheritanceCache.entries) {
        entry.value.remove(id);
      }

      cli_logger.Logger.info('删除参数预设: $id');
      return true;
    } catch (e) {
      cli_logger.Logger.error('删除参数预设失败: $id', error: e);
      return false;
    }
  }

  /// 查询预设
  Future<List<ParameterPreset>> queryPresets(PresetQuery query) async {
    try {
      await _loadAllPresets();

      var presets = _presetCache.values.toList();

      // 应用过滤条件
      if (query.type != null) {
        presets = presets.where((p) => p.type == query.type).toList();
      }

      if (query.scope != null) {
        presets = presets.where((p) => p.scope == query.scope).toList();
      }

      if (query.author != null) {
        presets = presets.where((p) => p.author == query.author).toList();
      }

      if (query.tags.isNotEmpty) {
        presets = presets
            .where(
              (p) => query.tags.any((tag) => p.tags.contains(tag)),
            )
            .toList();
      }

      if (query.namePattern != null) {
        final pattern = RegExp(query.namePattern!, caseSensitive: false);
        presets = presets.where((p) => pattern.hasMatch(p.name)).toList();
      }

      // 排序 (按更新时间倒序)
      presets.sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime.now())
            .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()),
      );

      // 应用分页
      final startIndex = query.offset;
      final endIndex = query.limit != null
          ? (startIndex + query.limit!).clamp(0, presets.length)
          : presets.length;

      return presets.sublist(startIndex, endIndex);
    } catch (e) {
      cli_logger.Logger.error('查询参数预设失败', error: e);
      return [];
    }
  }

  /// 应用预设到参数
  Future<Map<String, dynamic>> applyPreset(
    String presetId,
    List<EnterpriseTemplateParameter> parameters, {
    Map<String, dynamic> overrides = const {},
  }) async {
    final preset = await getPreset(presetId);
    if (preset == null) {
      throw ArgumentError('预设不存在: $presetId');
    }

    try {
      // 获取有效参数值 (包括继承)
      var effectiveParams = preset.parameters;

      if (enableInheritance && preset.hasParent) {
        final parentPreset = await getPreset(preset.parentPresetId!);
        effectiveParams = preset.getEffectiveParameters(parentPreset);
      }

      // 应用覆盖
      effectiveParams.addAll(overrides);

      // 过滤只返回存在的参数
      final result = <String, dynamic>{};
      final parameterNames = parameters.map((p) => p.name).toSet();

      for (final entry in effectiveParams.entries) {
        if (parameterNames.contains(entry.key)) {
          result[entry.key] = entry.value;
        }
      }

      cli_logger.Logger.info(
        '应用参数预设: $presetId - 设置了${result.length}个参数',
      );

      return result;
    } catch (e) {
      cli_logger.Logger.error('应用参数预设失败: $presetId', error: e);
      rethrow;
    }
  }

  /// 从模板创建预设
  Future<ParameterPreset> createPresetFromTemplate({
    required String name,
    required PresetType type,
    required PresetScope scope,
    required List<EnterpriseTemplateParameter> parameters,
    required Map<String, dynamic> values,
    String? description,
    String? author,
    List<String> tags = const [],
  }) async {
    // 只保存有值的参数
    final presetParameters = <String, dynamic>{};
    final parameterNames = parameters.map((p) => p.name).toSet();

    for (final entry in values.entries) {
      if (parameterNames.contains(entry.key) && entry.value != null) {
        presetParameters[entry.key] = entry.value;
      }
    }

    return createPreset(
      name: name,
      type: type,
      scope: scope,
      parameters: presetParameters,
      description: description ?? '从模板创建的预设',
      author: author,
      tags: tags,
    );
  }

  /// 获取默认预设目录
  static String _getDefaultPresetDirectory() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$homeDir/.ming/presets';
  }

  /// 生成预设ID
  String _generatePresetId(String name, PresetType type, PresetScope scope) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameHash = name.hashCode.abs();
    return '${type.name}_${scope.name}_${nameHash}_$timestamp';
  }

  /// 保存预设到文件
  Future<void> _savePreset(ParameterPreset preset) async {
    final directory = Directory(_presetDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('$_presetDirectory/${preset.id}.json');
    final json = jsonEncode(preset.toMap());
    await file.writeAsString(json);
  }

  /// 从文件加载预设
  Future<ParameterPreset?> _loadPreset(String id) async {
    final file = File('$_presetDirectory/$id.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return ParameterPreset.fromMap(map);
    } catch (e) {
      cli_logger.Logger.error('加载预设文件失败: $id', error: e);
      return null;
    }
  }

  /// 加载所有预设
  Future<void> _loadAllPresets() async {
    final directory = Directory(_presetDirectory);
    if (!await directory.exists()) {
      return;
    }

    try {
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      for (final file in files) {
        final id = file.path.split('/').last.replaceAll('.json', '');
        if (!_presetCache.containsKey(id)) {
          final preset = await _loadPreset(id);
          if (preset != null) {
            _presetCache[id] = preset;

            // 更新继承关系缓存
            if (preset.parentPresetId != null) {
              _inheritanceCache
                  .putIfAbsent(preset.parentPresetId!, () => [])
                  .add(id);
            }
          }
        }
      }
    } catch (e) {
      cli_logger.Logger.error('加载预设目录失败', error: e);
    }
  }

  /// 删除预设文件
  Future<void> _deletePresetFile(String id) async {
    final file = File('$_presetDirectory/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 创建版本备份
  Future<void> _createVersionBackup(ParameterPreset preset) async {
    final backupDir = Directory('$_presetDirectory/versions/${preset.id}');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${backupDir.path}/$timestamp.json');
    final json = jsonEncode(preset.toMap());
    await backupFile.writeAsString(json);

    // 清理旧版本
    await _cleanupOldVersions(backupDir);
  }

  /// 清理旧版本
  Future<void> _cleanupOldVersions(Directory versionDir) async {
    try {
      final files = await versionDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      if (files.length > maxVersionHistory) {
        // 按修改时间排序，删除最旧的文件
        files.sort(
            (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),);

        final filesToDelete = files.take(files.length - maxVersionHistory);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      cli_logger.Logger.error('清理旧版本失败', error: e);
    }
  }
}
