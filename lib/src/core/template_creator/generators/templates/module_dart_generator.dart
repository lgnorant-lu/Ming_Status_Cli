/*
---------------------------------------------------------------
File name:          module_dart_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模块定义文件生成器 (Module Dart Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - 模块定义文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 模块定义文件生成器
///
/// 生成符合模块规范的定义文件
class ModuleDartGenerator extends TemplateGeneratorBase {
  /// 创建模块定义生成器实例
  const ModuleDartGenerator();

  @override
  String getTemplateFileName() => 'module.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) =>
      '${config.templateName}_module.dart.template';

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(
      generateFileHeader(
        '${config.templateName}_module.dart',
        config,
        '${config.templateName}模块定义文件',
      ),
    );

    // 添加导入语句
    _generateImports(buffer, config);

    // 添加模块类定义
    _generateModuleClass(buffer, config);

    return buffer.toString();
  }

  /// 生成导入语句
  void _generateImports(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln("import 'dart:async';");
    buffer.writeln("import 'dart:developer' as developer;");

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln("import 'package:flutter/foundation.dart';");
      buffer.writeln("import 'package:flutter/material.dart';");
      buffer.writeln("import 'package:go_router/go_router.dart';");
    }

    buffer.writeln();
    buffer.writeln('/// 模块接口定义');
    buffer.writeln('abstract class ModuleInterface {');
    buffer.writeln('  /// 初始化模块');
    buffer.writeln('  Future<void> initialize();');
    buffer.writeln();
    buffer.writeln('  /// 销毁模块');
    buffer.writeln('  Future<void> dispose();');
    buffer.writeln();
    buffer.writeln('  /// 获取模块信息');
    buffer.writeln('  Map<String, dynamic> getModuleInfo();');
    buffer.writeln();
    buffer.writeln('  /// 注册路由');
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('  List<RouteBase> registerRoutes();');
    } else {
      buffer.writeln('  Map<String, Function> registerRoutes();');
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  /// 生成模块类
  void _generateModuleClass(StringBuffer buffer, ScaffoldConfig config) {
    final className = _getModuleClassName(config.templateName);

    buffer.writeln('/// ${config.templateName}模块实现');
    buffer.writeln('/// ');
    buffer.writeln('/// 提供${config.description ?? '模块功能'}');
    buffer.writeln('class $className implements ModuleInterface {');
    buffer.writeln('  /// 模块实例');
    buffer.writeln('  static $className? _instance;');
    buffer.writeln();
    buffer.writeln('  /// 模块初始化状态');
    buffer.writeln('  bool _isInitialized = false;');
    buffer.writeln();
    buffer.writeln('  /// 日志记录器');
    buffer.writeln(
      '  static void _log(String level, String message, [Object? error, StackTrace? stackTrace]) {',
    );
    buffer.writeln('    if (kDebugMode) {');
    buffer.writeln(
      "      developer.log(message, name: '$className', level: _getLogLevel(level), error: error, stackTrace: stackTrace);",
    );
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  static int _getLogLevel(String level) {');
    buffer.writeln('    switch (level.toLowerCase()) {');
    buffer.writeln("      case 'info': return 800;");
    buffer.writeln("      case 'warning': return 900;");
    buffer.writeln("      case 'severe': return 1000;");
    buffer.writeln('      default: return 700;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// 获取模块单例实例');
    buffer.writeln('  static $className get instance {');
    buffer.writeln('    _instance ??= $className._();');
    buffer.writeln('    return _instance!;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// 私有构造函数');
    buffer.writeln('  $className._();');
    buffer.writeln();
    buffer.writeln('  /// 检查模块是否已初始化');
    buffer.writeln('  bool get isInitialized => _isInitialized;');
    buffer.writeln();

    // 生成初始化方法
    _generateInitializeMethod(buffer, config);

    // 生成销毁方法
    _generateDisposeMethod(buffer, config);

    // 生成模块信息方法
    _generateModuleInfoMethod(buffer, config);

    // 生成路由注册方法
    _generateRegisterRoutesMethod(buffer, config);

    // 生成生命周期方法
    _generateLifecycleMethods(buffer, config);
  }

  /// 生成初始化方法
  void _generateInitializeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  @override');
    buffer.writeln('  Future<void> initialize() async {');
    buffer.writeln('    if (_isInitialized) {');
    buffer.writeln("      _log('warning', '模块已经初始化，跳过重复初始化');");
    buffer.writeln('      return;');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    try {');
    buffer.writeln("      _log('info', '开始初始化${config.templateName}模块');");
    buffer.writeln();

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('      // 初始化核心服务');
      buffer.writeln('      await _initializeServices();');
      buffer.writeln();
      buffer.writeln('      // 初始化数据存储');
      buffer.writeln('      await _initializeStorage();');
      buffer.writeln();
      buffer.writeln('      // 初始化缓存系统');
      buffer.writeln('      await _initializeCache();');
      buffer.writeln();
      buffer.writeln('      // 验证模块状态');
      buffer.writeln('      await _validateModuleState();');
    } else {
      buffer.writeln('      // 基础模块初始化');
      buffer.writeln('      await _initializeBasicServices();');
    }

    buffer.writeln();
    buffer.writeln('      _isInitialized = true;');
    buffer.writeln("      _log('info', '${config.templateName}模块初始化完成');");
    buffer.writeln('    } catch (e, stackTrace) {');
    buffer.writeln(
      "      _log('severe', '${config.templateName}模块初始化失败', e, stackTrace);",
    );
    buffer.writeln('      rethrow;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成销毁方法
  void _generateDisposeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  @override');
    buffer.writeln('  Future<void> dispose() async {');
    buffer.writeln('    // TODO: 实现模块清理逻辑');

    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('    // 清理服务');
      buffer.writeln('    // await _disposeServices();');
      buffer.writeln('    ');
      buffer.writeln('    // 关闭数据库连接');
      buffer.writeln('    // await _disposeDatabase();');
      buffer.writeln('    ');
      buffer.writeln('    // 清理缓存');
      buffer.writeln('    // await _disposeCache();');
    }

    buffer.writeln('    ');
    buffer.writeln("    print('${config.templateName}模块清理完成');");
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成模块信息方法
  void _generateModuleInfoMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, dynamic> getModuleInfo() {');
    buffer.writeln('    return {');
    buffer.writeln("      'name': '${config.templateName}',");
    buffer.writeln("      'version': '1.0.0',");
    buffer.writeln("      'description': '${config.description ?? '模块描述'}',");
    buffer.writeln("      'author': '${config.author ?? 'Unknown'}',");
    buffer.writeln("      'type': '${config.templateType.name}',");
    buffer.writeln("      'framework': '${config.framework.name}',");
    buffer.writeln("      'complexity': '${config.complexity.name}',");
    buffer.writeln("      'platform': '${config.platform.name}',");
    buffer.writeln("      'created_at': DateTime.now().toIso8601String(),");
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成路由注册方法
  void _generateRegisterRoutesMethod(
    StringBuffer buffer,
    ScaffoldConfig config,
  ) {
    buffer.writeln('  @override');

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('  List<RouteBase> registerRoutes() {');
      buffer.writeln('    return [');
      buffer.writeln('      // TODO: 添加模块路由');
      buffer.writeln('      GoRoute(');
      buffer.writeln("        path: '/${config.templateName}',");
      buffer.writeln("        name: '${config.templateName}',");
      buffer.writeln('        builder: (context, state) {');
      buffer.writeln('          // TODO: 返回模块主页面');
      buffer.writeln('          return const Placeholder();');
      buffer.writeln('        },');
      buffer.writeln('      ),');
      buffer.writeln('    ];');
    } else {
      buffer.writeln('  Map<String, Function> registerRoutes() {');
      buffer.writeln('    return {');
      buffer.writeln('      // TODO: 添加模块路由');
      buffer.writeln("      '/${config.templateName}': () {");
      buffer.writeln('        // TODO: 实现路由处理逻辑');
      buffer.writeln("        print('访问${config.templateName}模块');");
      buffer.writeln('      },');
      buffer.writeln('    };');
    }

    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成生命周期方法
  void _generateLifecycleMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 模块加载时调用');
    buffer.writeln('  Future<void> onModuleLoad() async {');
    buffer.writeln('    // TODO: 实现模块加载逻辑');
    buffer.writeln("    print('${config.templateName}模块已加载');");
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 模块卸载时调用');
    buffer.writeln('  Future<void> onModuleUnload() async {');
    buffer.writeln('    // TODO: 实现模块卸载逻辑');
    buffer.writeln("    print('${config.templateName}模块已卸载');");
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 配置变更时调用');
    buffer.writeln(
      '  Future<void> onConfigChanged(Map<String, dynamic> newConfig) async {',
    );
    buffer.writeln('    // TODO: 实现配置变更处理逻辑');
    buffer.writeln("    print('${config.templateName}模块配置已更新');");
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 权限变更时调用');
    buffer.writeln(
      '  Future<void> onPermissionChanged(List<String> permissions) async {',
    );
    buffer.writeln(
      "    _log('info', '${config.templateName}模块权限已更新: \$permissions');",
    );
    buffer.writeln('  }');
    buffer.writeln();

    // 添加辅助方法
    _generateHelperMethods(buffer, config);
  }

  /// 生成辅助方法
  void _generateHelperMethods(StringBuffer buffer, ScaffoldConfig config) {
    if (config.complexity == TemplateComplexity.enterprise) {
      buffer.writeln('  /// 初始化核心服务');
      buffer.writeln('  Future<void> _initializeServices() async {');
      buffer.writeln("    _log('info', '初始化核心服务');");
      buffer.writeln('    // 实现服务初始化逻辑');
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  /// 初始化数据存储');
      buffer.writeln('  Future<void> _initializeStorage() async {');
      buffer.writeln("    _log('info', '初始化数据存储');");
      buffer.writeln('    // 实现存储初始化逻辑');
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  /// 初始化缓存系统');
      buffer.writeln('  Future<void> _initializeCache() async {');
      buffer.writeln("    _log('info', '初始化缓存系统');");
      buffer.writeln('    // 实现缓存初始化逻辑');
      buffer.writeln('  }');
      buffer.writeln();

      buffer.writeln('  /// 验证模块状态');
      buffer.writeln('  Future<void> _validateModuleState() async {');
      buffer.writeln("    _log('info', '验证模块状态');");
      buffer.writeln('    // 实现状态验证逻辑');
      buffer.writeln('  }');
      buffer.writeln();
    } else {
      buffer.writeln('  /// 初始化基础服务');
      buffer.writeln('  Future<void> _initializeBasicServices() async {');
      buffer.writeln("    _log('info', '初始化基础服务');");
      buffer.writeln('    // 实现基础服务初始化逻辑');
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('}');
  }

  /// 获取模块类名
  String _getModuleClassName(String templateName) {
    // 将snake_case转换为PascalCase
    final words = templateName.split('_');
    final className = words
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join();
    return '${className}Module';
  }
}
