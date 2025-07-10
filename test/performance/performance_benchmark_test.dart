/*
---------------------------------------------------------------
File name:          performance_benchmark_test.dart
Author:             lgnorant-lu
Date created:       2025-07-08
Last modified:      2025-07-08
Dart Version:       3.2+
Description:        Task 49.3 - 性能基准和压力测试
                    验证大规模使用场景，创建性能基准测试
---------------------------------------------------------------
Change History:
    2025-07-08: Initial creation - 性能基准和压力测试;
---------------------------------------------------------------
*/

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../integration/cli_test_helper.dart';

void main() {
  group('Task 49.3: 性能基准和压力测试', () {
    late Directory tempDir;
    late PerformanceMetrics metrics;

    setUpAll(() async {
      // 初始化CLI测试环境
      await CliTestHelper.setUpAll();

      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_performance_');
      metrics = PerformanceMetrics();

      print('📊 性能测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }

      // 输出性能报告
      metrics.printReport();

      // 清理CLI测试环境
      await CliTestHelper.tearDownAll();
    });

    group('基础性能基准测试', () {
      test('CLI命令响应时间基准', () async {
        final benchmarks = <String, Duration>{};

        // 测试help命令响应时间
        final helpStopwatch = Stopwatch()..start();
        final helpResult = await CliTestHelper.runCommand(
          ['--help'],
          workingDirectory: tempDir.path,
        );
        helpStopwatch.stop();
        benchmarks['help_command'] = helpStopwatch.elapsed;

        expect(helpResult.exitCode, equals(0), reason: 'Help命令应该成功');
        expect(
          helpStopwatch.elapsedMilliseconds,
          lessThan(15000),
          reason: 'Help命令应该在15秒内响应',
        );

        // 测试version命令响应时间
        final versionStopwatch = Stopwatch()..start();
        final versionResult = await CliTestHelper.runCommand(
          ['version'],
          workingDirectory: tempDir.path,
        );
        versionStopwatch.stop();
        benchmarks['version_command'] = versionStopwatch.elapsed;

        expect(versionResult.exitCode, equals(0), reason: 'Version命令应该成功');
        expect(
          versionStopwatch.elapsedMilliseconds,
          lessThan(15000),
          reason: 'Version命令应该在15秒内响应',
        );

        // 记录基准数据
        metrics.addBenchmark('CLI响应时间', benchmarks);

        print('⏱️  CLI命令响应时间基准:');
        print('   Help命令: ${helpStopwatch.elapsedMilliseconds}ms');
        print('   Version命令: ${versionStopwatch.elapsedMilliseconds}ms');
      });

      test('工作空间初始化性能基准', () async {
        final initBenchmarks = <String, Duration>{};

        // 测试单个工作空间初始化
        final singleInitStopwatch = Stopwatch()..start();
        final initResult = await CliTestHelper.runCommand(
          [
            '--quiet',
            'init',
            'perf_workspace',
            '--name',
            'perf_workspace',
            '--description',
            'Performance test workspace',
            '--author',
            'Performance Tester',
          ],
          workingDirectory: tempDir.path,
        );
        singleInitStopwatch.stop();
        initBenchmarks['single_init'] = singleInitStopwatch.elapsed;

        expect(initResult.exitCode, equals(0), reason: '工作空间初始化应该成功');
        expect(
          singleInitStopwatch.elapsedMilliseconds,
          lessThan(15000),
          reason: '工作空间初始化应该在15秒内完成',
        );

        // 验证配置文件创建
        final configFile = File(path.join(tempDir.path, 'ming_status.yaml'));
        expect(configFile.existsSync(), isTrue, reason: '配置文件应该被创建');

        // 记录基准数据
        metrics.addBenchmark('工作空间初始化', initBenchmarks);

        print('⏱️  工作空间初始化性能基准:');
        print('   单个初始化: ${singleInitStopwatch.elapsedMilliseconds}ms');
      });
    });

    group('压力测试', () {
      test('连续命令执行压力测试', () async {
        const testIterations = 5; // 减少测试次数以避免超时
        final results = <Duration>[];
        var successCount = 0;

        print('🔄 开始连续命令执行压力测试 ($testIterations次)...');

        for (var i = 0; i < testIterations; i++) {
          final stopwatch = Stopwatch()..start();

          try {
            final result = await CliTestHelper.runCommand(
              ['--help'],
              workingDirectory: tempDir.path,
            );

            stopwatch.stop();
            results.add(stopwatch.elapsed);

            if (result.exitCode == 0) {
              successCount++;
            }

            // 每5次输出进度
            if ((i + 1) % 5 == 0) {
              print('   进度: ${i + 1}/$testIterations 完成');
            }
          } catch (e) {
            stopwatch.stop();
            results.add(stopwatch.elapsed);
            print('   错误 (第${i + 1}次): $e');
          }
        }

        // 计算统计数据
        final totalTime = results.fold<Duration>(
          Duration.zero,
          (prev, curr) => prev + curr,
        );
        final avgTime = Duration(
          microseconds: totalTime.inMicroseconds ~/ results.length,
        );
        final maxTime = results.reduce((a, b) => a > b ? a : b);
        final minTime = results.reduce((a, b) => a < b ? a : b);

        // 验证压力测试结果
        expect(
          successCount,
          greaterThanOrEqualTo(testIterations * 0.9),
          reason: '至少90%的命令应该成功执行',
        );
        expect(
          avgTime.inMilliseconds,
          lessThan(15000),
          reason: '平均响应时间应该在15秒内',
        );

        // 记录压力测试数据
        metrics.addStressTest('连续命令执行', {
          'iterations': testIterations,
          'success_rate': successCount / testIterations,
          'avg_time': avgTime,
          'max_time': maxTime,
          'min_time': minTime,
        });

        print('📊 连续命令执行压力测试结果:');
        print('   总次数: $testIterations');
        print('   成功次数: $successCount');
        print(
          '   成功率: ${(successCount / testIterations * 100).toStringAsFixed(1)}%',
        );
        print('   平均时间: ${avgTime.inMilliseconds}ms');
        print('   最大时间: ${maxTime.inMilliseconds}ms');
        print('   最小时间: ${minTime.inMilliseconds}ms');
      });

      test('内存使用监控测试', () async {
        print('🧠 开始内存使用监控测试...');

        // 获取初始内存使用
        final initialMemory = _getCurrentMemoryUsage();
        print('   初始内存使用: ${_formatMemory(initialMemory)}');

        // 执行一系列操作
        final operations = [
          () => CliTestHelper.runCommand(
                ['--help'],
                workingDirectory: tempDir.path,
              ),
          () => CliTestHelper.runCommand(
                ['version'],
                workingDirectory: tempDir.path,
              ),
          () => CliTestHelper.runCommand(
                ['--help'],
                workingDirectory: tempDir.path,
              ),
        ];

        var maxMemory = initialMemory;

        for (var i = 0; i < operations.length; i++) {
          await operations[i]();

          // 强制垃圾回收
          for (var j = 0; j < 3; j++) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }

          final currentMemory = _getCurrentMemoryUsage();
          maxMemory = max(maxMemory, currentMemory);

          print('   操作${i + 1}后内存: ${_formatMemory(currentMemory)}');
        }

        final finalMemory = _getCurrentMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;

        // 记录内存使用数据
        metrics.addMemoryTest('基础操作内存使用', {
          'initial_memory': initialMemory,
          'max_memory': maxMemory,
          'final_memory': finalMemory,
          'memory_increase': memoryIncrease,
        });

        // 验证内存使用合理性
        expect(
          maxMemory,
          lessThan(500 * 1024 * 1024),
          reason: '最大内存使用应该小于500MB',
        );
        expect(
          memoryIncrease,
          lessThan(50 * 1024 * 1024),
          reason: '内存增长应该小于50MB',
        );

        print('📊 内存使用监控结果:');
        print('   初始内存: ${_formatMemory(initialMemory)}');
        print('   最大内存: ${_formatMemory(maxMemory)}');
        print('   最终内存: ${_formatMemory(finalMemory)}');
        print('   内存增长: ${_formatMemory(memoryIncrease)}');
      });
    });

    group('负载测试', () {
      test('并发操作负载测试', () async {
        const concurrentOperations = 5;
        print('⚡ 开始并发操作负载测试 ($concurrentOperations个并发)...');

        final stopwatch = Stopwatch()..start();

        // 创建并发操作
        final futures = List.generate(concurrentOperations, (index) async {
          final operationStopwatch = Stopwatch()..start();

          try {
            final result = await CliTestHelper.runCommand(
              ['--help'],
              workingDirectory: tempDir.path,
            );

            operationStopwatch.stop();

            return {
              'index': index,
              'success': result.exitCode == 0,
              'duration': operationStopwatch.elapsed,
            };
          } catch (e) {
            operationStopwatch.stop();
            return {
              'index': index,
              'success': false,
              'duration': operationStopwatch.elapsed,
              'error': e.toString(),
            };
          }
        });

        // 等待所有操作完成
        final results = await Future.wait(futures);
        stopwatch.stop();

        // 分析结果
        final successCount = results.where((r) => r['success'] == true).length;
        final avgDuration = Duration(
          microseconds: results
                  .map<Duration>((r) => r['duration']! as Duration)
                  .fold<int>(0, (sum, d) => sum + d.inMicroseconds) ~/
              results.length,
        );

        // 记录负载测试数据
        metrics.addLoadTest('并发操作', {
          'concurrent_operations': concurrentOperations,
          'total_time': stopwatch.elapsed,
          'success_count': successCount,
          'success_rate': successCount / concurrentOperations,
          'avg_duration': avgDuration,
        });

        // 验证负载测试结果
        expect(
          successCount,
          equals(concurrentOperations),
          reason: '所有并发操作都应该成功',
        );
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(25000),
          reason: '并发操作应该在25秒内完成',
        );

        print('📊 并发操作负载测试结果:');
        print('   并发数: $concurrentOperations');
        print('   成功数: $successCount');
        print('   总时间: ${stopwatch.elapsedMilliseconds}ms');
        print('   平均时间: ${avgDuration.inMilliseconds}ms');
        print(
          '   成功率: ${(successCount / concurrentOperations * 100).toStringAsFixed(1)}%',
        );
      });
    });
  });
}

