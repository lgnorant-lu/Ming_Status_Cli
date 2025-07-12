/*
---------------------------------------------------------------
File name:          metadata_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        元数据管理器 (Metadata Manager)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板库管理系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/library/version_manager.dart';

/// 元数据类型
enum MetadataType {
  /// 基础元数据
  basic,

  /// 企业级元数据
  enterprise,

  /// 扩展元数据
  extended,

  /// 自定义元数据
  custom,
}

/// 元数据字段类型
enum MetadataFieldType {
  /// 字符串
  string,

  /// 数字
  number,

  /// 布尔值
  boolean,

  /// 日期时间
  datetime,

  /// 数组
  array,

  /// 对象
  object,

  /// 枚举
  enumeration,

  /// URL
  url,

  /// 邮箱
  email,
}

/// 元数据字段定义
class MetadataFieldDefinition {
  /// 创建元数据字段定义实例
  const MetadataFieldDefinition({
    required this.name,
    required this.type,
    required this.required,
    this.description,
    this.defaultValue,
    this.validationRules = const [],
    this.enumValues = const [],
    this.format,
    this.example,
  });

  /// 从Map创建字段定义
  factory MetadataFieldDefinition.fromMap(Map<String, dynamic> map) {
    return MetadataFieldDefinition(
      name: map['name']?.toString() ?? '',
      type: _parseFieldType(map['type']?.toString() ?? 'string'),
      required: map['required'] == true,
      description: map['description']?.toString(),
      defaultValue: map['default_value'],
      validationRules: map['validation_rules'] is List
          ? List<String>.from(map['validation_rules'] as List)
          : const [],
      enumValues: map['enum_values'] is List
          ? List<String>.from(map['enum_values'] as List)
          : const [],
      format: map['format']?.toString(),
      example: map['example'],
    );
  }

  /// 字段名称
  final String name;

  /// 字段类型
  final MetadataFieldType type;

  /// 是否必需
  final bool required;

  /// 字段描述
  final String? description;

  /// 默认值
  final dynamic defaultValue;

  /// 验证规则
  final List<String> validationRules;

  /// 枚举值 (当type为enumeration时)
  final List<String> enumValues;

  /// 格式规范
  final String? format;

  /// 示例值
  final dynamic example;

  /// 解析字段类型
  static MetadataFieldType _parseFieldType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'number':
      case 'int':
      case 'double':
        return MetadataFieldType.number;
      case 'boolean':
      case 'bool':
        return MetadataFieldType.boolean;
      case 'datetime':
      case 'date':
        return MetadataFieldType.datetime;
      case 'array':
      case 'list':
        return MetadataFieldType.array;
      case 'object':
      case 'map':
        return MetadataFieldType.object;
      case 'enumeration':
      case 'enum':
        return MetadataFieldType.enumeration;
      case 'url':
        return MetadataFieldType.url;
      case 'email':
        return MetadataFieldType.email;
      case 'string':
      default:
        return MetadataFieldType.string;
    }
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'required': required,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default_value': defaultValue,
      if (validationRules.isNotEmpty) 'validation_rules': validationRules,
      if (enumValues.isNotEmpty) 'enum_values': enumValues,
      if (format != null) 'format': format,
      if (example != null) 'example': example,
    };
  }
}

/// 元数据模式
class MetadataSchema {
  /// 创建元数据模式实例
  const MetadataSchema({
    required this.name,
    required this.version,
    required this.type,
    required this.fields,
    this.description,
    this.extendsSchema,
    this.metadata = const {},
  });

  /// 从Map创建元数据模式
  factory MetadataSchema.fromMap(Map<String, dynamic> map) {
    final fields = <MetadataFieldDefinition>[];
    if (map['fields'] is List) {
      for (final fieldData in map['fields'] as List) {
        if (fieldData is Map<String, dynamic>) {
          fields.add(MetadataFieldDefinition.fromMap(fieldData));
        }
      }
    }

    return MetadataSchema(
      name: map['name']?.toString() ?? '',
      version: map['version']?.toString() ?? '1.0.0',
      type: _parseMetadataType(map['type']?.toString() ?? 'basic'),
      fields: fields,
      description: map['description']?.toString(),
      extendsSchema: map['extends']?.toString(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  /// 模式名称
  final String name;

  /// 模式版本
  final String version;

  /// 模式类型
  final MetadataType type;

  /// 字段定义列表
  final List<MetadataFieldDefinition> fields;

  /// 模式描述
  final String? description;

  /// 继承的模式
  final String? extendsSchema;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 解析元数据类型
  static MetadataType _parseMetadataType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'enterprise':
        return MetadataType.enterprise;
      case 'extended':
        return MetadataType.extended;
      case 'custom':
        return MetadataType.custom;
      case 'basic':
      default:
        return MetadataType.basic;
    }
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'type': type.name,
      'fields': fields.map((f) => f.toMap()).toList(),
      if (description != null) 'description': description,
      if (extendsSchema != null) 'extends': extendsSchema,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// 元数据验证结果
class MetadataValidationResult {
  /// 创建元数据验证结果实例
  const MetadataValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.missingFields = const [],
    this.invalidFields = const [],
  });

  /// 是否有效
  final bool isValid;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 缺失字段
  final List<String> missingFields;

  /// 无效字段
  final List<String> invalidFields;
}

/// 元数据同步结果
class MetadataSyncResult {
  /// 创建元数据同步结果实例
  const MetadataSyncResult({
    required this.success,
    required this.templateId,
    this.updatedFields = const [],
    this.addedFields = const [],
    this.removedFields = const [],
    this.conflicts = const [],
    this.errors = const [],
  });

  /// 是否成功
  final bool success;

  /// 模板ID
  final String templateId;

  /// 更新的字段
  final List<String> updatedFields;

  /// 新增的字段
  final List<String> addedFields;

  /// 移除的字段
  final List<String> removedFields;

  /// 冲突字段
  final List<String> conflicts;

  /// 错误信息
  final List<String> errors;
}

/// 企业级模板元数据
class EnterpriseTemplateMetadata {
  /// 创建企业级模板元数据实例
  const EnterpriseTemplateMetadata({
    required this.templateId,
    required this.name,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.author,
    this.maintainer,
    this.organization,
    this.department,
    this.project,
    this.category,
    this.subcategory,
    this.tags = const [],
    this.keywords = const [],
    this.platforms = const [],
    this.frameworks = const [],
    this.languages = const [],
    this.dependencies = const {},
    this.requirements = const {},
    this.license,
    this.documentation,
    this.repository,
    this.homepage,
    this.bugTracker,
    this.support,
    this.changelog,
    this.roadmap,
    this.screenshots = const [],
    this.examples = const [],
    this.tutorials = const [],
    this.rating = 0.0,
    this.downloadCount = 0,
    this.usageCount = 0,
    this.lastUsed,
    this.complexity = 'medium',
    this.maturity = 'stable',
    this.security = const {},
    this.compliance = const {},
    this.performance = const {},
    this.accessibility = const {},
    this.localization = const {},
    this.customFields = const {},
  });

  /// 从Map创建企业级模板元数据
  factory EnterpriseTemplateMetadata.fromMap(Map<String, dynamic> map) {
    return EnterpriseTemplateMetadata(
      templateId: map['template_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      version: SemanticVersion.parse(map['version']?.toString() ?? '1.0.0'),
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] is String
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: map['description']?.toString(),
      author: map['author']?.toString(),
      maintainer: map['maintainer']?.toString(),
      organization: map['organization']?.toString(),
      department: map['department']?.toString(),
      project: map['project']?.toString(),
      category: map['category']?.toString(),
      subcategory: map['subcategory']?.toString(),
      tags: map['tags'] is List
          ? List<String>.from(map['tags'] as List)
          : const [],
      keywords: map['keywords'] is List
          ? List<String>.from(map['keywords'] as List)
          : const [],
      platforms: map['platforms'] is List
          ? List<String>.from(map['platforms'] as List)
          : const [],
      frameworks: map['frameworks'] is List
          ? List<String>.from(map['frameworks'] as List)
          : const [],
      languages: map['languages'] is List
          ? List<String>.from(map['languages'] as List)
          : const [],
      dependencies: map['dependencies'] is Map
          ? Map<String, String>.from(map['dependencies'] as Map)
          : const {},
      requirements: map['requirements'] is Map
          ? Map<String, dynamic>.from(map['requirements'] as Map)
          : const {},
      license: map['license']?.toString(),
      documentation: map['documentation']?.toString(),
      repository: map['repository']?.toString(),
      homepage: map['homepage']?.toString(),
      bugTracker: map['bug_tracker']?.toString(),
      support: map['support']?.toString(),
      changelog: map['changelog']?.toString(),
      roadmap: map['roadmap']?.toString(),
      screenshots: map['screenshots'] is List
          ? List<String>.from(map['screenshots'] as List)
          : const [],
      examples: map['examples'] is List
          ? List<String>.from(map['examples'] as List)
          : const [],
      tutorials: map['tutorials'] is List
          ? List<String>.from(map['tutorials'] as List)
          : const [],
      rating: map['rating'] is num ? (map['rating'] as num).toDouble() : 0.0,
      downloadCount:
          map['download_count'] is int ? map['download_count'] as int : 0,
      usageCount: map['usage_count'] is int ? map['usage_count'] as int : 0,
      lastUsed: map['last_used'] is String
          ? DateTime.tryParse(map['last_used'] as String)
          : null,
      complexity: map['complexity']?.toString() ?? 'medium',
      maturity: map['maturity']?.toString() ?? 'stable',
      security: map['security'] is Map
          ? Map<String, dynamic>.from(map['security'] as Map)
          : const {},
      compliance: map['compliance'] is Map
          ? Map<String, dynamic>.from(map['compliance'] as Map)
          : const {},
      performance: map['performance'] is Map
          ? Map<String, dynamic>.from(map['performance'] as Map)
          : const {},
      accessibility: map['accessibility'] is Map
          ? Map<String, dynamic>.from(map['accessibility'] as Map)
          : const {},
      localization: map['localization'] is Map
          ? Map<String, dynamic>.from(map['localization'] as Map)
          : const {},
      customFields: map['custom_fields'] is Map
          ? Map<String, dynamic>.from(map['custom_fields'] as Map)
          : const {},
    );
  }

  /// 模板ID
  final String templateId;

  /// 模板名称
  final String name;

  /// 版本信息
  final SemanticVersion version;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 模板描述
  final String? description;

  /// 作者
  final String? author;

  /// 维护者
  final String? maintainer;

  /// 组织
  final String? organization;

  /// 部门
  final String? department;

  /// 项目
  final String? project;

  /// 分类
  final String? category;

  /// 子分类
  final String? subcategory;

  /// 标签
  final List<String> tags;

  /// 关键词
  final List<String> keywords;

  /// 支持平台
  final List<String> platforms;

  /// 支持框架
  final List<String> frameworks;

  /// 支持语言
  final List<String> languages;

  /// 依赖关系
  final Map<String, String> dependencies;

  /// 系统要求
  final Map<String, dynamic> requirements;

  /// 许可证
  final String? license;

  /// 文档链接
  final String? documentation;

  /// 代码仓库
  final String? repository;

  /// 主页
  final String? homepage;

  /// 问题跟踪
  final String? bugTracker;

  /// 支持信息
  final String? support;

  /// 更新日志
  final String? changelog;

  /// 路线图
  final String? roadmap;

  /// 截图
  final List<String> screenshots;

  /// 示例
  final List<String> examples;

  /// 教程
  final List<String> tutorials;

  /// 评分
  final double rating;

  /// 下载次数
  final int downloadCount;

  /// 使用次数
  final int usageCount;

  /// 最后使用时间
  final DateTime? lastUsed;

  /// 复杂度 (simple, medium, complex)
  final String complexity;

  /// 成熟度 (experimental, beta, stable, deprecated)
  final String maturity;

  /// 安全信息
  final Map<String, dynamic> security;

  /// 合规信息
  final Map<String, dynamic> compliance;

  /// 性能信息
  final Map<String, dynamic> performance;

  /// 可访问性信息
  final Map<String, dynamic> accessibility;

  /// 本地化信息
  final Map<String, dynamic> localization;

  /// 自定义字段
  final Map<String, dynamic> customFields;

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'template_id': templateId,
      'name': name,
      'version': version.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (maintainer != null) 'maintainer': maintainer,
      if (organization != null) 'organization': organization,
      if (department != null) 'department': department,
      if (project != null) 'project': project,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (tags.isNotEmpty) 'tags': tags,
      if (keywords.isNotEmpty) 'keywords': keywords,
      if (platforms.isNotEmpty) 'platforms': platforms,
      if (frameworks.isNotEmpty) 'frameworks': frameworks,
      if (languages.isNotEmpty) 'languages': languages,
      if (dependencies.isNotEmpty) 'dependencies': dependencies,
      if (requirements.isNotEmpty) 'requirements': requirements,
      if (license != null) 'license': license,
      if (documentation != null) 'documentation': documentation,
      if (repository != null) 'repository': repository,
      if (homepage != null) 'homepage': homepage,
      if (bugTracker != null) 'bug_tracker': bugTracker,
      if (support != null) 'support': support,
      if (changelog != null) 'changelog': changelog,
      if (roadmap != null) 'roadmap': roadmap,
      if (screenshots.isNotEmpty) 'screenshots': screenshots,
      if (examples.isNotEmpty) 'examples': examples,
      if (tutorials.isNotEmpty) 'tutorials': tutorials,
      'rating': rating,
      'download_count': downloadCount,
      'usage_count': usageCount,
      if (lastUsed != null) 'last_used': lastUsed!.toIso8601String(),
      'complexity': complexity,
      'maturity': maturity,
      if (security.isNotEmpty) 'security': security,
      if (compliance.isNotEmpty) 'compliance': compliance,
      if (performance.isNotEmpty) 'performance': performance,
      if (accessibility.isNotEmpty) 'accessibility': accessibility,
      if (localization.isNotEmpty) 'localization': localization,
      if (customFields.isNotEmpty) 'custom_fields': customFields,
    };
  }

  /// 创建副本
  EnterpriseTemplateMetadata copyWith({
    String? templateId,
    String? name,
    SemanticVersion? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? author,
    String? maintainer,
    String? organization,
    String? department,
    String? project,
    String? category,
    String? subcategory,
    List<String>? tags,
    List<String>? keywords,
    List<String>? platforms,
    List<String>? frameworks,
    List<String>? languages,
    Map<String, String>? dependencies,
    Map<String, dynamic>? requirements,
    String? license,
    String? documentation,
    String? repository,
    String? homepage,
    String? bugTracker,
    String? support,
    String? changelog,
    String? roadmap,
    List<String>? screenshots,
    List<String>? examples,
    List<String>? tutorials,
    double? rating,
    int? downloadCount,
    int? usageCount,
    DateTime? lastUsed,
    String? complexity,
    String? maturity,
    Map<String, dynamic>? security,
    Map<String, dynamic>? compliance,
    Map<String, dynamic>? performance,
    Map<String, dynamic>? accessibility,
    Map<String, dynamic>? localization,
    Map<String, dynamic>? customFields,
  }) {
    return EnterpriseTemplateMetadata(
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      author: author ?? this.author,
      maintainer: maintainer ?? this.maintainer,
      organization: organization ?? this.organization,
      department: department ?? this.department,
      project: project ?? this.project,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      tags: tags ?? this.tags,
      keywords: keywords ?? this.keywords,
      platforms: platforms ?? this.platforms,
      frameworks: frameworks ?? this.frameworks,
      languages: languages ?? this.languages,
      dependencies: dependencies ?? this.dependencies,
      requirements: requirements ?? this.requirements,
      license: license ?? this.license,
      documentation: documentation ?? this.documentation,
      repository: repository ?? this.repository,
      homepage: homepage ?? this.homepage,
      bugTracker: bugTracker ?? this.bugTracker,
      support: support ?? this.support,
      changelog: changelog ?? this.changelog,
      roadmap: roadmap ?? this.roadmap,
      screenshots: screenshots ?? this.screenshots,
      examples: examples ?? this.examples,
      tutorials: tutorials ?? this.tutorials,
      rating: rating ?? this.rating,
      downloadCount: downloadCount ?? this.downloadCount,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      complexity: complexity ?? this.complexity,
      maturity: maturity ?? this.maturity,
      security: security ?? this.security,
      compliance: compliance ?? this.compliance,
      performance: performance ?? this.performance,
      accessibility: accessibility ?? this.accessibility,
      localization: localization ?? this.localization,
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  String toString() {
    return 'EnterpriseTemplateMetadata(id: $templateId, name: $name, version: $version)';
  }
}

/// 元数据管理器
class MetadataManager {
  /// 创建元数据管理器实例
  MetadataManager({
    this.enableValidation = true,
    this.enableAutoSync = true,
    this.syncInterval = const Duration(hours: 1),
  }) {
    // 元数据路径初始化已移除
  }

  // 元数据存储路径已移除 - 当前未使用

  /// 是否启用验证
  final bool enableValidation;

  /// 是否启用自动同步
  final bool enableAutoSync;

  /// 同步间隔
  final Duration syncInterval;

  /// 元数据模式映射
  final Map<String, MetadataSchema> _schemas = {};

  /// 模板元数据映射
  final Map<String, EnterpriseTemplateMetadata> _metadata = {};

  // 最后同步时间已移除 - 当前未使用

  /// 初始化元数据管理器
  Future<void> initialize() async {
    try {
      // 加载默认模式
      await _loadDefaultSchemas();

      // 加载元数据
      await _loadMetadata();

      // 启动自动同步
      if (enableAutoSync) {
        _startAutoSync();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 注册元数据模式
  Future<bool> registerSchema(MetadataSchema schema) async {
    try {
      _schemas[schema.name] = schema;
      await _saveSchemas();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取元数据模式
  MetadataSchema? getSchema(String name) {
    return _schemas[name];
  }

  /// 验证元数据
  Future<MetadataValidationResult> validateMetadata(
    String templateId,
    Map<String, dynamic> metadata,
    String schemaName,
  ) async {
    final schema = _schemas[schemaName];
    if (schema == null) {
      return const MetadataValidationResult(
        isValid: false,
        errors: ['元数据模式不存在'],
      );
    }

    final errors = <String>[];
    final warnings = <String>[];
    final missingFields = <String>[];
    final invalidFields = <String>[];

    // 检查必需字段
    for (final field in schema.fields) {
      if (field.required && !metadata.containsKey(field.name)) {
        missingFields.add(field.name);
        errors.add('缺少必需字段: ${field.name}');
      }
    }

    // 验证字段类型和值
    for (final entry in metadata.entries) {
      final fieldName = entry.key;
      final fieldValue = entry.value;

      final fieldDef =
          schema.fields.where((f) => f.name == fieldName).firstOrNull;

      if (fieldDef == null) {
        warnings.add('未知字段: $fieldName');
        continue;
      }

      if (!_validateFieldValue(fieldDef, fieldValue)) {
        invalidFields.add(fieldName);
        errors.add('字段值无效: $fieldName');
      }
    }

    return MetadataValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      missingFields: missingFields,
      invalidFields: invalidFields,
    );
  }

  /// 更新模板元数据
  Future<bool> updateMetadata(
    String templateId,
    EnterpriseTemplateMetadata metadata,
  ) async {
    try {
      _metadata[templateId] = metadata;
      await _saveMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取模板元数据
  EnterpriseTemplateMetadata? getMetadata(String templateId) {
    return _metadata[templateId];
  }

  /// 同步元数据
  Future<MetadataSyncResult> syncMetadata(
    String templateId,
    Map<String, dynamic> sourceMetadata,
  ) async {
    try {
      final existing = _metadata[templateId];
      final updatedFields = <String>[];
      final addedFields = <String>[];
      final removedFields = <String>[];
      final conflicts = <String>[];

      if (existing != null) {
        final existingMap = existing.toMap();

        // 检查更新和新增字段
        for (final entry in sourceMetadata.entries) {
          if (existingMap.containsKey(entry.key)) {
            if (existingMap[entry.key] != entry.value) {
              updatedFields.add(entry.key);
            }
          } else {
            addedFields.add(entry.key);
          }
        }

        // 检查移除字段
        for (final key in existingMap.keys) {
          if (!sourceMetadata.containsKey(key)) {
            removedFields.add(key);
          }
        }
      }

      return MetadataSyncResult(
        success: true,
        templateId: templateId,
        updatedFields: updatedFields,
        addedFields: addedFields,
        removedFields: removedFields,
        conflicts: conflicts,
      );
    } catch (e) {
      return MetadataSyncResult(
        success: false,
        templateId: templateId,
        errors: ['同步失败: $e'],
      );
    }
  }

  // 获取默认元数据路径方法已删除 - 未使用

  /// 加载默认模式
  Future<void> _loadDefaultSchemas() async {
    // 基础模式
    const basicSchema = MetadataSchema(
      name: 'basic',
      version: '1.0.0',
      type: MetadataType.basic,
      fields: [
        MetadataFieldDefinition(
          name: 'name',
          type: MetadataFieldType.string,
          required: true,
          description: '模板名称',
        ),
        MetadataFieldDefinition(
          name: 'version',
          type: MetadataFieldType.string,
          required: true,
          description: '模板版本',
        ),
        MetadataFieldDefinition(
          name: 'description',
          type: MetadataFieldType.string,
          required: false,
          description: '模板描述',
        ),
      ],
    );

    // 企业级模式
    final enterpriseSchema = MetadataSchema(
      name: 'enterprise',
      version: '1.0.0',
      type: MetadataType.enterprise,
      extendsSchema: 'basic',
      fields: [
        ...basicSchema.fields,
        const MetadataFieldDefinition(
          name: 'organization',
          type: MetadataFieldType.string,
          required: false,
          description: '组织名称',
        ),
        const MetadataFieldDefinition(
          name: 'department',
          type: MetadataFieldType.string,
          required: false,
          description: '部门名称',
        ),
        const MetadataFieldDefinition(
          name: 'compliance',
          type: MetadataFieldType.object,
          required: false,
          description: '合规信息',
        ),
      ],
    );

    _schemas['basic'] = basicSchema;
    _schemas['enterprise'] = enterpriseSchema;
  }

  /// 验证字段值
  bool _validateFieldValue(MetadataFieldDefinition field, dynamic value) {
    switch (field.type) {
      case MetadataFieldType.string:
        return value is String;
      case MetadataFieldType.number:
        return value is num;
      case MetadataFieldType.boolean:
        return value is bool;
      case MetadataFieldType.datetime:
        if (value is String) {
          return DateTime.tryParse(value) != null;
        }
        return value is DateTime;
      case MetadataFieldType.array:
        return value is List;
      case MetadataFieldType.object:
        return value is Map;
      case MetadataFieldType.enumeration:
        return field.enumValues.contains(value.toString());
      case MetadataFieldType.url:
        if (value is String) {
          try {
            Uri.parse(value);
            return true;
          } catch (e) {
            return false;
          }
        }
        return false;
      case MetadataFieldType.email:
        if (value is String) {
          return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
        }
        return false;
    }
  }

  /// 加载元数据
  Future<void> _loadMetadata() async {
    // 实现元数据加载
  }

  /// 保存元数据
  Future<void> _saveMetadata() async {
    // 实现元数据保存
  }

  /// 保存模式
  Future<void> _saveSchemas() async {
    // 实现模式保存
  }

  /// 启动自动同步
  void _startAutoSync() {
    // 实现自动同步
  }
}
