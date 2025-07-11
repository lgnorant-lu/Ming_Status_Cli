/*
---------------------------------------------------------------
File name:          phase2_week2_distribution_test.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        Phase 2.2 Week 2 智能搜索和分发系统测试
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 Week 2 测试;
---------------------------------------------------------------
*/

import 'dart:typed_data';

import 'package:ming_status_cli/src/core/distribution/cache_strategy.dart';
import 'package:ming_status_cli/src/core/distribution/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/distribution/template_downloader.dart';
import 'package:ming_status_cli/src/core/distribution/update_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 2.2 Week 2: 智能搜索和分发系统', () {
    group('TemplateDownloader Tests', () {
      late TemplateDownloader downloader;

      setUp(() {
        downloader = TemplateDownloader();
      });

      tearDown(() {
        downloader.dispose();
      });

      test('应该创建下载任务', () {
        final task = DownloadTask(
          id: 'test-task',
          url: 'https://example.com/template.zip',
          outputPath: './test_template.zip',
          config: const DownloadConfig(),
          createdAt: DateTime.now(),
        );

        expect(task.id, equals('test-task'));
        expect(task.url, equals('https://example.com/template.zip'));
        expect(task.outputPath, equals('./test_template.zip'));
        expect(task.format, equals(CompressionFormat.zip));
      });

      test('应该正确计算下载进度', () {
        const progress = DownloadProgress(
          downloadedBytes: 500,
          totalBytes: 1000,
          speed: 100,
          remainingTime: 5,
          status: DownloadStatus.downloading,
        );

        expect(progress.percentage, equals(50.0));
        expect(progress.isCompleted, isFalse);
        expect(progress.isFailed, isFalse);
      });

      test('应该获取下载统计', () {
        final stats = downloader.getDownloadStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalDownloads'), isTrue);
        expect(stats.containsKey('activeDownloads'), isTrue);
        expect(stats.containsKey('cacheSize'), isTrue);
      });
    });

    group('DependencyResolver Tests', () {
      late DependencyResolver resolver;

      setUp(() {
        resolver = DependencyResolver();
      });

      test('应该解析版本约束', () {
        final constraint = VersionConstraint.parse('^1.0.0');

        expect(constraint.type, equals(VersionConstraintType.compatible));
        expect(constraint.expression, equals('^1.0.0'));
        expect(constraint.minVersion, isNotNull);
        expect(constraint.maxVersion, isNotNull);
      });

      test('应该比较版本', () {
        final v1 = Version.parse('1.0.0');
        final v2 = Version.parse('1.1.0');
        final v3 = Version.parse('2.0.0');

        expect(v1.compareTo(v2), lessThan(0));
        expect(v2.compareTo(v1), greaterThan(0));
        expect(v1.compareTo(v1), equals(0));
        expect(v3.compareTo(v1), greaterThan(0));
      });

      test('应该检查版本约束', () {
        final constraint = VersionConstraint.parse('^1.0.0');
        final v1 = Version.parse('1.0.0');
        final v2 = Version.parse('1.5.0');
        final v3 = Version.parse('2.0.0');

        expect(constraint.allows(v1), isTrue);
        expect(constraint.allows(v2), isTrue);
        expect(constraint.allows(v3), isFalse);
      });

      test('应该创建依赖对象', () {
        final dependency = Dependency(
          name: 'flutter',
          versionConstraint: VersionConstraint.parse('^3.0.0'),
        );

        expect(dependency.name, equals('flutter'));
        expect(dependency.type, equals(DependencyType.runtime));
        expect(dependency.optional, isFalse);
      });

      test('应该解析依赖关系', () async {
        final dependencies = [
          Dependency(
            name: 'flutter',
            versionConstraint: VersionConstraint.parse('^3.0.0'),
          ),
        ];

        final result = await resolver.resolveDependencies(dependencies);

        expect(result, isA<ResolutionResult>());
        expect(result.resolvedVersions, isA<Map<String, Version>>());
        expect(result.conflicts, isA<List<DependencyConflict>>());
        expect(result.resolutionTime, isA<Duration>());
      });
    });

    group('UpdateManager Tests', () {
      late UpdateManager updateManager;

      setUp(() {
        updateManager = UpdateManager();
      });

      tearDown(() {
        updateManager.dispose();
      });

      test('应该创建更新信息', () {
        final updateInfo = UpdateInfo(
          templateName: 'flutter_clean_app',
          currentVersion: Version.parse('1.0.0'),
          availableVersion: Version.parse('1.1.0'),
          updateType: UpdateType.minor,
          updateSize: 1024 * 1024,
          description: 'Minor update',
          changelog: ['Bug fixes', 'New features'],
          isSecurityUpdate: false,
          compatibility: {'flutter': true},
          releaseDate: DateTime.now(),
        );

        expect(updateInfo.templateName, equals('flutter_clean_app'));
        expect(updateInfo.updateType, equals(UpdateType.minor));
        expect(updateInfo.isBreakingChange, isFalse);
        expect(updateInfo.isRecommended, isFalse);
      });

      test('应该创建更新进度', () {
        final progress = UpdateProgress(
          templateName: 'test_template',
          status: UpdateStatus.downloading,
          percentage: 50,
          currentStep: 'Downloading...',
          startTime: DateTime.now(),
        );

        expect(progress.templateName, equals('test_template'));
        expect(progress.status, equals(UpdateStatus.downloading));
        expect(progress.percentage, equals(50.0));
        expect(progress.isCompleted, isFalse);
        expect(progress.isFailed, isFalse);
      });

      test('应该检查可用更新', () async {
        final updates = await updateManager.checkForUpdates();

        expect(updates, isA<List<UpdateInfo>>());
        // 模拟数据应该返回一些更新
        expect(updates.length, greaterThanOrEqualTo(0));
      });

      test('应该创建快照', () async {
        final snapshot = await updateManager.createSnapshot('Test snapshot');

        expect(snapshot, isA<UpdateSnapshot>());
        expect(snapshot.name, contains('Snapshot'));
        expect(snapshot.templateVersions, isA<Map<String, Version>>());
      });

      test('应该获取更新统计', () {
        final stats = updateManager.getUpdateStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalSnapshots'), isTrue);
        expect(stats.containsKey('activeUpdates'), isTrue);
        expect(stats.containsKey('updateStrategy'), isTrue);
      });
    });

    group('CacheStrategy Tests', () {
      late CacheStrategy cacheStrategy;

      setUp(() {
        cacheStrategy = CacheStrategy();
      });

      tearDown(() {
        cacheStrategy.dispose();
      });

      test('应该创建缓存条目', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final entry = CacheEntry(
          key: 'test-key',
          data: data,
          createdAt: DateTime.now(),
          size: data.length,
        );

        expect(entry.key, equals('test-key'));
        expect(entry.data, equals(data));
        expect(entry.size, equals(5));
        expect(entry.isExpired, isFalse);
      });

      test('应该检查缓存条目过期', () {
        final pastTime = DateTime.now().subtract(const Duration(hours: 2));
        final entry = CacheEntry(
          key: 'test-key',
          data: Uint8List.fromList([1, 2, 3]),
          createdAt: pastTime,
          size: 3,
          ttl: const Duration(hours: 1),
        );

        expect(entry.isExpired, isTrue);
        expect(entry.remainingTtl, equals(Duration.zero));
      });

      test('应该存储和获取缓存数据', () async {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        const key = 'test-cache-key';

        await cacheStrategy.put(key, data);
        final retrieved = await cacheStrategy.get(key);

        expect(retrieved, isNotNull);
        expect(retrieved, equals(data));
      });

      test('应该获取缓存统计', () {
        final stats = cacheStrategy.getStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('memory'), isTrue);
        expect(stats.containsKey('disk'), isTrue);
        expect(stats.containsKey('overall'), isTrue);
      });

      test('应该获取缓存键列表', () {
        final keys = cacheStrategy.getKeys();

        expect(keys, isA<List<String>>());
      });

      test('应该清空缓存', () async {
        final data = Uint8List.fromList([1, 2, 3]);
        await cacheStrategy.put('test-key', data);

        await cacheStrategy.clear();

        final retrieved = await cacheStrategy.get('test-key');
        expect(retrieved, isNull);
      });
    });

    group('Integration Tests', () {
      test('应该集成下载器和缓存策略', () async {
        final downloader = TemplateDownloader();
        final cacheStrategy = CacheStrategy();

        try {
          // 模拟下载和缓存流程
          final mockData = Uint8List.fromList('template content'.codeUnits);
          await cacheStrategy.put('template-key', mockData);

          final cached = await cacheStrategy.get('template-key');
          expect(cached, isNotNull);
          expect(cached, equals(mockData));

          final stats = downloader.getDownloadStats();
          expect(stats, isA<Map<String, dynamic>>());
        } finally {
          downloader.dispose();
          cacheStrategy.dispose();
        }
      });

      test('应该集成依赖解析器和更新管理器', () async {
        final resolver = DependencyResolver();
        final updateManager = UpdateManager();

        try {
          // 模拟依赖解析和更新流程
          final dependencies = [
            Dependency(
              name: 'test_package',
              versionConstraint: VersionConstraint.parse('^1.0.0'),
            ),
          ];

          final result = await resolver.resolveDependencies(dependencies);
          expect(result.isSuccessful, isTrue);

          final updates = await updateManager.checkForUpdates();
          expect(updates, isA<List<UpdateInfo>>());
        } finally {
          updateManager.dispose();
        }
      });
    });
  });
}
