/*
---------------------------------------------------------------
File name:          performance_optimization_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.3 - 性能优化和资源管理测试
                    验证性能监控、缓存管理和资源管理功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 性能优化和资源管理测试;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:ming_status_cli/src/core/cache_manager.dart';
import 'package:ming_status_cli/src/core/performance_monitor.dart';
import 'package:ming_status_cli/src/core/resource_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 51.3: 性能优化和资源管理测试', () {
    late Directory tempDir;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_performance_test_');
      print('⚡ 性能优化测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }
    });

    group('性能监控器测试', () {
      late PerformanceMonitor monitor;

      setUp(() {
        monitor = PerformanceMonitor();
      });

      tearDown(() {
        monitor.disable();
        monitor.clearMetrics();
      });

      test('应该能够启用和禁用性能监控', () {
        expect(monitor.isMonitoring, isFalse);
        
        monitor.enable();
        expect(monitor.isMonitoring, isTrue);
        
        monitor.disable();
        expect(monitor.isMonitoring, isFalse);
        
        print('✅ 性能监控启用/禁用测试通过');
      });

      test('应该能够记录性能指标', () {
        monitor.enable();
        
        final metric = PerformanceMetric(
          name: 'test_metric',
          type: PerformanceMetricType.execution,
          value: 100,
          unit: 'ms',
          timestamp: DateTime.now(),
        );
        
        monitor.recordMetric(metric);
        expect(monitor.metricsCount, equals(1));
        
        print('✅ 性能指标记录测试通过');
      });

      test('应该能够测量执行时间', () async {
        monitor.enable();
        
        final result = await monitor.measureExecution(
          'test_operation',
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return 'test_result';
          },
        );
        
        expect(result, equals('test_result'));
        expect(monitor.metricsCount, greaterThan(0));
        
        // 检查是否记录了执行时间指标
        final stats = monitor.getPerformanceStats();
        expect(stats['total_metrics'], greaterThan(0));
        
        print('✅ 执行时间测量测试通过');
      });

      test('应该能够分析性能数据', () {
        monitor.enable();
        
        // 添加一些测试指标
        monitor.recordMetric(PerformanceMetric(
          name: 'fast_operation',
          type: PerformanceMetricType.execution,
          value: 50,
          unit: 'ms',
          timestamp: DateTime.now(),
        ),);
        
        monitor.recordMetric(PerformanceMetric(
          name: 'slow_operation',
          type: PerformanceMetricType.execution,
          value: 2000,
          unit: 'ms',
          timestamp: DateTime.now(),
        ),);
        
        final analysis = monitor.analyzePerformance();
        
        expect(analysis.overallScore, isA<double>());
        expect(analysis.metrics, hasLength(2));
        expect(analysis.analysisTime, isA<DateTime>());
        
        print('✅ 性能数据分析测试通过 (评分: ${analysis.overallScore.toStringAsFixed(1)})');
      });

      test('应该能够导出性能报告', () async {
        monitor.enable();
        
        // 添加测试数据
        await monitor.measureExecution('test_export', () async {
          await Future.delayed(const Duration(milliseconds: 50));
        });
        
        final reportPath = path.join(tempDir.path, 'performance_report.json');
        await monitor.exportReport(reportPath);
        
        final reportFile = File(reportPath);
        expect(reportFile.existsSync(), isTrue);
        
        final content = await reportFile.readAsString();
        expect(content, isNotEmpty);
        expect(content, contains('analysis'));
        expect(content, contains('stats'));
        
        print('✅ 性能报告导出测试通过');
      });
    });

    group('缓存管理器测试', () {
      late CacheManager cacheManager;

      setUp(() async {
        cacheManager = CacheManager();
        await cacheManager.initialize(
          cacheDirectory: path.join(tempDir.path, 'cache'),
          maxMemoryItems: 100,
          maxMemoryBytes: 1024 * 1024, // 1MB
        );
      });

      tearDown(() async {
        await cacheManager.clear();
        cacheManager.dispose();
      });

      test('应该能够设置和获取缓存项', () async {
        const key = 'test_key';
        const value = 'test_value';
        
        await cacheManager.set(key, value);
        final result = await cacheManager.get<String>(key);
        
        expect(result, equals(value));
        
        print('✅ 缓存设置/获取测试通过');
      });

      test('应该能够处理复杂数据类型', () async {
        const key = 'complex_data';
        final value = {
          'name': 'test',
          'numbers': [1, 2, 3],
          'nested': {'key': 'value'},
        };
        
        await cacheManager.set(key, value);
        final result = await cacheManager.get<Map<String, dynamic>>(key);
        
        expect(result, equals(value));
        expect(result?['name'], equals('test'));
        expect(result?['numbers'], equals([1, 2, 3]));
        
        print('✅ 复杂数据类型缓存测试通过');
      });

      test('应该能够处理TTL过期', () async {
        const key = 'ttl_test';
        const value = 'expires_soon';
        
        await cacheManager.set(key, value, ttl: const Duration(milliseconds: 100));
        
        // 立即获取应该成功
        var result = await cacheManager.get<String>(key);
        expect(result, equals(value));
        
        // 等待过期
        await Future.delayed(const Duration(milliseconds: 200));
        
        // 过期后应该返回null
        result = await cacheManager.get<String>(key);
        expect(result, isNull);
        
        print('✅ TTL过期测试通过');
      });

      test('应该能够删除缓存项', () async {
        const key = 'delete_test';
        const value = 'to_be_deleted';
        
        await cacheManager.set(key, value);
        expect(await cacheManager.get<String>(key), equals(value));
        
        final removed = await cacheManager.remove(key);
        expect(removed, isTrue);
        expect(await cacheManager.get<String>(key), isNull);
        
        print('✅ 缓存删除测试通过');
      });

      test('应该能够获取缓存统计', () async {
        // 添加一些缓存项
        for (var i = 0; i < 5; i++) {
          await cacheManager.set('key_$i', 'value_$i');
        }
        
        // 访问一些缓存项
        await cacheManager.get('key_0');
        await cacheManager.get('key_1');
        await cacheManager.get('nonexistent_key');
        
        final stats = cacheManager.getStats();
        
        expect(stats, containsPair('memory', isA<Map>()));
        expect(stats, containsPair('disk', isA<Map>()));
        expect(stats['memory']['totalRequests'], greaterThan(0));
        expect(stats['memory']['hits'], greaterThan(0));
        
        print('✅ 缓存统计测试通过');
      });

      test('应该能够处理大量缓存操作', () async {
        final stopwatch = Stopwatch()..start();
        
        // 设置大量缓存项
        for (var i = 0; i < 50; i++) {
          await cacheManager.set('bulk_key_$i', 'bulk_value_$i');
        }
        
        // 获取大量缓存项
        for (var i = 0; i < 50; i++) {
          final result = await cacheManager.get<String>('bulk_key_$i');
          expect(result, equals('bulk_value_$i'));
        }
        
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
               reason: '100次缓存操作应该在5秒内完成',);
        
        print('⏱️  缓存性能测试: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 大量缓存操作测试通过');
      });
    });

    group('资源管理器测试', () {
      late ResourceManager resourceManager;

      setUp(() {
        resourceManager = ResourceManager();
        resourceManager.initialize();
      });

      tearDown(() async {
        await resourceManager.dispose();
      });

      test('应该能够注册和获取资源', () {
        final timer = Timer(const Duration(seconds: 1), () {});
        final resource = TimerResource(
          id: 'test_timer',
          timer: timer,
          description: 'Test timer resource',
        );
        
        resourceManager.registerResource(resource);
        
        final retrieved = resourceManager.getResource('test_timer');
        expect(retrieved, equals(resource));
        expect(retrieved?.type, equals(ResourceType.timer));
        
        print('✅ 资源注册/获取测试通过');
      });

      test('应该能够释放资源', () async {
        final timer = Timer(const Duration(seconds: 1), () {});
        final resource = TimerResource(
          id: 'disposable_timer',
          timer: timer,
          description: 'Disposable timer',
        );
        
        resourceManager.registerResource(resource);
        expect(resource.isDisposed, isFalse);
        
        await resourceManager.disposeResource('disposable_timer');
        expect(resource.isDisposed, isTrue);
        
        final retrieved = resourceManager.getResource('disposable_timer');
        expect(retrieved, isNull);
        
        print('✅ 资源释放测试通过');
      });

      test('应该能够创建和管理资源池', () async {
        // 创建一个简单的资源池
        final pool = ResourcePool<TimerResource>(
          name: 'timer_pool',
          maxResources: 5,
          resourceFactory: () async {
            final timer = Timer(const Duration(minutes: 1), () {});
            return TimerResource(
              id: 'pool_timer_${DateTime.now().millisecondsSinceEpoch}',
              timer: timer,
              description: 'Pool timer',
            );
          },
        );
        
        resourceManager.registerPool(pool);
        
        // 获取资源
        final resource1 = await pool.acquire();
        expect(resource1.status, equals(ResourceStatus.inUse));
        expect(pool.inUseResources, equals(1));
        
        // 释放资源
        pool.release(resource1);
        expect(resource1.status, equals(ResourceStatus.available));
        expect(pool.availableResources, equals(1));
        
        await pool.dispose();
        print('✅ 资源池管理测试通过');
      });

      test('应该能够获取资源统计', () {
        // 创建一些测试资源
        for (var i = 0; i < 3; i++) {
          final timer = Timer(const Duration(seconds: 1), () {});
          final resource = TimerResource(
            id: 'stats_timer_$i',
            timer: timer,
            description: 'Stats timer $i',
          );
          resourceManager.registerResource(resource);
        }
        
        final stats = resourceManager.getResourceStats();
        
        expect(stats, containsPair('totalResources', 3));
        expect(stats, containsPair('resourcesByType', isA<Map>()));
        expect(stats, containsPair('resourcesByStatus', isA<Map>()));
        expect(stats['resourcesByType']['timer'], equals(3));
        
        print('✅ 资源统计测试通过');
      });

      test('应该能够设置内存阈值', () {
        final originalThreshold = resourceManager.memoryThresholdBytes;
        const newThreshold = 100 * 1024 * 1024; // 100MB
        
        resourceManager.setMemoryThreshold(newThreshold);
        expect(resourceManager.memoryThresholdBytes, equals(newThreshold));
        
        // 恢复原始阈值
        resourceManager.setMemoryThreshold(originalThreshold);
        
        print('✅ 内存阈值设置测试通过');
      });
    });

    group('集成性能测试', () {
      test('应该能够协同工作进行性能优化', () async {
        // 初始化所有组件
        final monitor = PerformanceMonitor();
        final cacheManager = CacheManager();
        final resourceManager = ResourceManager();
        
        monitor.enable();
        await cacheManager.initialize(
          cacheDirectory: path.join(tempDir.path, 'integration_cache'),
        );
        resourceManager.initialize();
        
        try {
          // 模拟一个复杂的操作
          await monitor.measureExecution('complex_operation', () async {
            // 缓存操作
            await cacheManager.set('operation_data', {'step': 1});
            final cached = await cacheManager.get('operation_data');
            expect(cached, isNotNull);
            
            // 资源操作
            final timer = Timer(const Duration(milliseconds: 100), () {});
            final resource = TimerResource(
              id: 'integration_timer',
              timer: timer,
              description: 'Integration test timer',
            );
            resourceManager.registerResource(resource);
            
            // 模拟一些工作
            await Future.delayed(const Duration(milliseconds: 50));
            
            await resourceManager.disposeResource('integration_timer');
          });
          
          // 检查性能指标
          expect(monitor.metricsCount, greaterThan(0));
          
          // 检查缓存统计
          final cacheStats = cacheManager.getStats();
          expect(cacheStats['memory']['totalRequests'], greaterThan(0));
          
          // 检查资源统计
          final resourceStats = resourceManager.getResourceStats();
          expect(resourceStats, isA<Map>());
          
          print('✅ 集成性能优化测试通过');
        } finally {
          // 清理
          monitor.disable();
          await cacheManager.clear();
          cacheManager.dispose();
          await resourceManager.dispose();
        }
      });

      test('应该能够处理高负载场景', () async {
        final monitor = PerformanceMonitor();
        final cacheManager = CacheManager();
        
        monitor.enable();
        await cacheManager.initialize(
          cacheDirectory: path.join(tempDir.path, 'load_test_cache'),
        );
        
        try {
          final stopwatch = Stopwatch()..start();
          
          // 并发执行多个操作
          final futures = <Future<void>>[];
          for (var i = 0; i < 20; i++) {
            futures.add(monitor.measureExecution('load_test_$i', () async {
              // 缓存操作
              await cacheManager.set('load_key_$i', 'load_value_$i');
              final result = await cacheManager.get<String>('load_key_$i');
              expect(result, equals('load_value_$i'));
              
              // 模拟一些计算
              await Future.delayed(const Duration(milliseconds: 10));
            }),);
          }
          
          await Future.wait(futures);
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(5000),
                 reason: '20个并发操作应该在5秒内完成',);
          
          // 检查性能分析
          final analysis = monitor.analyzePerformance();
          expect(analysis.overallScore, greaterThan(0));
          
          print('⏱️  高负载测试: ${stopwatch.elapsedMilliseconds}ms');
          print('📊 性能评分: ${analysis.overallScore.toStringAsFixed(1)}');
          print('✅ 高负载场景测试通过');
        } finally {
          monitor.disable();
          await cacheManager.clear();
          cacheManager.dispose();
        }
      });
    });
  });
}
