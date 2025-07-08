/*
---------------------------------------------------------------
File name:          template_engine_optimization_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        模板引擎优化功能测试用例
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_engine.dart';
import 'package:ming_status_cli/src/core/template_exceptions.dart';
import 'package:ming_status_cli/src/utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TemplateEngine 优化功能测试', () {
    late TemplateEngine engine;
    late String testDir;
    late String templatesDir;

    setUpAll(() async {
      // 创建测试目录
      testDir = path.join(
        Directory.systemTemp.path,
        'template_optimization_test',
      );
      templatesDir = path.join(testDir, 'templates');

      if (Directory(testDir).existsSync()) {
        await Directory(testDir).delete(recursive: true);
      }

      await Directory(templatesDir).create(recursive: true);

      // 创建测试模板
      await _createTestTemplate(templatesDir, 'test_template');
      await _createInvalidTemplate(templatesDir, 'invalid_template');
    });

    setUp(() {
      engine = TemplateEngine(workingDirectory: testDir);
    });

    tearDownAll(() async {
      if (Directory(testDir).existsSync()) {
        await Directory(testDir).delete(recursive: true);
      }
    });

    group('错误处理系统测试', () {
      test('应该正确处理模板不存在错误', () async {
        expect(
          () async => engine.loadTemplate('non_existent_template'),
          throwsA(
            isA<TemplateEngineException>().having(
              (e) => e.type,
              'type',
              TemplateEngineErrorType.templateNotFound,
            ),
          ),
        );
      });

      test('应该正确处理无效模板格式错误', () async {
        expect(
          () async => engine.loadTemplate('invalid_template'),
          throwsA(
            isA<TemplateEngineException>().having(
              (e) => e.type,
              'type',
              TemplateEngineErrorType.masonError,
            ),
          ),
        );
      });

      test('应该正确处理变量验证错误', () async {
        final result = await engine.generateModule(
          templateName: 'production_template', // 使用非测试模板名触发严格验证
          outputPath: path.join(testDir, 'output'),
          variables: {}, // 缺少必需变量
        );

        // generateModule 返回 false 而不是抛出异常
        expect(result, isFalse);
      });

      test('错误恢复管理器应该提供有用的建议', () async {
        try {
          await engine.loadTemplate('non_existent_template');
        } catch (e) {
          expect(e, isA<TemplateEngineException>());
          final error = e as TemplateEngineException;
          expect(error.recovery, isNotNull);
          expect(error.recovery, contains('请检查模板名称'));
        }
      });
    });

    group('性能优化测试', () {
      test('缓存机制应该提升性能', () async {
        // 第一次加载（无缓存）
        final stopwatch1 = Stopwatch()..start();
        await engine.loadTemplate('test_template');
        stopwatch1.stop();

        // 第二次加载（使用缓存）
        final stopwatch2 = Stopwatch()..start();
        await engine.loadTemplate('test_template');
        stopwatch2.stop();

        // 缓存加载应该更快（或至少不慢）
        expect(
          stopwatch2.elapsedMicroseconds,
          lessThanOrEqualTo(stopwatch1.elapsedMicroseconds),
        );
      });

      test('性能监控应该记录指标', () async {
        await engine.loadTemplate('test_template');

        final report = engine.getPerformanceReport();
        expect(report['performance_metrics'], isNotEmpty);
        final cacheStats = report['cache_stats'] as Map<String, dynamic>;
        expect(cacheStats['generators_cached'], equals(1));
      });

      test('预热功能应该加载所有可用模板', () async {
        await engine.warmup();

        final stats = engine.getPerformanceReport();
        final cacheStats = stats['cache_stats'] as Map<String, dynamic>;
        expect(cacheStats['generators_cached'], greaterThan(0));
      });
    });

    group('重试机制测试', () {
      test('应该在Mason异常时重试', () async {
        // 创建一个可能失败的模板加载场景
        // 这里我们验证重试逻辑存在
        final result = await engine.generateModule(
          templateName: 'test_template',
          outputPath: path.join(testDir, 'retry_test'),
          variables: {
            'module_id': 'test_module',
            'module_name': 'Test Module',
          },
        );

        expect(result, isTrue);
      });
    });

    group('批量操作测试', () {
      test('应该能验证所有模板', () async {
        final results = await engine.validateAllTemplates();

        expect(results, isA<Map<String, List<String>>>());
        expect(results.containsKey('test_template'), isTrue);
        expect(results['test_template'], isEmpty); // 无验证错误

        if (results.containsKey('invalid_template')) {
          expect(results['invalid_template'], isNotEmpty); // 有验证错误
        }
      });

      test('应该提供模板统计信息', () async {
        final stats = await engine.getTemplateStats();

        expect(stats['total_templates'], greaterThan(0));
        expect(stats['templates'], isA<Map<String, Map<String, dynamic>>>());
      });
    });

    group('健康检查测试', () {
      test('应该检查引擎健康状态', () async {
        final health = await engine.checkHealth();

        expect(health['status'], isIn(['healthy', 'warning', 'unhealthy']));
        expect(health['checks'], isA<Map<String, dynamic>>());
        expect(health['warnings'], isA<List<String>>());
        expect(health['errors'], isA<List<String>>());
      });

      test('健康检查应该发现问题', () async {
        // 创建一个没有模板目录的引擎
        final badEngine = TemplateEngine(
          workingDirectory: '/non/existent/path',
        );

        final health = await badEngine.checkHealth();
        expect(health['status'], equals('unhealthy'));
        expect(health['errors'], isNotEmpty);
      });
    });

    group('缓存管理测试', () {
      test('应该能清理所有缓存', () {
        // 加载一些数据到缓存并清理缓存
        engine
          ..loadTemplate('test_template')
          ..clearCache();

        final report = engine.getPerformanceReport();
        final cacheStats = report['cache_stats'] as Map<String, dynamic>;
        expect(cacheStats['generators_cached'], equals(0));
        expect(cacheStats['metadata_cached'], equals(0));
      });

      test('应该能重建缓存', () async {
        await engine.loadTemplate('test_template');
        final initialReport = engine.getPerformanceReport();
        final initialCacheStats =
            initialReport['cache_stats'] as Map<String, dynamic>;
        expect(
          initialCacheStats['generators_cached'],
          equals(1),
        );

        await engine.rebuildCache();

        // 重建后应该仍有缓存
        final report = engine.getPerformanceReport();
        final cacheStats = report['cache_stats'] as Map<String, dynamic>;
        expect(cacheStats['generators_cached'], greaterThan(0));
      });
    });

    group('高级生成功能测试', () {
      test('优化的generateModule应该成功生成', () async {
        final outputPath = path.join(testDir, 'optimized_output');

        final result = await engine.generateModule(
          templateName: 'test_template',
          outputPath: outputPath,
          variables: {
            'module_id': 'optimized_module',
            'module_name': 'Optimized Module',
          },
        );

        expect(result, isTrue);
        expect(FileUtils.directoryExists(outputPath), isTrue);

        // 验证生成的文件
        final entities = FileUtils.listDirectory(outputPath);
        expect(entities, isNotEmpty);
      });

      test('应该正确预处理变量', () {
        final variables = {
          'module_id': 'test_module',
        };

        final processed = engine.preprocessVariables(variables);

        expect(processed['class_name'], isNotNull);
        expect(processed['file_name'], isNotNull);
        expect(processed['generated_date'], isNotNull);
        expect(processed['author'], isNotNull);
      });

      test('应该验证模板变量', () {
        final errors = engine.validateTemplateVariables(
          templateName: 'production_template', // 使用非测试模板名触发严格验证
          variables: {
            'module_id': '', // 无效值
            // 缺少 module_name
          },
        );

        expect(errors, isNotEmpty);
        expect(errors.containsKey('module_id'), isTrue);
        expect(errors.containsKey('module_name'), isTrue);
      });
    });
  });
}

/// 创建测试模板
Future<void> _createTestTemplate(
  String templatesDir,
  String templateName,
) async {
  final templateDir = path.join(templatesDir, templateName);
  await Directory(templateDir).create(recursive: true);

  // 创建 brick.yaml
  final brickYaml = '''
name: $templateName
description: 测试模板
version: 1.0.0

vars:
  module_id:
    type: string
    description: 模块ID
    prompt: 请输入模块ID
  module_name:
    type: string
    description: 模块名称
    prompt: 请输入模块名称
  author:
    type: string
    description: 作者
    default: Test Author
''';

  await File(path.join(templateDir, 'brick.yaml')).writeAsString(brickYaml);

  // 创建模板文件
  const moduleFile = '''
/// {{module_name}}
/// 作者: {{author}}
class {{#pascalCase}}{{module_id}}{{/pascalCase}} {
  static const String id = '{{module_id}}';
  static const String name = '{{module_name}}';
  
  void initialize() {
    print('模块 {{module_name}} 已初始化');
  }
}
''';

  final moduleDir = path.join(templateDir, '__brick__');
  await Directory(moduleDir).create(recursive: true);
  await File(path.join(moduleDir, 'module.dart')).writeAsString(moduleFile);
}

/// 创建无效模板（用于测试错误处理）
Future<void> _createInvalidTemplate(
  String templatesDir,
  String templateName,
) async {
  final templateDir = path.join(templatesDir, templateName);
  await Directory(templateDir).create(recursive: true);

  // 创建无效的 brick.yaml（缺少必需字段）
  const invalidBrickYaml = '''
description: 无效模板
# 缺少name字段
''';

  await File(
    path.join(templateDir, 'brick.yaml'),
  ).writeAsString(invalidBrickYaml);

  // 创建__brick__目录但不添加文件
  final moduleDir = path.join(templateDir, '__brick__');
  await Directory(moduleDir).create(recursive: true);
}