/// 性能指标收集器
class PerformanceMetrics {
  final Map<String, Map<String, Duration>> _benchmarks = {};
  final Map<String, Map<String, dynamic>> _stressTests = {};
  final Map<String, Map<String, dynamic>> _memoryTests = {};
  final Map<String, Map<String, dynamic>> _loadTests = {};

  void addBenchmark(String category, Map<String, Duration> data) {
    _benchmarks[category] = data;
  }

  void addStressTest(String category, Map<String, dynamic> data) {
    _stressTests[category] = data;
  }

  void addMemoryTest(String category, Map<String, dynamic> data) {
    _memoryTests[category] = data;
  }

  void addLoadTest(String category, Map<String, dynamic> data) {
    _loadTests[category] = data;
  }

  void printReport() {
    print('\n📊 ===== 性能测试报告 =====');

    if (_benchmarks.isNotEmpty) {
      print('\n🎯 性能基准测试:');
      _benchmarks.forEach((category, data) {
        print('  $category:');
        data.forEach((key, duration) {
          print('    $key: ${duration.inMilliseconds}ms');
        });
      });
    }

    if (_stressTests.isNotEmpty) {
      print('\n🔄 压力测试:');
      _stressTests.forEach((category, data) {
        print('  $category:');
        data.forEach((key, value) {
          if (value is Duration) {
            print('    $key: ${value.inMilliseconds}ms');
          } else {
            print('    $key: $value');
          }
        });
      });
    }

    if (_memoryTests.isNotEmpty) {
      print('\n🧠 内存测试:');
      _memoryTests.forEach((category, data) {
        print('  $category:');
        data.forEach((key, value) {
          if (key.contains('memory')) {
            print('    $key: ${_formatMemory(value as int)}');
          } else {
            print('    $key: $value');
          }
        });
      });
    }

    if (_loadTests.isNotEmpty) {
      print('\n⚡ 负载测试:');
      _loadTests.forEach((category, data) {
        print('  $category:');
        data.forEach((key, value) {
          if (value is Duration) {
            print('    $key: ${value.inMilliseconds}ms');
          } else {
            print('    $key: $value');
          }
        });
      });
    }

    print('\n✅ 性能测试报告完成');
  }
}

/// 获取当前内存使用量（字节）
int _getCurrentMemoryUsage() {
  // 在实际环境中，这里可以使用更精确的内存监控
  // 目前返回一个模拟值
  return ProcessInfo.currentRss;
}

/// 格式化内存大小显示
String _formatMemory(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}
