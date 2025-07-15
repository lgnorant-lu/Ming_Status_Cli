/*
---------------------------------------------------------------
File name:          service_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        服务层文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 服务层文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 服务层文件生成器
///
/// 生成业务逻辑服务类文件
class ServiceGenerator extends BaseCodeGenerator {
  /// 创建服务生成器实例
  const ServiceGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_service.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/services';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(
      generateFileHeader(
        getFileName(config),
        config,
        '${config.templateName}业务逻辑服务类',
      ),
    );

    final className = _getClassName(config);
    final imports = _getImports(config);

    buffer.write(generateImports(imports));

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}业务逻辑服务',
        examples: [
          'final service = $className();',
          'await service.initialize();',
          'final data = await service.fetchData();',
        ],
        seeAlso: ['Repository', 'Provider'],
      ),
    );

    buffer.writeln('class $className {');

    // 生成字段
    _generateFields(buffer, config);

    // 生成构造函数
    _generateConstructor(buffer, config, className);

    // 生成初始化方法
    _generateInitializeMethod(buffer, config);

    // 生成业务方法
    _generateBusinessMethods(buffer, config);

    // 生成工具方法
    _generateUtilityMethods(buffer, config);

    buffer.writeln('}');

    // 生成异常类
    _generateExceptionClasses(buffer, config);

    return buffer.toString();
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    return formatClassName(config.templateName, 'Service');
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[
      'dart:async',
    ];

    // 只在实际使用时添加imports
    if (config.complexity != TemplateComplexity.simple) {
      // 根据框架选择HTTP客户端
      if (config.framework == TemplateFramework.flutter) {
        imports.add('package:dio/dio.dart');
      } else {
        imports.addAll([
          'dart:convert',
          'dart:io',
          'package:http/http.dart',
        ]);
      }
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      imports.addAll([
        // '../models/${config.templateName}_model.dart',
        '../repositories/${config.templateName}_repository.dart',
        // '../utils/logger.dart',
        // '../utils/validators.dart',
      ]);
    }

    return imports;
  }

  /// 生成字段
  void _generateFields(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 是否已初始化');
    buffer.writeln('  bool _isInitialized = false;');
    buffer.writeln();

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// HTTP客户端');
      if (config.framework == TemplateFramework.flutter) {
        buffer.writeln('  late final Dio _dio;');
      } else {
        buffer.writeln('  late final HttpClient _httpClient;');
      }
      buffer.writeln();

      buffer.writeln('  /// 基础URL');
      buffer.writeln(
        "  static const String _baseUrl = 'https://api.example.com';",
      );
      buffer.writeln();
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  /// 数据仓库');
      buffer.writeln(
        '  late final ${_getRepositoryClassName(config)} _repository;',
      );
      buffer.writeln();

      buffer.writeln('  /// 缓存过期时间（分钟）');
      buffer.writeln('  static const int _cacheExpirationMinutes = 30;');
      buffer.writeln();

      buffer.writeln('  /// 缓存数据');
      buffer.writeln('  final Map<String, _CacheEntry> _cache = {};');
      buffer.writeln();
    }

    // Getter方法
    buffer.writeln('  /// 获取初始化状态');
    buffer.writeln('  bool get isInitialized => _isInitialized;');
    buffer.writeln();
  }

  /// 生成构造函数
  void _generateConstructor(
    StringBuffer buffer,
    ScaffoldConfig config,
    String className,
  ) {
    buffer.writeln('  /// 创建$className实例');
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  $className({');
      buffer.writeln('    ${_getRepositoryClassName(config)}? repository,');
      buffer.writeln('  }) {');
      buffer.writeln(
        '    _repository = repository ?? ${_getRepositoryClassName(config)}();',
      );
      buffer.writeln('  }');
    } else {
      buffer.writeln('  $className();');
    }
    buffer.writeln();
  }

  /// 生成初始化方法
  void _generateInitializeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 初始化服务');
    buffer.writeln('  Future<void> initialize() async {');
    buffer.writeln('    if (_isInitialized) return;');
    buffer.writeln();

    if (config.complexity != TemplateComplexity.simple) {
      if (config.framework == TemplateFramework.flutter) {
        buffer.writeln('    // 初始化Dio客户端');
        buffer.writeln('    _dio = Dio(BaseOptions(');
        buffer.writeln('      baseUrl: _baseUrl,');
        buffer.writeln('      connectTimeout: const Duration(seconds: 30),');
        buffer.writeln('      receiveTimeout: const Duration(seconds: 30),');
        buffer.writeln('      headers: {');
        buffer.writeln("        'Content-Type': 'application/json',");
        buffer.writeln("        'Accept': 'application/json',");
        buffer.writeln('      },');
        buffer.writeln('    ));');
      } else {
        buffer.writeln('    // 初始化HTTP客户端');
        buffer.writeln('    _httpClient = HttpClient();');
        buffer.writeln(
          '    _httpClient.connectionTimeout = const Duration(seconds: 30);',
        );
      }
      buffer.writeln();
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    // 初始化数据仓库');
      buffer.writeln('    await _repository.initialize();');
      buffer.writeln();
    }

    buffer.writeln('    _isInitialized = true;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成业务方法
  void _generateBusinessMethods(StringBuffer buffer, ScaffoldConfig config) {
    // 获取数据方法
    buffer.writeln('  /// 获取数据列表');
    buffer.writeln('  Future<List<Map<String, dynamic>>> fetchData({');
    buffer.writeln('    int page = 1,');
    buffer.writeln('    int limit = 20,');
    buffer.writeln('    bool useCache = true,');
    buffer.writeln('  }) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln(r"    final cacheKey = 'data_${page}_$limit';");
      buffer.writeln('    ');
      buffer.writeln('    // 检查缓存');
      buffer.writeln('    if (useCache && _cache.containsKey(cacheKey)) {');
      buffer.writeln('      final entry = _cache[cacheKey]!;');
      buffer.writeln('      if (!entry.isExpired) {');
      buffer.writeln(
        '        return List<Map<String, dynamic>>.from(entry.data as List);',
      );
      buffer.writeln('      }');
      buffer.writeln('    }');
      buffer.writeln();
    }

    buffer.writeln('    try {');
    if (config.complexity == TemplateComplexity.simple) {
      buffer.writeln('      // 模拟数据获取');
      buffer.writeln(
          '      await Future<void>.delayed(const Duration(seconds: 1));');
      buffer.writeln('      return [');
      buffer.writeln("        {'id': 1, 'name': '示例数据1', 'page': page},");
      buffer.writeln("        {'id': 2, 'name': '示例数据2', 'page': page},");
      buffer.writeln('      ];');
    } else {
      if (config.framework == TemplateFramework.flutter) {
        buffer.writeln(
          "      final Response<Map<String, dynamic>> response = await _dio.get('/data', queryParameters: {",
        );
        buffer.writeln("        'page': page,");
        buffer.writeln("        'limit': limit,");
        buffer.writeln('      });');
        buffer.writeln();
        buffer.writeln('      if (response.statusCode == 200) {');
        buffer.writeln(
          "        final dynamic rawData = response.data?['data'] ?? <dynamic>[];",
        );
        buffer.writeln(
          "        final List<dynamic> listData = rawData is List ? rawData : <dynamic>[];",
        );
        buffer.writeln(
          "        final data = listData.map((item) => Map<String, dynamic>.from(item as Map)).toList();",
        );
      } else {
        buffer.writeln(
          r"      final uri = Uri.parse('$_baseUrl/data?page=$page&limit=$limit');",
        );
        buffer.writeln('      final request = await _httpClient.getUrl(uri);');
        buffer.writeln('      final response = await request.close();');
        buffer.writeln();
        buffer.writeln('      if (response.statusCode == 200) {');
        buffer.writeln(
          '        final responseBody = await response.transform(utf8.decoder).join();',
        );
        buffer.writeln('        final jsonData = jsonDecode(responseBody);');
        buffer.writeln(
          "        final data = List<Map<String, dynamic>>.from(jsonData['data'] ?? []);",
        );
      }

      if (config.complexity == TemplateComplexity.enterprise) {
        buffer.writeln();
        buffer.writeln('        // 缓存数据');
        buffer.writeln('        _cache[cacheKey] = _CacheEntry(data);');
      }

      buffer.writeln();
      buffer.writeln('        return data;');
      buffer.writeln('      } else {');
      buffer.writeln('        throw ${_getClassName(config)}Exception(');
      buffer.writeln(
        r"          'Failed to fetch data: HTTP ${response.statusCode}',",
      );
      buffer.writeln('        );');
      buffer.writeln('      }');
    }

    buffer.writeln('    } catch (e) {');
    buffer.writeln('      throw ${_getClassName(config)}Exception(');
    buffer.writeln(r"        'Error fetching data: $e',");
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // 获取单个项目方法
    buffer.writeln('  /// 根据ID获取单个数据项');
    buffer.writeln('  Future<Map<String, dynamic>?> fetchById(int id) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    buffer.writeln('    try {');
    if (config.complexity == TemplateComplexity.simple) {
      buffer.writeln('      // 模拟数据获取');
      buffer.writeln(
        '      await Future<void>.delayed(const Duration(milliseconds: 500));',
      );
      buffer.writeln(r"      return {'id': id, 'name': '示例数据$id'};");
    } else {
      if (config.framework == TemplateFramework.flutter) {
        buffer.writeln(
            r"      final Response<Map<String, dynamic>> response = await _dio.get('/data/$id');");
        buffer.writeln('      ');
        buffer.writeln('      if (response.statusCode == 200) {');
        buffer.writeln(
          '        return Map<String, dynamic>.from(response.data as Map);',
        );
      } else {
        buffer.writeln(r"      final uri = Uri.parse('$_baseUrl/data/$id');");
        buffer.writeln('      final request = await _httpClient.getUrl(uri);');
        buffer.writeln('      final response = await request.close();');
        buffer.writeln('      ');
        buffer.writeln('      if (response.statusCode == 200) {');
        buffer.writeln(
          '        final responseBody = await response.transform(utf8.decoder).join();',
        );
        buffer.writeln(
          '        return Map<String, dynamic>.from(jsonDecode(responseBody));',
        );
      }
      buffer.writeln('      } else if (response.statusCode == 404) {');
      buffer.writeln('        return null;');
      buffer.writeln('      } else {');
      buffer.writeln('        throw ${_getClassName(config)}Exception(');
      buffer.writeln(
        r"          'Failed to fetch item: HTTP ${response.statusCode}',",
      );
      buffer.writeln('        );');
      buffer.writeln('      }');
    }
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      throw ${_getClassName(config)}Exception(');
    buffer.writeln(r"        'Error fetching item: $e',");
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // 创建数据方法
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 创建新数据项');
      buffer.writeln(
        '  Future<Map<String, dynamic>> createData(Map<String, dynamic> data) async {',
      );
      buffer.writeln('    _ensureInitialized();');
      buffer.writeln();
      buffer.writeln('    try {');
      if (config.framework == TemplateFramework.flutter) {
        buffer.writeln(
          "      final Response<Map<String, dynamic>> response = await _dio.post('/data', data: data);",
        );
        buffer.writeln('      ');
        buffer.writeln('      if (response.statusCode == 201) {');
        buffer.writeln(
          '        final Map<String, dynamic> createdData = Map<String, dynamic>.from(response.data as Map);',
        );
      } else {
        buffer.writeln(r"      final uri = Uri.parse('$_baseUrl/data');");
        buffer.writeln('      final request = await _httpClient.postUrl(uri);');
        buffer.writeln('      request.headers.contentType = ContentType.json;');
        buffer.writeln('      request.write(jsonEncode(data));');
        buffer.writeln('      final response = await request.close();');
        buffer.writeln('      ');
        buffer.writeln('      if (response.statusCode == 201) {');
        buffer.writeln(
          '        final responseBody = await response.transform(utf8.decoder).join();',
        );
        buffer.writeln(
          '        final createdData = Map<String, dynamic>.from(jsonDecode(responseBody));',
        );
      }

      if (config.complexity == TemplateComplexity.enterprise) {
        buffer.writeln('        ');
        buffer.writeln('        // 清除相关缓存');
        buffer.writeln('        _clearDataCache();');
      }

      buffer.writeln('        ');
      buffer.writeln('        return createdData;');
      buffer.writeln('      } else {');
      buffer.writeln('        throw ${_getClassName(config)}Exception(');
      buffer.writeln(
        r"          'Failed to create data: HTTP ${response.statusCode}',",
      );
      buffer.writeln('        );');
      buffer.writeln('      }');
      buffer.writeln('    } catch (e) {');
      buffer.writeln('      throw ${_getClassName(config)}Exception(');
      buffer.writeln(r"        'Error creating data: $e',");
      buffer.writeln('      );');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }
  }

  /// 生成工具方法
  void _generateUtilityMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 确保服务已初始化');
    buffer.writeln('  void _ensureInitialized() {');
    buffer.writeln('    if (!_isInitialized) {');
    buffer.writeln(
      "      throw StateError('Service not initialized. Call initialize() first.');",
    );
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  /// 清除数据缓存');
      buffer.writeln('  void _clearDataCache() {');
      buffer.writeln(
        "    _cache.removeWhere((key, value) => key.startsWith('data_'));",
      );
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  /// 清除所有缓存');
      buffer.writeln('  void clearCache() {');
      buffer.writeln('    _cache.clear();');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  /// 清理资源');
    buffer.writeln('  void dispose() {');
    if (config.complexity != TemplateComplexity.simple) {
      if (config.framework != TemplateFramework.flutter) {
        buffer.writeln('    _httpClient.close();');
      }
    }
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    _cache.clear();');
      buffer.writeln('    _repository.dispose();');
    }
    buffer.writeln('    _isInitialized = false;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成异常类
  void _generateExceptionClasses(StringBuffer buffer, ScaffoldConfig config) {
    final exceptionClassName = '${_getClassName(config)}Exception';

    buffer.writeln();
    buffer.writeln('/// ${config.templateName}服务异常');
    buffer.writeln('class $exceptionClassName implements Exception {');
    buffer.writeln('  /// 错误消息');
    buffer.writeln('  final String message;');
    buffer.writeln();
    buffer.writeln('  /// 创建异常实例');
    buffer.writeln('  const $exceptionClassName(this.message);');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln("  String toString() => '$exceptionClassName: \$message';");
    buffer.writeln('}');

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln();
      buffer.writeln('/// 缓存条目');
      buffer.writeln('class _CacheEntry {');
      buffer.writeln('  /// 缓存数据');
      buffer.writeln('  final dynamic data;');
      buffer.writeln();
      buffer.writeln('  /// 创建时间');
      buffer.writeln('  final DateTime createdAt;');
      buffer.writeln();
      buffer.writeln('  /// 创建缓存条目');
      buffer.writeln('  _CacheEntry(this.data) : createdAt = DateTime.now();');
      buffer.writeln();
      buffer.writeln('  /// 是否已过期');
      buffer.writeln('  bool get isExpired {');
      buffer.writeln('    final expirationTime = createdAt.add(');
      buffer.writeln(
        '      const Duration(minutes: ${_getClassName(config)}._cacheExpirationMinutes),',
      );
      buffer.writeln('    );');
      buffer.writeln('    return DateTime.now().isAfter(expirationTime);');
      buffer.writeln('  }');
      buffer.writeln('}');
    }
  }

  /// 获取仓库类名
  String _getRepositoryClassName(ScaffoldConfig config) {
    final name = config.templateName;
    // 将snake_case转换为PascalCase
    final parts = name.split('_');
    final capitalizedParts =
        parts.map((part) => part[0].toUpperCase() + part.substring(1)).toList();
    return '${capitalizedParts.join('')}Repository';
  }
}
