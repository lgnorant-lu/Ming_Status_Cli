/*
---------------------------------------------------------------
File name:          template_performance_test.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        Task 34.4 模板性能和错误场景测试 (Template performance tests)
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:test/test.dart';

import '../integration/cli_test_helper.dart';

void main() {
  group('Task 34.4: 模板生成性能和错误场景测试', () {
    late Directory tempTestDir;

    setUpAll(() async {
      await CliTestHelper.setUpAll();
    });

    setUp(() async {
      tempTestDir =
          Directory.systemTemp.createTempSync('ming_performance_test');
    });

    tearDown(() async {
      if (tempTestDir.existsSync()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    tearDownAll(() async {
      await CliTestHelper.tearDownAll();
    });

    group('命令行性能测试', () {
      test('帮助命令应该快速响应', () async {
        final startTime = DateTime.now();

        final result = await CliTestHelper.runCommand([
          'help',
          'create',
        ]);

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        CliTestHelper.expectSuccess(result);
        expect(
          duration,
          lessThan(const Duration(seconds: 10)),
          reason: '帮助命令应该在10秒内完成，实际用时: ${duration.inSeconds}秒',
        );
        expect(result.stdout, contains('create'));
      });

      test('版本命令应该快速响应', () async {
        final startTime = DateTime.now();

        final result = await CliTestHelper.runCommand([
          'version',
        ]);

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        CliTestHelper.expectSuccess(result);
        expect(
          duration,
          lessThan(const Duration(seconds: 10)),
          reason: '版本命令应该在10秒内完成，实际用时: ${duration.inSeconds}秒',
        );
      });

      test('doctor命令应该在合理时间内完成', () async {
        final startTime = DateTime.now();

        final result = await CliTestHelper.runCommand([
          'doctor',
        ]);

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // doctor命令可能成功或失败，取决于环境，但不应该超时
        expect(result.exitCode, isNot(equals(-1)), reason: '命令不应该超时');
        expect(
          duration,
          lessThan(const Duration(seconds: 15)),
          reason: 'doctor命令应该在15秒内完成，实际用时: ${duration.inSeconds}秒',
        );
      });
    });

    group('错误场景测试', () {
      test('应该优雅处理不存在的模板', () async {
        final result = await CliTestHelper.runCommand([
          'create',
          'invalid_template_test',
          '--template',
          'non_existent_template',
          '--output',
          tempTestDir.path,
        ]);

        CliTestHelper.expectFailure(result);
        expect(result.stderr, contains('不存在'));
      });

      test('应该处理无效命令', () async {
        final result = await CliTestHelper.runCommand([
          'invalid_command',
        ]);

        CliTestHelper.expectFailure(result);
        expect(
          result.stderr.toLowerCase(),
          anyOf([
            contains('could not find'),
            contains('unknown'),
            contains('unrecognized'),
            contains('无效'),
            contains('找不到'),
          ]),
        );
      });

      test('应该处理缺少必需参数的create命令', () async {
        final result = await CliTestHelper.runCommand([
          'create',
          // 缺少项目名称
          '--template', 'basic',
        ]);

        CliTestHelper.expectFailure(result);
        // 命令应该快速失败，而不是等待交互输入
        expect(
          result.duration.inSeconds,
          lessThan(15),
          reason: '参数错误应该快速失败',
        );
      });
    });

    group('配置系统性能测试', () {
      test('配置列表命令应该快速响应', () async {
        final startTime = DateTime.now();

        final result = await CliTestHelper.runCommand([
          'config',
          '--list',
        ]);

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // 配置命令可能成功或失败，取决于环境
        expect(result.exitCode, isNot(equals(-1)), reason: '配置命令不应该超时');
        expect(
          duration,
          lessThan(const Duration(seconds: 10)),
          reason: '配置列表应该在10秒内完成，实际用时: ${duration.inSeconds}秒',
        );
      });
    });

    group('命令行参数解析测试', () {
      test('应该处理无效的全局选项', () async {
        final result = await CliTestHelper.runCommand([
          '--invalid-option',
        ]);

        CliTestHelper.expectFailure(result);
        expect(
          result.duration.inSeconds,
          lessThan(10),
          reason: '无效选项应该快速失败',
        );
      });

      test('应该处理help选项', () async {
        final result = await CliTestHelper.runCommand([
          '--help',
        ]);

        CliTestHelper.expectSuccess(result);
        expect(result.stdout, contains('Ming Status CLI'));
        expect(
          result.duration.inSeconds,
          lessThan(10),
          reason: '--help应该快速响应',
        );
      });

      test('应该处理version选项', () async {
        final result = await CliTestHelper.runCommand([
          '--version',
        ]);

        CliTestHelper.expectSuccess(result);
        expect(
          result.duration.inSeconds,
          lessThan(10),
          reason: '--version应该快速响应',
        );
      });
    });

    group('资源利用率测试', () {
      test('多次快速命令执行应该稳定', () async {
        const iterations = 5;
        final durations = <Duration>[];

        for (var i = 0; i < iterations; i++) {
          final startTime = DateTime.now();

          final result = await CliTestHelper.runCommand([
            'version',
          ]);

          final endTime = DateTime.now();
          durations.add(endTime.difference(startTime));

          CliTestHelper.expectSuccess(result);
        }

        final avgDuration = Duration(
          milliseconds:
              durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b) ~/
                  iterations,
        );

        expect(
          avgDuration,
          lessThan(const Duration(seconds: 10)),
          reason: '平均响应时间应该在10秒内，实际: ${avgDuration.inSeconds}秒',
        );

        // 检查没有内存泄漏迹象 - 响应时间应该相对稳定
        final maxDuration = durations.reduce((a, b) => a > b ? a : b);
        final minDuration = durations.reduce((a, b) => a < b ? a : b);
        final variance =
            maxDuration.inMilliseconds - minDuration.inMilliseconds;

        expect(
          variance, lessThan(5000), // 5秒差异
          reason: '响应时间方差应该较小，表明没有明显的性能退化',
        );
      });
    });

    group('并发执行测试', () {
      test('并发版本查询应该正常工作', () async {
        // 测试多个并发查询
        final futures = <Future<CliTestResult>>[];

        for (var i = 0; i < 3; i++) {
          futures.add(CliTestHelper.runCommand(['version']));
        }

        final results = await Future.wait(futures);

        for (final result in results) {
          CliTestHelper.expectSuccess(result);
          expect(
            result.duration.inSeconds,
            lessThan(15),
            reason: '并发执行不应该显著影响性能',
          );
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    });
  });
}
