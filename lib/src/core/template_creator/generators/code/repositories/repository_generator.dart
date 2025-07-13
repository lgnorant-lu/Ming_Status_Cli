/*
---------------------------------------------------------------
File name:          repository_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        数据仓库Repository文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 数据仓库Repository文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 数据仓库Repository文件生成器
///
/// 生成数据访问层Repository类文件
class RepositoryGenerator extends BaseCodeGenerator {
  /// 创建Repository生成器实例
  const RepositoryGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_repository.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/repositories';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();
    
    // 添加文件头部注释
    buffer.write(generateFileHeader(
      getFileName(config),
      config,
      '${config.templateName}数据仓库Repository',
    ),);

    final className = _getClassName(config);
    final imports = _getImports(config);
    
    buffer.write(generateImports(imports));
    
    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}数据访问层Repository',
      examples: [
        'final repository = $className();',
        'await repository.initialize();',
        'final data = await repository.findAll();',
        'final item = await repository.findById(1);',
      ],
      seeAlso: ['Service', 'Model'],
    ),);

    buffer.writeln('class $className {');
    
    // 生成字段
    _generateFields(buffer, config);
    
    // 生成构造函数
    _generateConstructor(buffer, config, className);
    
    // 生成初始化方法
    _generateInitializeMethod(buffer, config);
    
    // 生成CRUD方法
    _generateCrudMethods(buffer, config);
    
    // 生成查询方法
    _generateQueryMethods(buffer, config);
    
    // 生成工具方法
    _generateUtilityMethods(buffer, config);
    
    buffer.writeln('}');
    
    // 生成异常类
    _generateExceptionClasses(buffer, config);

    return buffer.toString();
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    final name = config.templateName;
    final capitalizedName = name[0].toUpperCase() + name.substring(1);
    return '${capitalizedName}Repository';
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[
      'dart:async',
    ];
    
    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'dart:convert',
        'dart:io',
        '../models/${config.templateName}_model.dart',
      ]);
    }
    
    if (config.complexity == TemplateComplexity.enterprise) {
      imports.addAll([
        'package:sqflite/sqflite.dart',
        'package:path/path.dart',
        '../utils/database_helper.dart',
        '../utils/logger.dart',
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
      buffer.writeln('  /// 内存缓存');
      buffer.writeln('  final Map<int, Map<String, dynamic>> _cache = {};');
      buffer.writeln();
      
      buffer.writeln('  /// 缓存过期时间（毫秒）');
      buffer.writeln('  static const int _cacheExpirationMs = 300000; // 5分钟');
      buffer.writeln();
    }
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  /// 数据库实例');
      buffer.writeln('  Database? _database;');
      buffer.writeln();
      
      buffer.writeln('  /// 表名');
      buffer.writeln("  static const String _tableName = '${config.templateName}s';");
      buffer.writeln();
    }
    
    // Getter方法
    buffer.writeln('  /// 获取初始化状态');
    buffer.writeln('  bool get isInitialized => _isInitialized;');
    buffer.writeln();
  }

  /// 生成构造函数
  void _generateConstructor(StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  $className();');
    buffer.writeln();
  }

  /// 生成初始化方法
  void _generateInitializeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 初始化Repository');
    buffer.writeln('  Future<void> initialize() async {');
    buffer.writeln('    if (_isInitialized) return;');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    // 初始化数据库');
      buffer.writeln('    final databasesPath = await getDatabasesPath();');
      buffer.writeln("    final path = join(databasesPath, '${config.templateName}.db');");
      buffer.writeln();
      buffer.writeln('    _database = await openDatabase(');
      buffer.writeln('      path,');
      buffer.writeln('      version: 1,');
      buffer.writeln('      onCreate: _createTables,');
      buffer.writeln('      onUpgrade: _upgradeTables,');
      buffer.writeln('    );');
      buffer.writeln();
    }
    
    buffer.writeln('    _isInitialized = true;');
    buffer.writeln('  }');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  /// 创建数据库表');
      buffer.writeln('  Future<void> _createTables(Database db, int version) async {');
      buffer.writeln("    await db.execute('''");
      buffer.writeln(r'      CREATE TABLE $_tableName (');
      buffer.writeln('        id INTEGER PRIMARY KEY AUTOINCREMENT,');
      buffer.writeln('        name TEXT NOT NULL,');
      buffer.writeln('        description TEXT,');
      buffer.writeln("        status TEXT DEFAULT 'active',");
      buffer.writeln('        metadata TEXT,');
      buffer.writeln('        created_at TEXT NOT NULL,');
      buffer.writeln('        updated_at TEXT NOT NULL');
      buffer.writeln('      )');
      buffer.writeln("    ''');");
      buffer.writeln('  }');
      buffer.writeln();
      
      buffer.writeln('  /// 升级数据库表');
      buffer.writeln('  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {');
      buffer.writeln('    // TODO: 实现数据库升级逻辑');
      buffer.writeln('  }');
      buffer.writeln();
    }
  }

  /// 生成CRUD方法
  void _generateCrudMethods(StringBuffer buffer, ScaffoldConfig config) {
    // Create方法
    buffer.writeln('  /// 创建新记录');
    buffer.writeln('  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final now = DateTime.now().toIso8601String();');
      buffer.writeln('    final insertData = {');
      buffer.writeln('      ...data,');
      buffer.writeln("      'created_at': now,");
      buffer.writeln("      'updated_at': now,");
      buffer.writeln('    };');
      buffer.writeln();
      buffer.writeln('    final id = await _database!.insert(_tableName, insertData);');
      buffer.writeln("    final result = {'id': id, ...insertData};");
      buffer.writeln();
      buffer.writeln('    // 更新缓存');
      buffer.writeln('    _cache[id] = result;');
      buffer.writeln();
      buffer.writeln('    return result;');
    } else {
      buffer.writeln('    // 模拟创建操作');
      buffer.writeln('    final id = DateTime.now().millisecondsSinceEpoch;');
      buffer.writeln('    final result = {');
      buffer.writeln("      'id': id,");
      buffer.writeln('      ...data,');
      buffer.writeln("      'created_at': DateTime.now().toIso8601String(),");
      buffer.writeln('    };');
      buffer.writeln();
      if (config.complexity != TemplateComplexity.simple) {
        buffer.writeln('    // 添加到缓存');
        buffer.writeln('    _cache[id] = result;');
        buffer.writeln();
      }
      buffer.writeln('    return result;');
    }
    
    buffer.writeln('  }');
    buffer.writeln();
    
    // Read方法
    buffer.writeln('  /// 根据ID查找记录');
    buffer.writeln('  Future<Map<String, dynamic>?> findById(int id) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    // 检查缓存');
      buffer.writeln('    if (_cache.containsKey(id)) {');
      buffer.writeln('      return _cache[id];');
      buffer.writeln('    }');
      buffer.writeln();
    }
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final results = await _database!.query(');
      buffer.writeln('      _tableName,');
      buffer.writeln("      where: 'id = ?',");
      buffer.writeln('      whereArgs: [id],');
      buffer.writeln('      limit: 1,');
      buffer.writeln('    );');
      buffer.writeln();
      buffer.writeln('    if (results.isNotEmpty) {');
      buffer.writeln('      final result = results.first;');
      buffer.writeln('      _cache[id] = result;');
      buffer.writeln('      return result;');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    return null;');
    } else {
      buffer.writeln('    // 模拟查找操作');
      buffer.writeln('    await Future.delayed(const Duration(milliseconds: 100));');
      buffer.writeln('    return {');
      buffer.writeln("      'id': id,");
      buffer.writeln(r"      'name': '示例记录$id',");
      buffer.writeln("      'created_at': DateTime.now().toIso8601String(),");
      buffer.writeln('    };');
    }
    
    buffer.writeln('  }');
    buffer.writeln();
    
    // Update方法
    buffer.writeln('  /// 更新记录');
    buffer.writeln('  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> data) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final updateData = {');
      buffer.writeln('      ...data,');
      buffer.writeln("      'updated_at': DateTime.now().toIso8601String(),");
      buffer.writeln('    };');
      buffer.writeln();
      buffer.writeln('    final count = await _database!.update(');
      buffer.writeln('      _tableName,');
      buffer.writeln('      updateData,');
      buffer.writeln("      where: 'id = ?',");
      buffer.writeln('      whereArgs: [id],');
      buffer.writeln('    );');
      buffer.writeln();
      buffer.writeln('    if (count > 0) {');
      buffer.writeln('      final updated = await findById(id);');
      buffer.writeln('      if (updated != null) {');
      buffer.writeln('        _cache[id] = updated;');
      buffer.writeln('      }');
      buffer.writeln('      return updated;');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    return null;');
    } else {
      buffer.writeln('    // 模拟更新操作');
      buffer.writeln('    final existing = await findById(id);');
      buffer.writeln('    if (existing != null) {');
      buffer.writeln('      final updated = {');
      buffer.writeln('        ...existing,');
      buffer.writeln('        ...data,');
      buffer.writeln("        'updated_at': DateTime.now().toIso8601String(),");
      buffer.writeln('      };');
      if (config.complexity != TemplateComplexity.simple) {
        buffer.writeln('      _cache[id] = updated;');
      }
      buffer.writeln('      return updated;');
      buffer.writeln('    }');
      buffer.writeln('    return null;');
    }
    
    buffer.writeln('  }');
    buffer.writeln();
    
    // Delete方法
    buffer.writeln('  /// 删除记录');
    buffer.writeln('  Future<bool> delete(int id) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final count = await _database!.delete(');
      buffer.writeln('      _tableName,');
      buffer.writeln("      where: 'id = ?',");
      buffer.writeln('      whereArgs: [id],');
      buffer.writeln('    );');
      buffer.writeln();
      buffer.writeln('    if (count > 0) {');
      buffer.writeln('      _cache.remove(id);');
      buffer.writeln('      return true;');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    return false;');
    } else {
      buffer.writeln('    // 模拟删除操作');
      if (config.complexity != TemplateComplexity.simple) {
        buffer.writeln('    final removed = _cache.remove(id);');
        buffer.writeln('    return removed != null;');
      } else {
        buffer.writeln('    await Future.delayed(const Duration(milliseconds: 50));');
        buffer.writeln('    return true; // 模拟成功删除');
      }
    }
    
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成查询方法
  void _generateQueryMethods(StringBuffer buffer, ScaffoldConfig config) {
    // FindAll方法
    buffer.writeln('  /// 查找所有记录');
    buffer.writeln('  Future<List<Map<String, dynamic>>> findAll({');
    buffer.writeln('    int? limit,');
    buffer.writeln('    int? offset,');
    buffer.writeln('    String? orderBy,');
    buffer.writeln('  }) async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final results = await _database!.query(');
      buffer.writeln('      _tableName,');
      buffer.writeln("      orderBy: orderBy ?? 'created_at DESC',");
      buffer.writeln('      limit: limit,');
      buffer.writeln('      offset: offset,');
      buffer.writeln('    );');
      buffer.writeln();
      buffer.writeln('    // 更新缓存');
      buffer.writeln('    for (final result in results) {');
      buffer.writeln("      final id = result['id'] as int;");
      buffer.writeln('      _cache[id] = result;');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    return results;');
    } else {
      buffer.writeln('    // 模拟查询操作');
      buffer.writeln('    await Future.delayed(const Duration(milliseconds: 200));');
      buffer.writeln('    return List.generate(limit ?? 10, (index) => {');
      buffer.writeln("      'id': index + 1,");
      buffer.writeln(r"      'name': '示例记录${index + 1}',");
      buffer.writeln("      'created_at': DateTime.now().toIso8601String(),");
      buffer.writeln('    });');
    }
    
    buffer.writeln('  }');
    buffer.writeln();
    
    // Count方法
    buffer.writeln('  /// 获取记录总数');
    buffer.writeln('  Future<int> count() async {');
    buffer.writeln('    _ensureInitialized();');
    buffer.writeln();
    
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    final result = await _database!.rawQuery(');
      buffer.writeln(r"      'SELECT COUNT(*) as count FROM $_tableName',");
      buffer.writeln('    );');
      buffer.writeln("    return result.first['count'] as int;");
    } else {
      buffer.writeln('    // 模拟计数操作');
      buffer.writeln('    await Future.delayed(const Duration(milliseconds: 50));');
      buffer.writeln('    return 42; // 模拟总数');
    }
    
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成工具方法
  void _generateUtilityMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 确保Repository已初始化');
    buffer.writeln('  void _ensureInitialized() {');
    buffer.writeln('    if (!_isInitialized) {');
    buffer.writeln("      throw StateError('Repository not initialized. Call initialize() first.');");
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 清除缓存');
      buffer.writeln('  void clearCache() {');
      buffer.writeln('    _cache.clear();');
      buffer.writeln('  }');
      buffer.writeln();
    }
    
    buffer.writeln('  /// 清理资源');
    buffer.writeln('  Future<void> dispose() async {');
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    await _database?.close();');
      buffer.writeln('    _database = null;');
    }
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    _cache.clear();');
    }
    buffer.writeln('    _isInitialized = false;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成异常类
  void _generateExceptionClasses(StringBuffer buffer, ScaffoldConfig config) {
    final exceptionClassName = '${_getClassName(config)}Exception';
    
    buffer.writeln();
    buffer.writeln('/// ${config.templateName}仓库异常');
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
  }
}
