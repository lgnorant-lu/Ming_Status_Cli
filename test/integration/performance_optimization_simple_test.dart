/*
---------------------------------------------------------------
File name:          performance_optimization_simple_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.3 - 性能优化和资源管理简化测试
                    验证核心性能优化功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 性能优化简化测试;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ming_status_cli/src/core/cache_manager.dart';
import 'package:ming_status_cli/src/core/performance_monitor.dart';
import 'package:ming_status_cli/src/core/resource_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 51.3: 性能优化和资源管理简化测试', () {
    late Directory tempDir;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_perf_simple_test_');
      print('⚡ 性能优化简化测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }
    });

    group('性能监控器基础测试', () {
      test('应该能够创建性能监控器实例', () {
        final monitor = PerformanceMonitor();
        expect(monitor, isNotNull);
        expect(monitor.isMonitoring, isFalse);
        print('✅ 性能监控器实例创建成功');
      });

      test('应该能够启用和禁用监控', () {
        final monitor = PerformanceMonitor();

        monitor.enable();
        expect(monitor.isMonitoring, isTrue);

        monitor.disable();
        expect(monitor.isMonitoring, isFalse);

        print('✅ 监控启用/禁用测试通过');
      });

      test('应该能够记录性能指标', () {
        final monitor = PerformanceMonitor();
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

        monitor.disable();
        print('✅ 性能指标记录测试通过');
      });

      test('应该能够测量执行时间', () async {
        final monitor = PerformanceMonitor();
        monitor.enable();

        final result = await monitor.measureExecution(
          'test_operation',
          () async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'test_result';
          },
        );

        expect(result, equals('test_result'));
        expect(monitor.metricsCount, greaterThan(0));

        monitor.disable();
        print('✅ 执行时间测量测试通过');
      });

      test('应该能够分析性能数据', () {
        final monitor = PerformanceMonitor();
        monitor.enable();

        // 添加测试指标
        monitor.recordMetric(PerformanceMetric(
          name: 'fast_operation',
          type: PerformanceMetricType.execution,
          value: 50,
          unit: 'ms',
          timestamp: DateTime.now(),
        ),);

        final analysis = monitor.analyzePerformance();

        expect(analysis.overallScore, isA<double>());
        expect(analysis.metrics, hasLength(greaterThanOrEqualTo(1)));
        expect(analysis.analysisTime, isA<DateTime>());

        monitor.disable();
        print('✅ 性能数据分析测试通过 (评分: ${analysis.overallScore.toStringAsFixed(1)})');
      });

      test('应该能够获取性能统计', () {
        final monitor = PerformanceMonitor();
        monitor.enable();

        monitor.recordMetric(PerformanceMetric(
          name: 'stats_test',
          type: PerformanceMetricType.memory,
          value: 1024,
          unit: 'bytes',
          timestamp: DateTime.now(),
        ),);

        final stats = monitor.getPerformanceStats();

        expect(stats, containsPair('monitoring_enabled', true));
        expect(stats, containsPair('total_metrics', greaterThanOrEqualTo(1)));
        expect(stats, containsPair('overall_score', isA<double>()));

        monitor.disable();
        print('✅ 性能统计测试通过');
      });
    });

    group('内存缓存基础测试', () {
      test('应该能够创建内存缓存实例', () {
        final cache = MemoryCache<String>();
        expect(cache, isNotNull);
        expect(cache.length, equals(0));

        cache.dispose();
        print('✅ 内存缓存实例创建成功');
      });

      test('应该能够设置和获取缓存项', () {
        final cache = MemoryCache<String>();

        cache.set('test_key', 'test_value');
        final result = cache.get('test_key');

        expect(result, equals('test_value'));
        expect(cache.length, equals(1));

        cache.dispose();
        print('✅ 缓存设置/获取测试通过');
      });

      test('应该能够处理TTL过期', () async {
        final cache = MemoryCache<String>();

        cache.set('ttl_key', 'ttl_value',
            ttl: const Duration(milliseconds: 100),);

        // 立即获取应该成功
        var result = cache.get('ttl_key');
        expect(result, equals('ttl_value'));

        // 等待过期
        await Future.delayed(const Duration(milliseconds: 200));

        // 过期后应该返回null
        result = cache.get('ttl_key');
        expect(result, isNull);

        cache.dispose();
        print('✅ TTL过期测试通过');
      });

      test('应该能够删除缓存项', () {
        final cache = MemoryCache<String>();

        cache.set('delete_key', 'delete_value');
        expect(cache.get('delete_key'), equals('delete_value'));

        final removed = cache.remove('delete_key');
        expect(removed, isTrue);
        expect(cache.get('delete_key'), isNull);

        cache.dispose();
        print('✅ 缓存删除测试通过');
      });

      test('应该能够获取缓存统计', () {
        final cache = MemoryCache<String>();

        // 添加一些缓存项
        cache.set('stats_key1', 'value1');
        cache.set('stats_key2', 'value2');

        // 访问缓存项
        cache.get('stats_key1');
        cache.get('nonexistent_key');

        final stats = cache.stats;

        expect(stats.totalRequests, equals(2));
        expect(stats.hits, equals(1));
        expect(stats.misses, equals(1));
        expect(stats.hitRate, equals(0.5));

        cache.dispose();
        print('✅ 缓存统计测试通过');
      });
    });

    group('磁盘缓存基础测试', () {
      test('应该能够创建磁盘缓存实例', () async {
        final cacheDir = path.join(tempDir.path, 'disk_cache_test');
        final cache = DiskCache(cacheDirectory: cacheDir);

        await cache.initialize();
        expect(Directory(cacheDir).existsSync(), isTrue);

        print('✅ 磁盘缓存实例创建成功');
      });

      test('应该能够设置和获取磁盘缓存', () async {
        final cacheDir = path.join(tempDir.path, 'disk_cache_ops');
        final cache = DiskCache(cacheDirectory: cacheDir);

        await cache.initialize();

        final testData = Uint8List.fromList('test_data'.codeUnits);
        await cache.set('disk_key', testData);

        final result = await cache.get('disk_key');
        expect(result, isNotNull);
        expect(String.fromCharCodes(result!), equals('test_data'));

        print('✅ 磁盘缓存设置/获取测试通过');
      });

      test('应该能够删除磁盘缓存项', () async {
        final cacheDir = path.join(tempDir.path, 'disk_cache_delete');
        final cache = DiskCache(cacheDirectory: cacheDir);

        await cache.initialize();

        final testData = Uint8List.fromList('delete_test'.codeUnits);
        await cache.set('delete_disk_key', testData);

        var result = await cache.get('delete_disk_key');
        expect(result, isNotNull);

        final removed = await cache.remove('delete_disk_key');
        expect(removed, isTrue);

        result = await cache.get('delete_disk_key');
        expect(result, isNull);

        print('✅ 磁盘缓存删除测试通过');
      });

      test('应该能够获取缓存大小', () async {
        final cacheDir = path.join(tempDir.path, 'disk_cache_size');
        final cache = DiskCache(cacheDirectory: cacheDir);

        await cache.initialize();

        final initialSize = await cache.getCacheSize();
        expect(initialSize, equals(0));

        final testData = Uint8List.fromList('size_test_data'.codeUnits);
        await cache.set('size_key', testData);

        final newSize = await cache.getCacheSize();
        expect(newSize, greaterThan(0));

        print('✅ 磁盘缓存大小测试通过');
      });
    });

    group('资源管理器基础测试', () {
      test('应该能够创建资源管理器实例', () {
        final manager = ResourceManager();
        expect(manager, isNotNull);
        print('✅ 资源管理器实例创建成功');
      });

      test('应该能够注册和获取资源', () async {
        final manager = ResourceManager();
        manager.initialize();

        final timer = Timer(const Duration(seconds: 1), () {});
        final resource = TimerResource(
          id: 'test_timer',
          timer: timer,
          description: 'Test timer resource',
        );

        manager.registerResource(resource);

        final retrieved = manager.getResource('test_timer');
        expect(retrieved, equals(resource));
        expect(retrieved?.type, equals(ResourceType.timer));

        await manager.dispose();
        print('✅ 资源注册/获取测试通过');
      });

      test('应该能够释放资源', () async {
        final manager = ResourceManager();
        manager.initialize();

        final timer = Timer(const Duration(seconds: 1), () {});
        final resource = TimerResource(
          id: 'disposable_timer',
          timer: timer,
          description: 'Disposable timer',
        );

        manager.registerResource(resource);
        expect(resource.isDisposed, isFalse);

        await manager.disposeResource('disposable_timer');
        expect(resource.isDisposed, isTrue);

        final retrieved = manager.getResource('disposable_timer');
        expect(retrieved, isNull);

        await manager.dispose();
        print('✅ 资源释放测试通过');
      });

      test('应该能够获取资源统计', () async {
        final manager = ResourceManager();
        manager.initialize();

        // 创建一些测试资源
        for (var i = 0; i < 3; i++) {
          final timer = Timer(const Duration(seconds: 1), () {});
          final resource = TimerResource(
            id: 'stats_timer_$i',
            timer: timer,
            description: 'Stats timer $i',
          );
          manager.registerResource(resource);
        }

        final stats = manager.getResourceStats();

        expect(stats, containsPair('totalResources', 3));
        expect(stats, containsPair('resourcesByType', isA<Map>()));
        expect(stats['resourcesByType']['timer'], equals(3));

        await manager.dispose();
        print('✅ 资源统计测试通过');
      });
    });

    group('性能测试', () {
      test('应该能够快速处理大量性能指标', () {
        final monitor = PerformanceMonitor();
        monitor.enable();

        final stopwatch = Stopwatch()..start();

        // 记录大量指标
        for (var i = 0; i < 100; i++) {
          monitor.recordMetric(PerformanceMetric(
            name: 'perf_test_$i',
            type: PerformanceMetricType.execution,
            value: i.toDouble(),
            unit: 'ms',
            timestamp: DateTime.now(),
          ),);
        }

        stopwatch.stop();

        expect(monitor.metricsCount, greaterThanOrEqualTo(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: '100个性能指标记录应该在1秒内完成',);

        monitor.disable();
        print('⏱️  性能指标记录测试: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 大量性能指标处理测试通过');
      });

      test('应该能够快速处理缓存操作', () {
        final cache = MemoryCache<String>();

        final stopwatch = Stopwatch()..start();

        // 大量缓存操作
        for (var i = 0; i < 100; i++) {
          cache.set('perf_key_$i', 'perf_value_$i');
        }

        for (var i = 0; i < 100; i++) {
          final result = cache.get('perf_key_$i');
          expect(result, equals('perf_value_$i'));
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100),
            reason: '200次缓存操作应该在100ms内完成',);

        cache.dispose();
        print('⏱️  缓存操作性能测试: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 缓存操作性能测试通过');
      });
    });
  });
}
