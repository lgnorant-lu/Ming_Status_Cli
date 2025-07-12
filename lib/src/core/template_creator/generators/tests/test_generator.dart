/*
---------------------------------------------------------------
File name:          test_generator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        测试文件生成器 (Test File Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
TODO:
    - [ ] 添加更多测试类型支持
    - [ ] 支持测试数据生成
    - [ ] 添加性能测试生成
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/template_generator_base.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 测试文件生成器
///
/// 负责生成项目的测试文件
class TestGenerator extends TemplateGeneratorBase {
  /// 创建测试生成器实例
  const TestGenerator({
    required this.testType,
    this.targetFile,
  });

  /// 测试类型
  final TestType testType;

  /// 目标文件（用于生成对应的测试文件）
  final String? targetFile;

  @override
  String getTemplateFileName() => '${testType.name}_test.dart.template';

  @override
  String getOutputFileName(ScaffoldConfig config) {
    if (targetFile != null) {
      return '${targetFile!.replaceAll('.dart', '')}_test.dart.template';
    }
    return '${testType.name}_test.dart.template';
  }

  @override
  String generateContent(ScaffoldConfig config) {
    final buffer = StringBuffer();

    // 添加文件头部注释
    buffer.writeln(generateFileHeader(
      getOutputFileName(config).replaceAll('.template', ''),
      config,
      '${config.templateName}${testType.displayName}测试',
    ),);

    // 根据测试类型生成不同的内容
    switch (testType) {
      case TestType.unit:
        _generateUnitTest(buffer, config);
      case TestType.widget:
        _generateWidgetTest(buffer, config);
      case TestType.integration:
        _generateIntegrationTest(buffer, config);
      case TestType.golden:
        _generateGoldenTest(buffer, config);
      case TestType.performance:
        _generatePerformanceTest(buffer, config);
    }

    return buffer.toString();
  }

  /// 生成单元测试
  void _generateUnitTest(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln("import 'package:test/test.dart';")
      ..writeln("import 'package:mockito/mockito.dart';")
      ..writeln("import 'package:mockito/annotations.dart';");

    if (config.framework == TemplateFramework.flutter) {
      buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    }

    buffer
      ..writeln()
      ..writeln("import 'package:${config.templateName}/${config.templateName}.dart';");

    if (targetFile != null) {
      final importPath = targetFile!.replaceAll('lib/', '').replaceAll('.dart', '.dart');
      buffer.writeln("import 'package:${config.templateName}/$importPath';");
    }

    buffer
      ..writeln()
      ..writeln('// Mock类生成注解')
      ..writeln('@GenerateMocks([')
      ..writeln('  // 在这里添加需要Mock的类')
      ..writeln('  // ExampleService,')
      ..writeln('  // ExampleRepository,')
      ..writeln('])')
      ..writeln()
      ..writeln("import '${getOutputFileName(config).replaceAll('.dart.template', '.mocks.dart')}';")
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  group('${_getTestGroupName(config)}', () {")
      ..writeln('    late MockExampleService mockService;')
      ..writeln('    late ExampleClass exampleClass;')
      ..writeln()
      ..writeln('    setUp(() {')
      ..writeln('      mockService = MockExampleService();')
      ..writeln('      exampleClass = ExampleClass(service: mockService);')
      ..writeln('    });')
      ..writeln()
      ..writeln('    tearDown(() {')
      ..writeln('      // 清理资源')
      ..writeln('    });')
      ..writeln()
      ..writeln("    test('should return expected result when method is called', () {")
      ..writeln('      // Arrange')
      ..writeln("      const expectedResult = 'expected';")
      ..writeln('      when(mockService.getData()).thenReturn(expectedResult);')
      ..writeln()
      ..writeln('      // Act')
      ..writeln('      final result = exampleClass.processData();')
      ..writeln()
      ..writeln('      // Assert')
      ..writeln('      expect(result, equals(expectedResult));')
      ..writeln('      verify(mockService.getData()).called(1);')
      ..writeln('    });')
      ..writeln()
      ..writeln("    test('should throw exception when invalid input is provided', () {")
      ..writeln('      // Arrange')
      ..writeln("      when(mockService.getData()).thenThrow(Exception('Invalid input'));")
      ..writeln()
      ..writeln('      // Act & Assert')
      ..writeln('      expect(')
      ..writeln('        () => exampleClass.processData(),')
      ..writeln('        throwsA(isA<Exception>()),')
      ..writeln('      );')
      ..writeln('    });')
      ..writeln()
      ..writeln("    group('边界条件测试', () {")
      ..writeln("      test('should handle null input correctly', () {")
      ..writeln('        // TODO: 实现null输入测试')
      ..writeln('      });')
      ..writeln()
      ..writeln("      test('should handle empty input correctly', () {")
      ..writeln('        // TODO: 实现空输入测试')
      ..writeln('      });')
      ..writeln('    });')
      ..writeln('  });')
      ..writeln('}')
      ..writeln()
      ..writeln('// 示例类（实际使用时请替换为真实的类）')
      ..writeln('class ExampleClass {')
      ..writeln('  const ExampleClass({required this.service});')
      ..writeln()
      ..writeln('  final ExampleService service;')
      ..writeln()
      ..writeln('  String processData() {')
      ..writeln('    return service.getData();')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('// 示例服务接口')
      ..writeln('abstract class ExampleService {')
      ..writeln('  String getData();')
      ..writeln('}');
  }

  /// 生成Widget测试
  void _generateWidgetTest(StringBuffer buffer, ScaffoldConfig config) {
    if (config.framework != TemplateFramework.flutter) {
      _generateUnitTest(buffer, config);
      return;
    }

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';")
      ..writeln("import 'package:mockito/mockito.dart';")
      ..writeln("import 'package:mockito/annotations.dart';")
      ..writeln()
      ..writeln("import 'package:${config.templateName}/src/app.dart';");

    if (targetFile != null) {
      final importPath = targetFile!.replaceAll('lib/', '').replaceAll('.dart', '.dart');
      buffer.writeln("import 'package:${config.templateName}/$importPath';");
    }

    buffer
      ..writeln()
      ..writeln('// Mock类生成注解')
      ..writeln('@GenerateMocks([')
      ..writeln('  // 在这里添加需要Mock的类')
      ..writeln('  // ExampleService,')
      ..writeln('])')
      ..writeln()
      ..writeln("import '${getOutputFileName(config).replaceAll('.dart.template', '.mocks.dart')}';")
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  group('${_getTestGroupName(config)} Widget Tests', () {")
      ..writeln("    testWidgets('should display expected UI elements', (tester) async {")
      ..writeln('      // Arrange')
      ..writeln('      await tester.pumpWidget(')
      ..writeln('        const ProviderScope(')
      ..writeln('          child: MaterialApp(')
      ..writeln('            home: ExampleWidget(),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      // Act')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // Assert')
      ..writeln("      expect(find.text('Expected Text'), findsOneWidget);")
      ..writeln('      expect(find.byType(ElevatedButton), findsOneWidget);')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('should respond to user interactions', (tester) async {")
      ..writeln('      // Arrange')
      ..writeln('      await tester.pumpWidget(')
      ..writeln('        const ProviderScope(')
      ..writeln('          child: MaterialApp(')
      ..writeln('            home: ExampleWidget(),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      // Act')
      ..writeln('      await tester.tap(find.byType(ElevatedButton));')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // Assert')
      ..writeln("      expect(find.text('Button Pressed'), findsOneWidget);")
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('should handle loading states correctly', (tester) async {")
      ..writeln('      // TODO: 实现加载状态测试')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('should handle error states correctly', (tester) async {")
      ..writeln('      // TODO: 实现错误状态测试')
      ..writeln('    });')
      ..writeln('  });')
      ..writeln('}')
      ..writeln()
      ..writeln('// 示例Widget（实际使用时请替换为真实的Widget）')
      ..writeln('class ExampleWidget extends StatelessWidget {')
      ..writeln('  const ExampleWidget({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return Scaffold(')
      ..writeln('      appBar: AppBar(')
      ..writeln("        title: const Text('Example Widget'),")
      ..writeln('      ),')
      ..writeln('      body: const Center(')
      ..writeln('        child: Column(')
      ..writeln('          mainAxisAlignment: MainAxisAlignment.center,')
      ..writeln('          children: [')
      ..writeln("            Text('Expected Text'),")
      ..writeln('            SizedBox(height: 16),')
      ..writeln('            ElevatedButton(')
      ..writeln('              onPressed: null,')
      ..writeln("              child: Text('Test Button'),")
      ..writeln('            ),')
      ..writeln('          ],')
      ..writeln('        ),')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');
  }

  /// 生成集成测试
  void _generateIntegrationTest(StringBuffer buffer, ScaffoldConfig config) {
    if (config.framework != TemplateFramework.flutter) {
      _generateUnitTest(buffer, config);
      return;
    }

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln("import 'package:integration_test/integration_test.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';")
      ..writeln()
      ..writeln("import 'package:${config.templateName}/main.dart' as app;")
      ..writeln()
      ..writeln('void main() {')
      ..writeln('  IntegrationTestWidgetsFlutterBinding.ensureInitialized();')
      ..writeln()
      ..writeln("  group('${_getTestGroupName(config)} Integration Tests', () {")
      ..writeln("    testWidgets('complete user flow test', (tester) async {")
      ..writeln('      // 启动应用')
      ..writeln('      app.main();')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // 验证初始状态')
      ..writeln("      expect(find.text('Welcome'), findsOneWidget);")
      ..writeln()
      ..writeln('      // 执行用户操作')
      ..writeln("      await tester.tap(find.text('Get Started'));")
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // 验证导航结果')
      ..writeln("      expect(find.text('Home'), findsOneWidget);")
      ..writeln()
      ..writeln('      // 测试设置页面')
      ..writeln('      await tester.tap(find.byIcon(Icons.settings));')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln("      expect(find.text('Settings'), findsOneWidget);")
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('theme switching test', (tester) async {")
      ..writeln('      app.main();')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // 导航到设置页面')
      ..writeln('      await tester.tap(find.byIcon(Icons.settings));')
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // 切换主题')
      ..writeln("      await tester.tap(find.text('Dark Mode'));")
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      // 验证主题变化')
      ..writeln('      // TODO: 添加主题验证逻辑')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('data persistence test', (tester) async {")
      ..writeln('      // TODO: 实现数据持久化测试')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('network connectivity test', (tester) async {")
      ..writeln('      // TODO: 实现网络连接测试')
      ..writeln('    });')
      ..writeln('  });')
      ..writeln('}');
  }

  /// 生成Golden测试
  void _generateGoldenTest(StringBuffer buffer, ScaffoldConfig config) {
    if (config.framework != TemplateFramework.flutter) {
      _generateUnitTest(buffer, config);
      return;
    }

    buffer
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln("import 'package:flutter_test/flutter_test.dart';")
      ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';")
      ..writeln()
      ..writeln("import 'package:${config.templateName}/src/app.dart';")
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  group('${_getTestGroupName(config)} Golden Tests', () {")
      ..writeln("    testWidgets('home screen golden test', (tester) async {")
      ..writeln('      await tester.pumpWidget(')
      ..writeln('        const ProviderScope(')
      ..writeln('          child: MaterialApp(')
      ..writeln('            home: HomeScreen(),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      await expectLater(')
      ..writeln('        find.byType(MaterialApp),')
      ..writeln("        matchesGoldenFile('golden/home_screen.png'),")
      ..writeln('      );')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('settings screen golden test', (tester) async {")
      ..writeln('      await tester.pumpWidget(')
      ..writeln('        const ProviderScope(')
      ..writeln('          child: MaterialApp(')
      ..writeln('            home: SettingsScreen(),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      await expectLater(')
      ..writeln('        find.byType(MaterialApp),')
      ..writeln("        matchesGoldenFile('golden/settings_screen.png'),")
      ..writeln('      );')
      ..writeln('    });')
      ..writeln()
      ..writeln("    testWidgets('dark theme golden test', (tester) async {")
      ..writeln('      await tester.pumpWidget(')
      ..writeln('        ProviderScope(')
      ..writeln('          child: MaterialApp(')
      ..writeln('            theme: ThemeData.dark(),')
      ..writeln('            home: const HomeScreen(),')
      ..writeln('          ),')
      ..writeln('        ),')
      ..writeln('      );')
      ..writeln()
      ..writeln('      await tester.pumpAndSettle();')
      ..writeln()
      ..writeln('      await expectLater(')
      ..writeln('        find.byType(MaterialApp),')
      ..writeln("        matchesGoldenFile('golden/home_screen_dark.png'),")
      ..writeln('      );')
      ..writeln('    });')
      ..writeln('  });')
      ..writeln('}')
      ..writeln()
      ..writeln('// 示例Screen类（实际使用时请替换为真实的Screen）')
      ..writeln('class HomeScreen extends StatelessWidget {')
      ..writeln('  const HomeScreen({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return const Scaffold(')
      ..writeln('      body: Center(')
      ..writeln("        child: Text('Home Screen'),")
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}')
      ..writeln()
      ..writeln('class SettingsScreen extends StatelessWidget {')
      ..writeln('  const SettingsScreen({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return const Scaffold(')
      ..writeln('      body: Center(')
      ..writeln("        child: Text('Settings Screen'),")
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');
  }

  /// 生成性能测试
  void _generatePerformanceTest(StringBuffer buffer, ScaffoldConfig config) {
    buffer
      ..writeln()
      ..writeln("import 'package:test/test.dart';");

    if (config.framework == TemplateFramework.flutter) {
      buffer
        ..writeln("import 'package:flutter/material.dart';")
        ..writeln("import 'package:flutter_test/flutter_test.dart';")
        ..writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    }

    buffer
      ..writeln()
      ..writeln("import 'package:${config.templateName}/${config.templateName}.dart';")
      ..writeln()
      ..writeln('void main() {')
      ..writeln("  group('${_getTestGroupName(config)} Performance Tests', () {")
      ..writeln("    test('should complete operation within time limit', () async {")
      ..writeln('      // Arrange')
      ..writeln('      const timeLimit = Duration(milliseconds: 100);')
      ..writeln('      final stopwatch = Stopwatch()..start();')
      ..writeln()
      ..writeln('      // Act')
      ..writeln('      await performExpensiveOperation();')
      ..writeln('      stopwatch.stop();')
      ..writeln()
      ..writeln('      // Assert')
      ..writeln('      expect(stopwatch.elapsed, lessThan(timeLimit));')
      ..writeln('    });')
      ..writeln()
      ..writeln("    test('should handle large data sets efficiently', () async {")
      ..writeln('      // Arrange')
      ..writeln('      final largeDataSet = List.generate(10000, (index) => index);')
      ..writeln('      final stopwatch = Stopwatch()..start();')
      ..writeln()
      ..writeln('      // Act')
      ..writeln('      final result = processLargeDataSet(largeDataSet);')
      ..writeln('      stopwatch.stop();')
      ..writeln()
      ..writeln('      // Assert')
      ..writeln('      expect(result, isNotNull);')
      ..writeln('      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));')
      ..writeln('    });')
      ..writeln()
      ..writeln("    test('memory usage should remain stable', () async {")
      ..writeln('      // TODO: 实现内存使用测试')
      ..writeln('      // 可以使用 dart:developer 的 Timeline 或其他工具')
      ..writeln('    });')
      ..writeln('  });')
      ..writeln('}')
      ..writeln()
      ..writeln('// 示例性能测试函数')
      ..writeln('Future<void> performExpensiveOperation() async {')
      ..writeln('  // 模拟耗时操作')
      ..writeln('  await Future.delayed(const Duration(milliseconds: 50));')
      ..writeln('}')
      ..writeln()
      ..writeln('List<int> processLargeDataSet(List<int> data) {')
      ..writeln('  // 模拟大数据集处理')
      ..writeln('  return data.where((item) => item % 2 == 0).toList();')
      ..writeln('}');
  }

  /// 获取测试组名称
  String _getTestGroupName(ScaffoldConfig config) {
    if (targetFile != null) {
      final fileName = targetFile!.split('/').last.replaceAll('.dart', '');
      return fileName;
    }
    return config.templateName;
  }
}

/// 测试类型枚举
enum TestType {
  /// 单元测试
  unit('unit', '单元'),
  /// Widget测试
  widget('widget', 'Widget'),
  /// 集成测试
  integration('integration', '集成'),
  /// Golden测试
  golden('golden', 'Golden'),
  /// 性能测试
  performance('performance', '性能');

  const TestType(this.name, this.displayName);

  /// 类型名称
  final String name;

  /// 显示名称
  final String displayName;
}
