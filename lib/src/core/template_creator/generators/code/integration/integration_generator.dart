/*
---------------------------------------------------------------
File name:          integration_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/15
Last modified:      2025/07/15
Dart Version:       3.2+
Description:        集成测试类文件生成器
---------------------------------------------------------------
Change History:
    2025/07/15: Initial creation - 集成测试类文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/scaffold_config.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/utils/string_utils.dart';

/// Integration集成测试类文件生成器
///
/// 生成集成测试类文件
class IntegrationGenerator extends BaseCodeGenerator {
  /// 创建Integration生成器实例
  const IntegrationGenerator();

  @override
  String getFileName(ScaffoldConfig config) {
    return '${config.templateName}_integration.dart';
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    return 'lib/src/integration';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.write(
      generateFileHeader(
        getFileName(config),
        config,
        '${config.templateName}集成测试类',
      ),
    );

    final className = _getClassName(config);
    final imports = _getImports(config);

    buffer.write(generateImports(imports));

    buffer.write(
      generateClassDocumentation(
        className,
        '${config.templateName}集成测试',
        examples: [
          'final integration = $className();',
          'await integration.initialize();',
          'final result = await integration.runTests();',
        ],
      ),
    );

    buffer.writeln('class $className {');

    // 生成字段
    _generateFields(buffer, config);

    // 生成构造函数
    _generateConstructor(buffer, config, className);

    // 生成初始化方法
    _generateInitializeMethod(buffer, config);

    // 生成测试方法
    _generateTestMethods(buffer, config);

    // 生成工具方法
    _generateUtilityMethods(buffer, config);

    buffer.writeln('}');

    return buffer.toString();
  }

  /// 获取类名
  String _getClassName(ScaffoldConfig config) {
    return formatClassName(config.templateName, 'Integration');
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    return [
      'dart:async',
    ];
  }

  /// 生成字段
  void _generateFields(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 是否已初始化');
    buffer.writeln('  bool _isInitialized = false;');
    buffer.writeln();
  }

  /// 生成构造函数
  void _generateConstructor(
      StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln('  /// 创建$className实例');
    buffer.writeln('  $className();');
    buffer.writeln();
  }

  /// 生成初始化方法
  void _generateInitializeMethod(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 初始化集成测试');
    buffer.writeln('  Future<void> initialize() async {');
    buffer.writeln('    if (_isInitialized) return;');
    buffer.writeln('    ');
    buffer.writeln('    // 初始化测试环境');
    buffer.writeln('    await _setupTestEnvironment();');
    buffer.writeln('    ');
    buffer.writeln('    _isInitialized = true;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成测试方法
  void _generateTestMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 运行集成测试');
    buffer.writeln('  Future<bool> runTests() async {');
    buffer.writeln('    if (!_isInitialized) {');
    buffer
        .writeln("      throw StateError('Integration test not initialized');");
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    try {');
    buffer.writeln('      // 运行各种集成测试');
    buffer.writeln('      await _testServiceIntegration();');
    buffer.writeln('      await _testRepositoryIntegration();');
    buffer.writeln('      await _testProviderIntegration();');
    buffer.writeln('      ');
    buffer.writeln('      return true;');
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      return false;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// 生成工具方法
  void _generateUtilityMethods(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('  /// 设置测试环境');
    buffer.writeln('  Future<void> _setupTestEnvironment() async {');
    buffer.writeln('    // 设置测试数据库');
    buffer.writeln('    // 设置测试配置');
    buffer.writeln('    // 初始化测试数据');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 测试服务集成');
    buffer.writeln('  Future<void> _testServiceIntegration() async {');
    buffer.writeln('    // 测试服务层集成');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 测试仓库集成');
    buffer.writeln('  Future<void> _testRepositoryIntegration() async {');
    buffer.writeln('    // 测试仓库层集成');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 测试提供者集成');
    buffer.writeln('  Future<void> _testProviderIntegration() async {');
    buffer.writeln('    // 测试提供者层集成');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 清理测试环境');
    buffer.writeln('  Future<void> cleanup() async {');
    buffer.writeln('    if (!_isInitialized) return;');
    buffer.writeln('    ');
    buffer.writeln('    // 清理测试数据');
    buffer.writeln('    // 关闭测试连接');
    buffer.writeln('    ');
    buffer.writeln('    _isInitialized = false;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// 检查是否已初始化');
    buffer.writeln('  bool get isInitialized => _isInitialized;');
  }
}
