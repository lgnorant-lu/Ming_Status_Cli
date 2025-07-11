/*
---------------------------------------------------------------
File name:          simple_stress_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        简化压力测试 (Simple Stress Test)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 简化的压力测试用于快速验证;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:math' as math;

import 'package:ming_status_cli/src/core/performance/memory_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/performance_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/startup_optimizer.dart';
import 'package:test/test.dart';

void main() {
  group('简化压力测试', () {
    late PerformanceOptimizer performanceOptimizer;
    late StartupOptimizer startupOptimizer;
    late MemoryOptimizer memoryOptimizer;

    setUpAll(() async {
      performanceOptimizer = PerformanceOptimizer(
        maxMemoryUsage: 100 * 1024 * 1024, // 100MB
        targetResponseTime: 1000, // 1秒
      );
      startupOptimizer = StartupOptimizer();
      memoryOptimizer = MemoryOptimizer(
        maxMemoryUsage: 100 * 1024 * 1024,
      );

      await performanceOptimizer.initialize();
      await memoryOptimizer.initialize();

      print('✅ 简化压力测试环境初始化完成');
    });

    tearDownAll(() async {
      performanceOptimizer.dispose();
      memoryOptimizer.dispose();
      print('✅ 简化压力测试环境清理完成');
    });

    group('基础性能测试', () {
      test('应该能够测量基础性能指标', () async {
        print('📊 测试基础性能指标');

        final metrics = await performanceOptimizer.getCurrentMetrics();

        expect(metrics.startupTime, greaterThan(0));
        expect(metrics.memoryUsage, greaterThan(0));
        expect(metrics.responseTime, greaterThan(0));
        expect(metrics.throughput, greaterThan(0));
        expect(metrics.cacheHitRate, greaterThanOrEqualTo(0));
        expect(metrics.errorRate, greaterThanOrEqualTo(0));

        print('✅ 基础性能指标测试通过');
        print('  启动时间: ${metrics.startupTime}ms');
        print('  内存使用: ${_formatBytes(metrics.memoryUsage)}');
        print('  响应时间: ${metrics.responseTime}ms');
        print('  吞吐量: ${metrics.throughput.toStringAsFixed(2)} ops/sec');
      });

      test('应该能够执行性能优化', () async {
        print('⚡ 测试性能优化');

        final result = await performanceOptimizer.optimize(
          OptimizationStrategy.comprehensive,
        );

        expect(result.strategy, equals(OptimizationStrategy.comprehensive));
        expect(result.appliedOptimizations, isNotEmpty);
        expect(result.beforeMetrics, isNotNull);
        expect(result.afterMetrics, isNotNull);

        print('✅ 性能优化测试通过');
        print('  应用的优化: ${result.appliedOptimizations.length}个');
        print('  优化策略: ${result.strategy.name}');
      });
    });

    group('并发性能测试', () {
      test('应该能够处理小规模并发操作', () async {
        print('🔥 测试小规模并发操作');

        const concurrentCount = 5;
        const operationsPerTask = 10;

        final futures = <Future<List<Duration>>>[];

        for (var i = 0; i < concurrentCount; i++) {
          futures.add(_performConcurrentOperations(operationsPerTask));
        }

        final results = await Future.wait(futures);

        // 统计结果
        var totalOperations = 0;
        var totalTime = Duration.zero;

        for (final taskResults in results) {
          totalOperations += taskResults.length;
          for (final duration in taskResults) {
            totalTime += duration;
          }
        }

        final averageTime = totalTime.inMilliseconds / totalOperations;

        expect(totalOperations, equals(concurrentCount * operationsPerTask));
        expect(averageTime, lessThan(1000)); // 平均操作时间小于1秒

        print('✅ 小规模并发测试通过');
        print('  总操作数: $totalOperations');
        print('  平均操作时间: ${averageTime.toStringAsFixed(2)}ms');
      });

      test('应该能够处理连续操作', () async {
        print('🔄 测试连续操作');

        const operationCount = 20;
        final operationTimes = <Duration>[];

        for (var i = 0; i < operationCount; i++) {
          final stopwatch = Stopwatch()..start();

          // 模拟操作
          await _simulateOperation();

          stopwatch.stop();
          operationTimes.add(stopwatch.elapsed);
        }

        final averageTime = operationTimes
                .map((d) => d.inMilliseconds)
                .reduce((a, b) => a + b) /
            operationCount;

        final maxTime =
            operationTimes.map((d) => d.inMilliseconds).reduce(math.max);

        expect(operationTimes.length, equals(operationCount));
        expect(averageTime, lessThan(500)); // 平均时间小于500ms
        expect(maxTime, lessThan(1000)); // 最大时间小于1秒

        print('✅ 连续操作测试通过');
        print('  操作数: $operationCount');
        print('  平均时间: ${averageTime.toStringAsFixed(2)}ms');
        print('  最大时间: ${maxTime}ms');
      });
    });

    group('内存压力测试', () {
      test('应该能够处理内存分配和释放', () async {
        print('🧠 测试内存分配和释放');

        final beforeUsage = await memoryOptimizer.getCurrentMemoryUsage();

        // 创建大量对象
        final objects = <List<String>>[];
        for (var i = 0; i < 100; i++) {
          objects.add(List.generate(1000, (j) => 'test_data_${i}_$j'));
        }

        final duringUsage = await memoryOptimizer.getCurrentMemoryUsage();

        // 清理对象
        objects.clear();

        // 执行内存优化
        final optimizationResult = await memoryOptimizer.optimize();

        final afterUsage = await memoryOptimizer.getCurrentMemoryUsage();

        expect(duringUsage.usedBytes, greaterThan(beforeUsage.usedBytes));
        expect(optimizationResult.freedBytes, greaterThanOrEqualTo(0));

        print('✅ 内存压力测试通过');
        print('  优化前: ${_formatBytes(beforeUsage.usedBytes)}');
        print('  分配后: ${_formatBytes(duringUsage.usedBytes)}');
        print('  优化后: ${_formatBytes(afterUsage.usedBytes)}');
        print('  释放内存: ${_formatBytes(optimizationResult.freedBytes)}');
      });

      test('应该能够监控内存使用趋势', () async {
        print('📈 测试内存使用趋势监控');

        final snapshots = <Map<String, dynamic>>[];

        // 收集多个内存快照
        for (var i = 0; i < 5; i++) {
          final usage = await memoryOptimizer.getCurrentMemoryUsage();
          snapshots.add(usage.toMap());

          // 创建一些临时对象
          final tempData = List.generate(100, (j) => 'temp_$i$j');
          await Future<void>.delayed(const Duration(milliseconds: 50));
          tempData.clear();
        }

        expect(snapshots.length, equals(5));
        expect(snapshots.every((s) => s.containsKey('used_bytes')), isTrue);
        expect(
            snapshots.every((s) => s.containsKey('usage_percentage')), isTrue,);

        print('✅ 内存趋势监控测试通过');
        print('  快照数量: ${snapshots.length}');
      });
    });

    group('启动时间优化测试', () {
      test('应该能够优化启动时间', () async {
        print('🚀 测试启动时间优化');

        // 注册测试任务
        startupOptimizer.registerTasks([
          StartupTask(
            id: 'quick_init',
            name: '快速初始化',
            phase: StartupPhase.coreInit,
            priority: 1,
            executor: () async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
          ),
          StartupTask(
            id: 'load_config',
            name: '加载配置',
            phase: StartupPhase.componentInit,
            priority: 2,
            executor: () async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
            },
          ),
        ]);

        final result = await startupOptimizer.executeOptimizedStartup();

        expect(result.success, isTrue);
        expect(result.totalTime.inMilliseconds, lessThan(500)); // 小于500ms
        expect(result.phaseResults, isNotEmpty);

        print('✅ 启动时间优化测试通过');
        print('  启动时间: ${result.totalTime.inMilliseconds}ms');
        print('  阶段数: ${result.phaseResults.length}');
      });
    });

    group('压力测试报告', () {
      test('应该能够生成性能报告', () async {
        print('📊 测试性能报告生成');

        final performanceReport = performanceOptimizer.generateReport();
        final memoryReport = memoryOptimizer.generateMemoryReport();
        final startupReport = startupOptimizer.generateStartupReport();

        expect(performanceReport, isNotEmpty);
        expect(performanceReport['summary'], isNotNull);

        expect(memoryReport, isNotEmpty);
        expect(memoryReport['summary'], isNotNull);

        expect(startupReport, isNotEmpty);
        expect(startupReport['summary'], isNotNull);

        print('✅ 性能报告生成测试通过');
        print('  性能报告项目: ${performanceReport.keys.length}');
        print('  内存报告项目: ${memoryReport.keys.length}');
        print('  启动报告项目: ${startupReport.keys.length}');
      });
    });
  });
}

/// 执行并发操作
Future<List<Duration>> _performConcurrentOperations(int count) async {
  final results = <Duration>[];

  for (var i = 0; i < count; i++) {
    final stopwatch = Stopwatch()..start();

    await _simulateOperation();

    stopwatch.stop();
    results.add(stopwatch.elapsed);
  }

  return results;
}

/// 模拟操作
Future<void> _simulateOperation() async {
  // 模拟CPU密集型操作
  var sum = 0;
  for (var i = 0; i < 1000; i++) {
    sum += i * i;
  }

  // 模拟I/O操作
  await Future<void>.delayed(
      Duration(milliseconds: math.Random().nextInt(10) + 5),);

  // 模拟内存操作
  final tempList = List.generate(100, (i) => 'temp_$i$sum');
  tempList.clear();
}

/// 格式化字节数
String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}
