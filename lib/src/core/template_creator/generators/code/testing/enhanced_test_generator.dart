/*
---------------------------------------------------------------
File name:          enhanced_test_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        增强的测试文件生成器
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 增强的测试文件生成器;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/base/base_code_generator.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 增强的测试文件生成器
///
/// 为生成的代码文件创建对应的测试文件
class EnhancedTestGenerator extends BaseCodeGenerator {
  
  /// 创建增强测试生成器实例
  const EnhancedTestGenerator({
    required this.testType,
    required this.targetClassName,
  });
  /// 测试类型
  final TestType testType;
  
  /// 被测试的类名
  final String targetClassName;

  @override
  String getFileName(ScaffoldConfig config) {
    final baseName = config.templateName;
    switch (testType) {
      case TestType.unit:
        return '${baseName}_${targetClassName.toLowerCase()}_test.dart';
      case TestType.integration:
        return '${baseName}_integration_test.dart';
      case TestType.widget:
        return '${baseName}_widget_test.dart';
    }
  }

  @override
  String getRelativePath(ScaffoldConfig config) {
    switch (testType) {
      case TestType.unit:
        return 'test/unit';
      case TestType.integration:
        return 'test/integration';
      case TestType.widget:
        return 'test/widget';
    }
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();
    
    // 添加文件头部注释
    buffer.write(generateFileHeader(
      getFileName(config),
      config,
      '${config.templateName} $targetClassName ${testType.displayName}测试',
    ),);

    final imports = _getImports(config);
    buffer.write(generateImports(imports));
    
    switch (testType) {
      case TestType.unit:
        _generateUnitTest(buffer, config);
      case TestType.integration:
        _generateIntegrationTest(buffer, config);
      case TestType.widget:
        _generateWidgetTest(buffer, config);
    }

    return buffer.toString();
  }

  /// 获取导入
  List<String> _getImports(ScaffoldConfig config) {
    final imports = <String>[
      'package:test/test.dart',
    ];
    
    if (testType == TestType.widget) {
      imports.addAll([
        'package:flutter/material.dart',
        'package:flutter_test/flutter_test.dart',
      ]);
    }
    
    if (config.complexity != TemplateComplexity.simple) {
      imports.addAll([
        'package:mockito/mockito.dart',
        'package:mockito/annotations.dart',
      ]);
    }
    
    // 添加被测试文件的导入
    final targetPath = _getTargetFilePath(config);
    imports.add('package:${config.templateName}/$targetPath');
    
    return imports;
  }

  /// 获取被测试文件的路径
  String _getTargetFilePath(ScaffoldConfig config) {
    switch (targetClassName.toLowerCase()) {
      case 'provider':
        return 'lib/src/providers/${config.templateName}_provider.dart';
      case 'service':
        return 'lib/src/services/${config.templateName}_service.dart';
      case 'model':
        return 'lib/src/models/${config.templateName}_model.dart';
      case 'repository':
        return 'lib/src/repositories/${config.templateName}_repository.dart';
      case 'utils':
        return 'lib/src/utils/${config.templateName}_utils.dart';
      case 'constants':
        return 'lib/src/constants/${config.templateName}_constants.dart';
      default:
        return 'lib/src/${targetClassName.toLowerCase()}/${config.templateName}_${targetClassName.toLowerCase()}.dart';
    }
  }

  /// 生成单元测试
  void _generateUnitTest(StringBuffer buffer, ScaffoldConfig config) {
    final className = formatClassName(config.templateName, targetClassName);
    final testGroupName = '$className 单元测试';
    
    buffer.writeln('void main() {');
    buffer.writeln("  group('$testGroupName', () {");
    buffer.writeln('    late $className ${targetClassName.toLowerCase()};');
    buffer.writeln();
    
    // setUp
    buffer.writeln('    setUp(() {');
    buffer.writeln('      ${targetClassName.toLowerCase()} = $className();');
    buffer.writeln('    });');
    buffer.writeln();
    
    // tearDown
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln('    tearDown(() async {');
      if (targetClassName.toLowerCase() == 'repository' || targetClassName.toLowerCase() == 'service') {
        buffer.writeln('      await ${targetClassName.toLowerCase()}.dispose();');
      }
      buffer.writeln('    });');
      buffer.writeln();
    }
    
    // 生成具体测试用例
    _generateTestCases(buffer, config, className);
    
    buffer.writeln('  });');
    buffer.writeln('}');
  }

  /// 生成测试用例
  void _generateTestCases(StringBuffer buffer, ScaffoldConfig config, String className) {
    switch (targetClassName.toLowerCase()) {
      case 'provider':
        _generateProviderTests(buffer, config, className);
      case 'service':
        _generateServiceTests(buffer, config, className);
      case 'model':
        _generateModelTests(buffer, config, className);
      case 'repository':
        _generateRepositoryTests(buffer, config, className);
      case 'utils':
        _generateUtilsTests(buffer, config, className);
      case 'constants':
        _generateConstantsTests(buffer, config, className);
    }
  }

  /// 生成Provider测试
  void _generateProviderTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln("    test('初始状态应该正确', () {");
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.isInitialized, false);');
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.isLoading, false);');
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.error, null);');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('初始化应该成功', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.isInitialized, true);');
    buffer.writeln('    });');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln("    test('加载数据应该成功', () async {");
      buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
      buffer.writeln('      await ${targetClassName.toLowerCase()}.loadData();');
      buffer.writeln('      expect(${targetClassName.toLowerCase()}.data, isNotEmpty);');
      buffer.writeln('    });');
      buffer.writeln();
      
      buffer.writeln("    test('选择项目应该更新状态', () async {");
      buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
      buffer.writeln('      await ${targetClassName.toLowerCase()}.loadData();');
      buffer.writeln('      final firstItem = ${targetClassName.toLowerCase()}.data.first;');
      buffer.writeln('      ${targetClassName.toLowerCase()}.selectItem(firstItem);');
      buffer.writeln('      expect(${targetClassName.toLowerCase()}.selectedItem, firstItem);');
      buffer.writeln('    });');
      buffer.writeln();
    }
  }

  /// 生成Service测试
  void _generateServiceTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln("    test('初始化应该成功', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.isInitialized, true);');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('获取数据应该返回列表', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      final data = await ${targetClassName.toLowerCase()}.fetchData();');
    buffer.writeln('      expect(data, isA<List<Map<String, dynamic>>>());');
    buffer.writeln('      expect(data, isNotEmpty);');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('根据ID获取数据应该返回正确项目', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      final item = await ${targetClassName.toLowerCase()}.fetchById(1);');
    buffer.writeln('      expect(item, isNotNull);');
    buffer.writeln("      expect(item!['id'], 1);");
    buffer.writeln('    });');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln("    test('创建数据应该成功', () async {");
      buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
      buffer.writeln("      final newData = {'name': '测试项目', 'description': '测试描述'};");
      buffer.writeln('      final created = await ${targetClassName.toLowerCase()}.createData(newData);');
      buffer.writeln('      expect(created, isNotNull);');
      buffer.writeln("      expect(created['name'], '测试项目');");
      buffer.writeln('    });');
      buffer.writeln();
    }
  }

  /// 生成Model测试
  void _generateModelTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln("    test('创建模型实例应该成功', () {");
    buffer.writeln('      final model = $className(');
    buffer.writeln('        id: 1,');
    buffer.writeln("        name: '测试模型',");
    buffer.writeln("        description: '测试描述',");
    buffer.writeln('      );');
    buffer.writeln('      ');
    buffer.writeln('      expect(model.id, 1);');
    buffer.writeln("      expect(model.name, '测试模型');");
    buffer.writeln("      expect(model.description, '测试描述');");
    buffer.writeln('    });');
    buffer.writeln();
    
    if (config.complexity != TemplateComplexity.simple) {
      buffer.writeln("    test('JSON序列化应该正确', () {");
      buffer.writeln('      final model = $className(');
      buffer.writeln('        id: 1,');
      buffer.writeln("        name: '测试模型',");
      buffer.writeln("        description: '测试描述',");
      buffer.writeln('      );');
      buffer.writeln('      ');
      buffer.writeln('      final json = model.toJson();');
      buffer.writeln("      expect(json['id'], 1);");
      buffer.writeln("      expect(json['name'], '测试模型');");
      buffer.writeln('      ');
      buffer.writeln('      final fromJson = $className.fromJson(json);');
      buffer.writeln('      expect(fromJson.id, model.id);');
      buffer.writeln('      expect(fromJson.name, model.name);');
      buffer.writeln('    });');
      buffer.writeln();
      
      buffer.writeln("    test('copyWith应该创建新实例', () {");
      buffer.writeln('      final original = $className(');
      buffer.writeln('        id: 1,');
      buffer.writeln("        name: '原始名称',");
      buffer.writeln('      );');
      buffer.writeln('      ');
      buffer.writeln("      final updated = original.copyWith(name: '更新名称');");
      buffer.writeln('      expect(updated.id, original.id);');
      buffer.writeln("      expect(updated.name, '更新名称');");
      buffer.writeln("      expect(original.name, '原始名称'); // 原实例不变");
      buffer.writeln('    });');
      buffer.writeln();
    }
  }

  /// 生成Repository测试
  void _generateRepositoryTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    buffer.writeln("    test('初始化应该成功', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      expect(${targetClassName.toLowerCase()}.isInitialized, true);');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('创建记录应该成功', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln("      final data = {'name': '测试记录', 'description': '测试描述'};");
    buffer.writeln('      final created = await ${targetClassName.toLowerCase()}.create(data);');
    buffer.writeln('      ');
    buffer.writeln('      expect(created, isNotNull);');
    buffer.writeln("      expect(created['name'], '测试记录');");
    buffer.writeln("      expect(created['id'], isNotNull);");
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('查找记录应该成功', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      final found = await ${targetClassName.toLowerCase()}.findById(1);');
    buffer.writeln('      expect(found, isNotNull);');
    buffer.writeln("      expect(found!['id'], 1);");
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('查找所有记录应该返回列表', () async {");
    buffer.writeln('      await ${targetClassName.toLowerCase()}.initialize();');
    buffer.writeln('      final all = await ${targetClassName.toLowerCase()}.findAll();');
    buffer.writeln('      expect(all, isA<List<Map<String, dynamic>>>());');
    buffer.writeln('    });');
    buffer.writeln();
  }

  /// 生成Utils测试
  void _generateUtilsTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    final validatorClass = formatClassName(config.templateName, 'Validator');
    final formatterClass = formatClassName(config.templateName, 'Formatter');
    
    buffer.writeln("    group('验证器测试', () {");
    buffer.writeln("      test('邮箱验证应该正确', () {");
    buffer.writeln("        expect($validatorClass.isValidEmail('test@example.com'), true);");
    buffer.writeln("        expect($validatorClass.isValidEmail('invalid-email'), false);");
    buffer.writeln('      });');
    buffer.writeln();
    
    buffer.writeln("      test('密码验证应该正确', () {");
    buffer.writeln("        expect($validatorClass.isValidPassword('password123'), true);");
    buffer.writeln("        expect($validatorClass.isValidPassword('123'), false);");
    buffer.writeln('      });');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    group('格式化器测试', () {");
    buffer.writeln("      test('日期格式化应该正确', () {");
    buffer.writeln('        final date = DateTime(2023, 12, 25);');
    buffer.writeln("        expect($formatterClass.formatDate(date), '2023-12-25');");
    buffer.writeln('      });');
    buffer.writeln();
    
    buffer.writeln("      test('文件大小格式化应该正确', () {");
    buffer.writeln("        expect($formatterClass.formatFileSize(1024), '1.0 KB');");
    buffer.writeln("        expect($formatterClass.formatFileSize(1048576), '1.0 MB');");
    buffer.writeln('      });');
    buffer.writeln('    });');
    buffer.writeln();
  }

  /// 生成Constants测试
  void _generateConstantsTests(StringBuffer buffer, ScaffoldConfig config, String className) {
    final appConstantsClass = formatClassName(config.templateName, 'AppConstants');
    final apiConstantsClass = formatClassName(config.templateName, 'ApiConstants');
    
    buffer.writeln("    test('应用常量应该正确定义', () {");
    buffer.writeln('      expect($appConstantsClass.appName, isNotEmpty);');
    buffer.writeln('      expect($appConstantsClass.version, isNotEmpty);');
    buffer.writeln('      expect($appConstantsClass.buildNumber, greaterThan(0));');
    buffer.writeln('    });');
    buffer.writeln();
    
    buffer.writeln("    test('API常量应该正确定义', () {");
    buffer.writeln('      expect($apiConstantsClass.baseUrl, isNotEmpty);');
    buffer.writeln('      expect($apiConstantsClass.endpoints.users, isNotEmpty);');
    buffer.writeln('      expect($apiConstantsClass.headers.contentType, isNotEmpty);');
    buffer.writeln('    });');
    buffer.writeln();
  }

  /// 生成集成测试
  void _generateIntegrationTest(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('void main() {');
    buffer.writeln("  group('${config.templateName} 集成测试', () {");
    buffer.writeln("    test('完整流程测试', () async {");
    buffer.writeln('      // TODO: 实现完整的集成测试流程');
    buffer.writeln('      // 1. 初始化所有组件');
    buffer.writeln('      // 2. 执行业务流程');
    buffer.writeln('      // 3. 验证结果');
    buffer.writeln('    });');
    buffer.writeln('  });');
    buffer.writeln('}');
  }

  /// 生成Widget测试
  void _generateWidgetTest(StringBuffer buffer, ScaffoldConfig config) {
    buffer.writeln('void main() {');
    buffer.writeln("  group('${config.templateName} Widget测试', () {");
    buffer.writeln("    testWidgets('Widget应该正确渲染', (WidgetTester tester) async {");
    buffer.writeln('      // TODO: 实现Widget测试');
    buffer.writeln('      // await tester.pumpWidget(MyWidget());');
    buffer.writeln("      // expect(find.text('Expected Text'), findsOneWidget);");
    buffer.writeln('    });');
    buffer.writeln('  });');
    buffer.writeln('}');
  }
}

/// 测试类型枚举
enum TestType {
  unit('单元'),
  integration('集成'),
  widget('Widget');

  const TestType(this.displayName);
  final String displayName;
}
