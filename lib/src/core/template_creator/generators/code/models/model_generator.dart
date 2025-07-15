/*
---------------------------------------------------------------
File name:          model_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        数据模型文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 数据模型文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 数据模型文件生成器
///
/// 生成数据模型类文件
class ModelGenerator extends BaseCodeGenerator {
  /// 创建模型生成器实例
  const ModelGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_model.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/models';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(
      generateFileHeader(
        getFileName(config),
        config,
        '${config.templateName}数据模型类',
      ),
    );

    final className = _getClassName(config);
    final imports = _getImports(config);

    buffer.write(generateImports(imports));

    // 生成主模型类
    _generateMainModel(buffer, config, className);

    // 生成相关模型类
    if (config.complexity != TemplateComplexity.simple) {
      _generateRelatedModels(buffer, config);
    }

    return buffer.toString();
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    final name = config.templateName;
    // 将下划线命名转换为UpperCamelCase
    final parts = name.split('_');
    final capitalizedName = parts
        .map((part) => part.isNotEmpty
            ? part[0].toUpperCase() + part.substring(1).toLowerCase()
            : part)
        .join();
    return '${capitalizedName}Model';
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[];

    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'package:equatable/equatable.dart',
      ]);
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      imports.addAll([
        'package:freezed_annotation/freezed_annotation.dart',
        'package:json_annotation/json_annotation.dart',
      ]);
    }

    return imports;
  }

  /// 生成主模型类
  void _generateMainModel(
      StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}数据模型',
        examples: [
          "final model = $className(id: 1, name: '示例');",
          'final json = model.toJson();',
          'final fromJson = $className.fromJson(json);',
        ],
      ),
    );

    // 根据复杂度选择不同的实现方式
    if (config.complexity == TemplateComplexity.enterprise) {
      _generateFreezedModel(buffer, config, className);
    } else if (config.complexity != TemplateComplexity.simple) {
      _generateEquatableModel(buffer, config, className);
    } else {
      _generateSimpleModel(buffer, config, className);
    }
  }

  /// 生成简单模型
  void _generateSimpleModel(
      StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln('class $className {');

    // 生成字段
    _generateSimpleFields(buffer, config);

    // 生成构造函数
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({');
    buffer.writeln('    required this.id,');
    buffer.writeln('    required this.name,');
    buffer.writeln('    this.description,');
    buffer.writeln('    this.createdAt,');
    buffer.writeln('  });');
    buffer.writeln();

    // 生成toString方法
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');
    buffer.writeln(
        "    return '$className(id: \$id, name: \$name, description: \$description, createdAt: \$createdAt)';");
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成Equatable模型
  void _generateEquatableModel(
      StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln('class $className extends Equatable {');

    // 生成字段
    _generateEquatableFields(buffer, config);

    // 生成构造函数
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  $className({');
    buffer.writeln('    required this.id,');
    buffer.writeln('    required this.name,');
    buffer.writeln('    this.description,');
    buffer.writeln("    this.status = 'active',");
    buffer.writeln('    this.metadata,');
    buffer.writeln('    DateTime? createdAt,');
    buffer.writeln('    DateTime? updatedAt,');
    buffer.writeln('  }) : createdAt = createdAt ?? DateTime.now(),');
    buffer.writeln('       updatedAt = updatedAt ?? DateTime.now();');
    buffer.writeln();

    // 生成工厂构造函数
    buffer.writeln('  /// 从JSON创建实例');
    buffer
        .writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    buffer.writeln("      id: json['id'] as int,");
    buffer.writeln("      name: json['name'] as String,");
    buffer.writeln("      description: json['description'] as String?,");
    buffer.writeln("      status: json['status'] as String? ?? 'active',");
    buffer.writeln(
        "      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>) : <String, dynamic>{},");
    buffer.writeln("      createdAt: json['created_at'] != null");
    buffer.writeln("          ? DateTime.parse(json['created_at'] as String)");
    buffer.writeln('          : null,');
    buffer.writeln("      updatedAt: json['updated_at'] != null");
    buffer.writeln("          ? DateTime.parse(json['updated_at'] as String)");
    buffer.writeln('          : null,');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // 生成toJson方法
    buffer.writeln('  /// 转换为JSON');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    buffer.writeln("      'id': id,");
    buffer.writeln("      'name': name,");
    buffer
        .writeln("      if (description != null) 'description': description,");
    buffer.writeln("      'status': status,");
    buffer.writeln("      if (metadata != null) 'metadata': metadata,");
    buffer.writeln("      'created_at': createdAt.toIso8601String(),");
    buffer.writeln("      'updated_at': updatedAt.toIso8601String(),");
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // 生成copyWith方法
    buffer.writeln('  /// 创建副本并更新指定字段');
    buffer.writeln('  $className copyWith({');
    buffer.writeln('    int? id,');
    buffer.writeln('    String? name,');
    buffer.writeln('    String? description,');
    buffer.writeln('    String? status,');
    buffer.writeln('    Map<String, dynamic>? metadata,');
    buffer.writeln('    DateTime? createdAt,');
    buffer.writeln('    DateTime? updatedAt,');
    buffer.writeln('  }) {');
    buffer.writeln('    return $className(');
    buffer.writeln('      id: id ?? this.id,');
    buffer.writeln('      name: name ?? this.name,');
    buffer.writeln('      description: description ?? this.description,');
    buffer.writeln('      status: status ?? this.status,');
    buffer.writeln('      metadata: metadata ?? this.metadata,');
    buffer.writeln('      createdAt: createdAt ?? this.createdAt,');
    buffer.writeln('      updatedAt: updatedAt ?? DateTime.now(),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // 生成props
    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> get props => [');
    buffer.writeln('        id,');
    buffer.writeln('        name,');
    buffer.writeln('        description,');
    buffer.writeln('        status,');
    buffer.writeln('        metadata,');
    buffer.writeln('        createdAt,');
    buffer.writeln('        updatedAt,');
    buffer.writeln('      ];');

    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成Freezed模型
  void _generateFreezedModel(
      StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln("part '${config.templateName}_model.freezed.dart';");
    buffer.writeln("part '${config.templateName}_model.g.dart';");
    buffer.writeln();

    buffer.writeln('@freezed');
    buffer.writeln('class $className with _\$$className {');

    // 生成工厂构造函数
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const factory $className({');
    buffer.writeln('    required int id,');
    buffer.writeln('    required String name,');
    buffer.writeln('    String? description,');
    buffer.writeln("    @Default('active') String status,");
    buffer.writeln('    Map<String, dynamic>? metadata,');
    buffer.writeln('    DateTime? createdAt,');
    buffer.writeln('    DateTime? updatedAt,');
    buffer.writeln('  }) = _$className;');
    buffer.writeln();

    // 生成fromJson工厂方法
    buffer.writeln('  /// 从JSON创建实例');
    buffer
        .writeln('  factory $className.fromJson(Map<String, dynamic> json) =>');
    buffer.writeln('      _\$${className}FromJson(json);');

    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成简单字段
  void _generateSimpleFields(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 唯一标识符');
    buffer.writeln('  final int id;');
    buffer.writeln();

    buffer.writeln('  /// 名称');
    buffer.writeln('  final String name;');
    buffer.writeln();

    buffer.writeln('  /// 描述');
    buffer.writeln('  final String? description;');
    buffer.writeln();

    buffer.writeln('  /// 创建时间');
    buffer.writeln('  final DateTime? createdAt;');
    buffer.writeln();
  }

  /// 生成Equatable字段
  void _generateEquatableFields(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 唯一标识符');
    buffer.writeln('  final int id;');
    buffer.writeln();

    buffer.writeln('  /// 名称');
    buffer.writeln('  final String name;');
    buffer.writeln();

    buffer.writeln('  /// 描述');
    buffer.writeln('  final String? description;');
    buffer.writeln();

    buffer.writeln('  /// 状态');
    buffer.writeln('  final String status;');
    buffer.writeln();

    buffer.writeln('  /// 元数据');
    buffer.writeln('  final Map<String, dynamic>? metadata;');
    buffer.writeln();

    buffer.writeln('  /// 创建时间');
    buffer.writeln('  final DateTime createdAt;');
    buffer.writeln();

    buffer.writeln('  /// 更新时间');
    buffer.writeln('  final DateTime updatedAt;');
    buffer.writeln();
  }

  /// 生成相关模型类
  void _generateRelatedModels(StringBuffer buffer, ScaffoldConfig config) {
    // 生成列表响应模型
    _generateListResponseModel(buffer, config);

    // 生成创建请求模型
    _generateCreateRequestModel(buffer, config);

    // 生成更新请求模型
    _generateUpdateRequestModel(buffer, config);
  }

  /// 生成列表响应模型
  void _generateListResponseModel(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getClassName(config)}ListResponse';

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}列表响应模型',
      ),
    );

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('@freezed');
      buffer.writeln('class $className with _\$$className {');
      buffer.writeln('  /// 创建$className实例');
      buffer.writeln('  const factory $className({');
      buffer.writeln('    required List<${_getClassName(config)}> data,');
      buffer.writeln('    required int total,');
      buffer.writeln('    required int page,');
      buffer.writeln('    required int perPage,');
      buffer.writeln('    required int totalPages,');
      buffer.writeln('  }) = _$className;');
      buffer.writeln();
      buffer.writeln('  /// 从JSON创建实例');
      buffer.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) =>');
      buffer.writeln('      _\$${className}FromJson(json);');
      buffer.writeln('}');
    } else {
      buffer.writeln('class $className extends Equatable {');
      buffer.writeln('  /// 数据列表');
      buffer.writeln('  final List<${_getClassName(config)}> data;');
      buffer.writeln();
      buffer.writeln('  /// 总数量');
      buffer.writeln('  final int total;');
      buffer.writeln();
      buffer.writeln('  /// 当前页');
      buffer.writeln('  final int page;');
      buffer.writeln();
      buffer.writeln('  /// 每页数量');
      buffer.writeln('  final int perPage;');
      buffer.writeln();
      buffer.writeln('  /// 总页数');
      buffer.writeln('  final int totalPages;');
      buffer.writeln();

      buffer.writeln('  /// 创建$className实例');
      buffer.writeln('  const $className({');
      buffer.writeln('    required this.data,');
      buffer.writeln('    required this.total,');
      buffer.writeln('    required this.page,');
      buffer.writeln('    required this.perPage,');
      buffer.writeln('    required this.totalPages,');
      buffer.writeln('  });');
      buffer.writeln();

      buffer.writeln('  /// 从JSON创建实例');
      buffer.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) {');
      buffer.writeln('    return $className(');
      buffer.writeln("      data: (json['data'] as List)");
      buffer.writeln(
          '          .map((item) => ${_getClassName(config)}.fromJson(item as Map<String, dynamic>))');
      buffer.writeln('          .toList(),');
      buffer.writeln("      total: json['total'] as int,");
      buffer.writeln("      page: json['page'] as int,");
      buffer.writeln("      perPage: json['per_page'] as int,");
      buffer.writeln("      totalPages: json['total_pages'] as int,");
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  @override');
      buffer.writeln(
          '  List<Object?> get props => [data, total, page, perPage, totalPages];');
      buffer.writeln('}');
    }
    buffer.writeln();
  }

  /// 生成创建请求模型
  void _generateCreateRequestModel(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getClassName(config)}CreateRequest';

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}创建请求模型',
      ),
    );

    buffer.writeln('class $className extends Equatable {');
    buffer.writeln('  /// 名称');
    buffer.writeln('  final String name;');
    buffer.writeln();
    buffer.writeln('  /// 描述');
    buffer.writeln('  final String? description;');
    buffer.writeln();
    buffer.writeln('  /// 元数据');
    buffer.writeln('  final Map<String, dynamic>? metadata;');
    buffer.writeln();

    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({');
    buffer.writeln('    required this.name,');
    buffer.writeln('    this.description,');
    buffer.writeln('    this.metadata,');
    buffer.writeln('  });');
    buffer.writeln();

    buffer.writeln('  /// 转换为JSON');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    buffer.writeln("      'name': name,");
    buffer
        .writeln("      if (description != null) 'description': description,");
    buffer.writeln("      if (metadata != null) 'metadata': metadata,");
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer
        .writeln('  List<Object?> get props => [name, description, metadata];');
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成更新请求模型
  void _generateUpdateRequestModel(StringBuffer buffer, ScaffoldConfig config) {
    final className = '${_getClassName(config)}UpdateRequest';

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}更新请求模型',
      ),
    );

    buffer.writeln('class $className extends Equatable {');
    buffer.writeln('  /// 名称');
    buffer.writeln('  final String? name;');
    buffer.writeln();
    buffer.writeln('  /// 描述');
    buffer.writeln('  final String? description;');
    buffer.writeln();
    buffer.writeln('  /// 状态');
    buffer.writeln('  final String? status;');
    buffer.writeln();
    buffer.writeln('  /// 元数据');
    buffer.writeln('  final Map<String, dynamic>? metadata;');
    buffer.writeln();

    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  const $className({');
    buffer.writeln('    this.name,');
    buffer.writeln('    this.description,');
    buffer.writeln('    this.status,');
    buffer.writeln('    this.metadata,');
    buffer.writeln('  });');
    buffer.writeln();

    buffer.writeln('  /// 转换为JSON');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    final json = <String, dynamic>{};');
    buffer.writeln("    if (name != null) json['name'] = name;");
    buffer.writeln(
        "    if (description != null) json['description'] = description;");
    buffer.writeln("    if (status != null) json['status'] = status;");
    buffer.writeln("    if (metadata != null) json['metadata'] = metadata;");
    buffer.writeln('    return json;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln(
        '  List<Object?> get props => [name, description, status, metadata];');
    buffer.writeln('}');
    buffer.writeln();
  }
}
