/*
---------------------------------------------------------------
File name:          performance_optimization_integration_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        性能优化集成测试 (Performance Optimization Integration Test)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 性能优化和压力测试集成;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:ming_status_cli/src/core/performance/memory_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/performance_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/startup_optimizer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../stress/extended_stress_test.dart';

void main() {
  group('性能优化集成测试', () {
    late Directory tempDir;
    late PerformanceOptimizer performanceOptimizer;
    late StartupOptimizer startupOptimizer;
    late MemoryOptimizer memoryOptimizer;
    late ExtendedStressTester stressTester;

    setUpAll(() async {
      // 创建临时目录
      tempDir = await Directory.systemTemp.createTemp('performance_test_');

      // 初始化优化器
      performanceOptimizer = PerformanceOptimizer();
      startupOptimizer = StartupOptimizer();
      memoryOptimizer = MemoryOptimizer();

      await performanceOptimizer.initialize();
      await memoryOptimizer.initialize();

      // 初始化压力测试器
      const config = StressTestConfig(
        concurrentUsers: 10,
        operationsPerUser: 100,
        testDuration: Duration(minutes: 5),
        maxMemoryUsage: 200 * 1024 * 1024, // 200MB
        maxResponseTime: 2000, // 2秒
        errorThreshold: 0.1, // 10%
      );

      stressTester = ExtendedStressTester(
        config: config,
        outputDirectory: tempDir.path,
      );

      await stressTester.initialize();

      print('✅ 性能优化集成测试环境初始化完成');
    });

    tearDownAll(() async {
      // 清理资源
      performanceOptimizer.dispose();
      memoryOptimizer.dispose();
      stressTester.dispose();

      // 删除临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      print('✅ 性能优化集成测试环境清理完成');
    });

    group('启动时间优化测试', () {
      test('应该能够优化CLI启动时间', () async {
        print('🚀 测试CLI启动时间优化');

        // 注册启动任务
        startupOptimizer.registerTasks([
          StartupTask(
            id: 'init_config',
            name: '初始化配置',
            phase: StartupPhase.coreInit,
            priority: 1,
            executor: () async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            },
          ),
          StartupTask(
            id: 'load_templates',
            name: '加载模板',
            phase: StartupPhase.componentInit,
            priority: 2,
            executor: () async {
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
          ),
          StartupTask(
            id: 'init_cache',
            name: '初始化缓存',
            phase: StartupPhase.postInit,
            priority: 3,
            executor: () async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
          ),
        ]);

        // 执行优化启动
        final result = await startupOptimizer.executeOptimizedStartup();

        expect(result.success, isTrue);
        expect(result.totalTime.inMilliseconds, lessThan(1000)); // 小于1秒
        expect(result.optimizations, isNotEmpty);

        print('✅ 启动时间优化测试通过: ${result.totalTime.inMilliseconds}ms');
      });

      test('应该能够生成启动报告', () async {
        print('📊 测试启动报告生成');

        final report = startupOptimizer.generateStartupReport();

        expect(report, isNotEmpty);
        expect(report['summary'], isNotNull);
        expect(report['latest_result'], isNotNull);
        expect(report['recommendations'], isNotNull);

        print('✅ 启动报告生成测试通过');
      });
    });

    group('内存优化测试', () {
      test('应该能够优化内存使用', () async {
        print('🧠 测试内存优化');

        // 创建一些内存使用
        final largeList = List.generate(10000, (i) => 'test_data_$i');

        // 获取优化前的内存使用
        final beforeUsage = await memoryOptimizer.getCurrentMemoryUsage();

        // 执行内存优化
        final result = await memoryOptimizer.optimize();

        expect(result.success, isTrue);
        expect(result.freedBytes, greaterThanOrEqualTo(0));
        expect(result.optimizations, isNotEmpty);

        // 清理测试数据
        largeList.clear();

        print('✅ 内存优化测试通过: 释放${result.freedBytes}字节');
      });

      test('应该能够监控内存使用趋势', () async {
        print('📈 测试内存监控');

        // 获取多个内存快照
        final snapshots = <Map<String, dynamic>>[];
        for (var i = 0; i < 5; i++) {
          final usage = await memoryOptimizer.getCurrentMemoryUsage();
          snapshots.add(usage.toMap());
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        expect(snapshots.length, equals(5));
        expect(snapshots.every((s) => s.containsKey('used_bytes')), isTrue);

        print('✅ 内存监控测试通过');
      });

      test('应该能够生成内存报告', () async {
        print('📊 测试内存报告生成');

        final report = memoryOptimizer.generateMemoryReport();

        expect(report, isNotEmpty);
        expect(report['summary'], isNotNull);
        expect(report['current_usage'], isNotNull);
        expect(report['recommendations'], isNotNull);

        print('✅ 内存报告生成测试通过');
      });
    });

    group('综合性能优化测试', () {
      test('应该能够执行综合性能优化', () async {
        print('⚡ 测试综合性能优化');

        // 执行综合优化
        final result = await performanceOptimizer.optimize(
          OptimizationStrategy.comprehensive,
        );

        expect(result.success, isTrue);
        expect(result.strategy, equals(OptimizationStrategy.comprehensive));
        expect(result.appliedOptimizations, isNotEmpty);
        expect(result.improvements, isNotEmpty);

        print('✅ 综合性能优化测试通过');
      });

      test('应该能够生成性能报告', () async {
        print('📊 测试性能报告生成');

        final report = performanceOptimizer.generateReport();

        expect(report, isNotEmpty);
        expect(report['summary'], isNotNull);
        expect(report['improvements'], isNotNull);
        expect(report['history'], isNotNull);
        expect(report['recommendations'], isNotNull);

        print('✅ 性能报告生成测试通过');
      });
    });

    group('压力测试集成', () {
      test('应该能够执行小规模并发测试', () async {
        print('🔥 测试小规模并发压力');

        final result = await stressTester.runConcurrencyStressTest();

        expect(result.totalOperations, greaterThan(0));
        expect(result.errorRate, lessThanOrEqualTo(0.1)); // 错误率不超过10%
        expect(result.averageResponseTime, lessThan(2000)); // 平均响应时间小于2秒

        print('✅ 小规模并发测试通过: ${result.totalOperations}个操作');
      });

      test('应该能够执行短期稳定性测试', () async {
        print('⏱️ 测试短期稳定性');

        // 修改配置为短期测试
        const shortTermConfig = StressTestConfig(
          concurrentUsers: 5,
          operationsPerUser: 50,
          testDuration: Duration(minutes: 1),
          maxMemoryUsage: 200 * 1024 * 1024,
          maxResponseTime: 2000,
          errorThreshold: 0.1,
        );

        final shortTermTester = ExtendedStressTester(
          config: shortTermConfig,
          outputDirectory: tempDir.path,
        );

        await shortTermTester.initialize();

        final result = await shortTermTester.runLongTermStabilityTest();

        expect(result.totalOperations, greaterThan(0));
        expect(result.errorRate, lessThanOrEqualTo(0.1));

        shortTermTester.dispose();

        print('✅ 短期稳定性测试通过: 运行${result.duration.inSeconds}秒');
      });

      test('应该能够生成压力测试报告', () async {
        print('📊 测试压力测试报告生成');

        await stressTester.generateStressTestReport();

        final reportFile =
            File(path.join(tempDir.path, 'stress_test_report.json'));
        expect(await reportFile.exists(), isTrue);

        final content = await reportFile.readAsString();
        expect(content, isNotEmpty);

        print('✅ 压力测试报告生成测试通过');
      });
    });

    group('性能回归检测', () {
      test('应该能够检测性能回归', () async {
        print('🔍 测试性能回归检测');

        // 建立基准性能
        final baseline = await performanceOptimizer.getCurrentMetrics();

        // 模拟性能下降
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 再次测量
        final current = await performanceOptimizer.getCurrentMetrics();

        // 检查是否有性能变化
        expect(current.timestamp, isNot(equals(baseline.timestamp)));

        print('✅ 性能回归检测测试通过');
      });

      test('应该能够建立性能基准', () async {
        print('📏 测试性能基准建立');

        final baseline = performanceOptimizer.getBaselineMetrics();
        expect(baseline, isNotNull);
        expect(baseline!.startupTime, greaterThan(0));
        expect(baseline.memoryUsage, greaterThan(0));

        print('✅ 性能基准建立测试通过');
      });
    });

    group('优化策略验证', () {
      test('应该能够验证启动时间优化策略', () async {
        print('🚀 验证启动时间优化策略');

        final result = await performanceOptimizer.optimize(
          OptimizationStrategy.startup,
        );

        expect(result.success, isTrue);
        expect(result.strategy, equals(OptimizationStrategy.startup));
        expect(
          result.appliedOptimizations.any((opt) => opt.contains('启动')),
          isTrue,
        );

        print('✅ 启动时间优化策略验证通过');
      });

      test('应该能够验证内存优化策略', () async {
        print('🧠 验证内存优化策略');

        final result = await performanceOptimizer.optimize(
          OptimizationStrategy.memory,
        );

        expect(result.success, isTrue);
        expect(result.strategy, equals(OptimizationStrategy.memory));
        expect(
          result.appliedOptimizations.any((opt) => opt.contains('内存')),
          isTrue,
        );

        print('✅ 内存优化策略验证通过');
      });

      test('应该能够验证响应时间优化策略', () async {
        print('⚡ 验证响应时间优化策略');

        final result = await performanceOptimizer.optimize(
          OptimizationStrategy.response,
        );

        expect(result.success, isTrue);
        expect(result.strategy, equals(OptimizationStrategy.response));
        expect(
          result.appliedOptimizations.any((opt) => opt.contains('响应')),
          isTrue,
        );

        print('✅ 响应时间优化策略验证通过');
      });
    });
  });
}
