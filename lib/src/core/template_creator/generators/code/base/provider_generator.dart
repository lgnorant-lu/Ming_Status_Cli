/*
---------------------------------------------------------------
File name:          provider_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        状态管理Provider文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 状态管理Provider文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 状态管理Provider文件生成器
///
/// 根据不同的状态管理方案生成对应的Provider文件
class ProviderGenerator extends BaseCodeGenerator {
  /// 创建Provider生成器实例
  const ProviderGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_provider.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/providers';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(generateFileHeader(
      getFileName(config),
      config,
      '${config.templateName}状态管理Provider',
    ),);

    // 根据框架类型生成不同的Provider
    if (config.framework == TemplateFramework.flutter) {
      _generateFlutterProvider(buffer, config);
    } else {
      _generateDartProvider(buffer, config);
    }

    return buffer.toString();
  }

  /// 生成Flutter Provider
  void _generateFlutterProvider(StringBuffer buffer, ScaffoldConfig config) {
    final className = _getClassName(config);
    final imports = _getFlutterImports(config);

    buffer.write(generateImports(imports));

    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}应用状态管理Provider',
      examples: [
        'final provider = $className();',
        'provider.initialize();',
        'provider.updateState(newData);',
      ],
      seeAlso: ['ChangeNotifier', 'Provider'],
    ),);

    buffer.writeln('class $className extends ChangeNotifier {');

    // 生成状态字段
    _generateStateFields(buffer, config);

    // 生成构造函数
    _generateConstructor(buffer, config, className);

    // 生成初始化方法
    _generateInitializeMethod(buffer, config);

    // 生成状态更新方法
    _generateUpdateMethods(buffer, config);

    // 生成清理方法
    _generateDisposeMethod(buffer, config);

    buffer.writeln('}');

    // 生成Provider扩展（如果是企业级）
    if (config.complexity == TemplateComplexity.enterprise) {
      _generateProviderExtensions(buffer, config);
    }
  }

  /// 生成Dart Provider（非Flutter）
  void _generateDartProvider(StringBuffer buffer, ScaffoldConfig config) {
    final className = _getClassName(config);
    final imports = _getDartImports(config);

    buffer.write(generateImports(imports));

    buffer.write(generateClassDocumentation(
      className,
      '${config.templateName}状态管理Provider',
      examples: [
        'final provider = $className();',
        'provider.initialize();',
        'await provider.loadData();',
      ],
    ),);

    buffer.writeln('class $className {');

    // 生成状态字段
    _generateStateFields(buffer, config);

    // 生成构造函数
    _generateConstructor(buffer, config, className);

    // 生成初始化方法
    _generateInitializeMethod(buffer, config);

    // 生成数据加载方法
    _generateDataMethods(buffer, config);

    buffer.writeln('}');
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    return formatClassName(config.templateName, 'Provider');
  }

  /// 获取Flutter导入
  List<String> _getFlutterImports(ScaffoldConfig config) {
    final imports = <String>[
      'package:flutter/foundation.dart',
    ];

    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'dart:async',
        'package:flutter/material.dart',
      ]);
    }

    if (config.complexity == TemplateComplexity.enterprise) {
      imports.addAll([
        'package:provider/provider.dart',
        '../services/${config.templateName}_service.dart',
        '../models/${config.templateName}_model.dart',
      ]);
    }

    return imports;
  }

  /// 获取Dart导入
  List<String> _getDartImports(ScaffoldConfig config) {
    final imports = <String>[
      'dart:async',
    ];

    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'dart:convert',
        '../services/${config.templateName}_service.dart',
      ]);
    }

    return imports;
  }

  /// 生成状态字段
  void _generateStateFields(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 是否已初始化');
    buffer.writeln('  bool _isInitialized = false;');
    buffer.writeln();

    buffer.writeln('  /// 是否正在加载');
    buffer.writeln('  bool _isLoading = false;');
    buffer.writeln();

    buffer.writeln('  /// 错误信息');
    buffer.writeln('  String? _error;');
    buffer.writeln();

    // 根据复杂度添加更多字段
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 数据列表');
      buffer.writeln('  List<Map<String, dynamic>> _data = [];');
      buffer.writeln();

      buffer.writeln('  /// 当前选中项');
      buffer.writeln('  Map<String, dynamic>? _selectedItem;');
      buffer.writeln();
    }

    // Getter方法
    buffer.writeln('  /// 获取初始化状态');
    buffer.writeln('  bool get isInitialized => _isInitialized;');
    buffer.writeln();

    buffer.writeln('  /// 获取加载状态');
    buffer.writeln('  bool get isLoading => _isLoading;');
    buffer.writeln();

    buffer.writeln('  /// 获取错误信息');
    buffer.writeln('  String? get error => _error;');
    buffer.writeln();

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('  /// 获取数据列表');
      buffer.writeln(
          '  List<Map<String, dynamic>> get data => List.unmodifiable(_data);',);
      buffer.writeln();

      buffer.writeln('  /// 获取当前选中项');
      buffer.writeln(
          '  Map<String, dynamic>? get selectedItem => _selectedItem;',);
      buffer.writeln();
    }
  }

  /// 生成构造函数
  void _generateConstructor(
      StringBuffer buffer, ScaffoldConfig config, String className,) {
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  $className();');
    buffer.writeln();
  }

  /// 生成初始化方法
  void _generateInitializeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 初始化Provider');
    buffer.writeln('  Future<void> initialize() async {');
    buffer.writeln('    if (_isInitialized) return;');
    buffer.writeln();
    buffer.writeln('    try {');
    buffer.writeln('      _setLoading(true);');
    buffer.writeln('      _clearError();');
    buffer.writeln();
    buffer.writeln('      // TODO: 添加初始化逻辑');

    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('      await loadData();');
    }

    buffer.writeln();
    buffer.writeln('      _isInitialized = true;');
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      _setError(e.toString());');
    buffer.writeln('    } finally {');
    buffer.writeln('      _setLoading(false);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成更新方法
  void _generateUpdateMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 设置加载状态');
    buffer.writeln('  void _setLoading(bool loading) {');
    buffer.writeln('    if (_isLoading != loading) {');
    buffer.writeln('      _isLoading = loading;');
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('      notifyListeners();');
    }
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 设置错误信息');
    buffer.writeln('  void _setError(String error) {');
    buffer.writeln('    _error = error;');
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('    notifyListeners();');
    }
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 清除错误信息');
    buffer.writeln('  void _clearError() {');
    buffer.writeln('    if (_error != null) {');
    buffer.writeln('      _error = null;');
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('      notifyListeners();');
    }
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成数据方法
  void _generateDataMethods(StringBuffer buffer, ScaffoldConfig config) {
    if (config.complexity == TemplateComplexity.simple) return;

    buffer.writeln('  /// 加载数据');
    buffer.writeln('  Future<void> loadData() async {');
    buffer.writeln('    try {');
    buffer.writeln('      _setLoading(true);');
    buffer.writeln('      _clearError();');
    buffer.writeln();
    buffer.writeln('      // TODO: 实现数据加载逻辑');
    buffer.writeln('      await Future.delayed(const Duration(seconds: 1));');
    buffer.writeln('      _data = [');
    buffer.writeln("        {'id': 1, 'name': '示例数据1'},");
    buffer.writeln("        {'id': 2, 'name': '示例数据2'},");
    buffer.writeln('      ];');
    buffer.writeln();
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('      notifyListeners();');
    }
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      _setError(e.toString());');
    buffer.writeln('    } finally {');
    buffer.writeln('      _setLoading(false);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 选择项目');
    buffer.writeln('  void selectItem(Map<String, dynamic>? item) {');
    buffer.writeln('    if (_selectedItem != item) {');
    buffer.writeln('      _selectedItem = item;');
    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln('      notifyListeners();');
    }
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成清理方法
  void _generateDisposeMethod(StringBuffer buffer, ScaffoldConfig config) {
    if (config.framework != TemplateFramework.flutter) return;

    buffer.writeln('  @override');
    buffer.writeln('  void dispose() {');
    buffer.writeln('    // TODO: 清理资源');
    buffer.writeln('    super.dispose();');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成Provider扩展
  void _generateProviderExtensions(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln();
    buffer.writeln('/// Provider扩展方法');
    buffer.writeln(
        'extension ${_getClassName(config)}Extensions on ${_getClassName(config)} {',);
    buffer.writeln('  /// 重置状态');
    buffer.writeln('  void reset() {');
    buffer.writeln('    _isInitialized = false;');
    buffer.writeln('    _isLoading = false;');
    buffer.writeln('    _error = null;');
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    _data.clear();');
      buffer.writeln('    _selectedItem = null;');
    }
    buffer.writeln('    notifyListeners();');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
