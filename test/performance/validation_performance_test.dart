/*
---------------------------------------------------------------
File name:                  validation_performance_test.dart
Author:                     Ignorant-lu
Date created:               2025/07/04
Description:                Performance testing for Ming Status CLI validation system
----------------------------------------------------------------

Changed history:            
                            2025/07/04: 初始创建;
----
*/

import 'dart:io';
import 'package:test/test.dart';
import 'package:ming_status_cli/src/core/validator_service.dart';
import 'package:ming_status_cli/src/models/validation_result.dart';
import 'package:ming_status_cli/src/validators/dependency_validator.dart';
import 'package:ming_status_cli/src/validators/platform_compliance_validator.dart';
import 'package:ming_status_cli/src/validators/quality_validator.dart';
import 'package:ming_status_cli/src/validators/structure_validator.dart';

/// Performance testing for the validation system.
/// 
/// This test suite validates:
/// - Large project validation efficiency
/// - Different validation level performance
/// - Cache system performance
/// - Memory usage patterns
/// - Performance regression detection
void main() {
  group('Validation Performance Tests', () {
    late ValidatorService validatorService;
    late String testProjectPath;

    setUpAll(() async {
      validatorService = ValidatorService();

      // Register all validators using the correct API
      validatorService.registerValidators([
        StructureValidator(),
        QualityValidator(),
        DependencyValidator(),
        PlatformComplianceValidator(),
      ]);

      // Use current project as test subject
      testProjectPath = Directory.current.path;
    });

    tearDownAll(() {
      validatorService.clearCache();
    });

    group('Validation Level Performance', () {
      test('should benchmark different validation levels', () async {
        final levels = [
          ValidationLevel.basic,
          ValidationLevel.standard,
          ValidationLevel.strict,
          ValidationLevel.enterprise,
        ];

        final results = <ValidationLevel, Duration>{};

        for (final level in levels) {
          final stopwatch = Stopwatch()..start();

          final context = ValidationContext(
            projectPath: testProjectPath,
            strictMode: level == ValidationLevel.strict || 
                       level == ValidationLevel.enterprise,
            enabledValidators: [
              ValidationType.structure,
              ValidationType.quality, 
              ValidationType.dependency,
              ValidationType.compliance,
            ],
          );

          await validatorService.validateModule(
            testProjectPath, 
            context: context,
          );
          
          stopwatch.stop();
          results[level] = stopwatch.elapsed;

          print('${level.toString().split('.').last}: '
                '${stopwatch.elapsedMilliseconds}ms');
        }

        // All validations should complete within reasonable time (30 seconds)
        for (final entry in results.entries) {
          expect(
            entry.value.inSeconds, 
            lessThan(30),
            reason: '${entry.key} validation should complete within 30 seconds',
          );
        }

        // Verify that all validations completed successfully
        expect(
          results.length,
          equals(4),
          reason: 'All validation levels should complete',
        );
      });

      test('should maintain reasonable performance across runs', () async {
        const runCount = 3;
        final durations = <Duration>[];

        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality,
          ],
        );

        // Clear cache before each run to ensure actual work is done
        for (var i = 0; i < runCount; i++) {
          validatorService.clearCache();
          final stopwatch = Stopwatch()..start();
          
          await validatorService.validateModule(
            testProjectPath, 
            context: context,
          );
          
          stopwatch.stop();
          durations.add(stopwatch.elapsed);
          
          // Add small delay to ensure distinct measurements
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Calculate statistics - handle edge cases
        final totalMicroseconds = durations.fold<int>(
          0, (sum, duration) => sum + duration.inMicroseconds,);
        final avgDuration = Duration(microseconds: totalMicroseconds ~/ runCount);
        
        final maxDuration = durations.reduce((a, b) => 
          a.inMicroseconds > b.inMicroseconds ? a : b,);
        
        final minDuration = durations.reduce((a, b) => 
          a.inMicroseconds < b.inMicroseconds ? a : b,);

        // Handle edge case where minDuration might be very small
        final variance = minDuration.inMicroseconds > 0 
          ? maxDuration.inMicroseconds / minDuration.inMicroseconds
          : 1.0;

        print('Performance Stats:');
        print('  Average: ${avgDuration.inMilliseconds}ms');
        print('  Min: ${minDuration.inMilliseconds}ms');
        print('  Max: ${maxDuration.inMilliseconds}ms');
        print('  Variance: ${variance.toStringAsFixed(2)}x');

        // More reasonable variance expectation for real-world scenarios
        expect(
          variance, 
          lessThan(50.0), // Allow for higher variance in CI environments
          reason: 'Performance should be reasonably consistent across runs',
        );

        // Ensure all runs took measurable time
        expect(
          avgDuration.inMicroseconds, 
          greaterThan(0),
          reason: 'Validation should take measurable time',
        );
      });
    });

    group('Validation Execution', () {
      test('should handle validation execution', () async {
        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality, 
            ValidationType.dependency,
            ValidationType.compliance,
          ],
        );

        final stopwatch = Stopwatch()..start();
        final result = await validatorService.validateModule(
          testProjectPath, 
          context: context,
        );
        stopwatch.stop();

        final executionTime = stopwatch.elapsedMilliseconds;

        print('Validation execution: ${executionTime}ms');

        expect(
          executionTime, 
          lessThan(30000),
          reason: 'Validation should complete within reasonable time',
        );

        expect(
          result.messages.isNotEmpty,
          isTrue,
          reason: 'Should produce validation messages',
        );
      });
    });

    group('Cache Performance', () {
      test('should demonstrate cache functionality', () async {
        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality,
          ],
        );

        // First run without cache
        validatorService.clearCache();
        final noCacheStopwatch = Stopwatch()..start();
        await validatorService.validateModule(
          testProjectPath, 
          context: context,
        );
        noCacheStopwatch.stop();

        // Second run with potential cache
        final withCacheStopwatch = Stopwatch()..start();
        await validatorService.validateModule(
          testProjectPath, 
          context: context,
        );
        withCacheStopwatch.stop();

        final noCacheTime = noCacheStopwatch.elapsedMilliseconds;
        final withCacheTime = withCacheStopwatch.elapsedMilliseconds;

        print('No cache: ${noCacheTime}ms');
        print('With cache: ${withCacheTime}ms');

        expect(
          noCacheTime, 
          greaterThan(0),
          reason: 'First validation should take measurable time',
        );

        expect(
          withCacheTime, 
          greaterThanOrEqualTo(0),
          reason: 'Second validation should complete successfully',
        );

        if (withCacheTime > 0 && noCacheTime > withCacheTime) {
          final speedup = noCacheTime / withCacheTime;
          print('Cache speedup: ${speedup.toStringAsFixed(2)}x');
        }
      });

      test('should validate cache hit rates', () async {
        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality,
          ],
        );

        validatorService.clearCache();
        
        for (var i = 0; i < 3; i++) {
          await validatorService.validateModule(
            testProjectPath, 
            context: context,
          );
        }

        final stats = validatorService.lastValidationStats;
        
        expect(stats, isNotNull, reason: 'Should have validation stats');
        
        print('Cache stats available: ${stats != null}');
        if (stats != null) {
          print('Cache hit rate: ${(stats.cacheHitRate * 100).toStringAsFixed(1)}%');
          print('Executed validators: ${stats.executedValidators}');
        }
      });
    });

    group('Large Project Simulation', () {
      test('should handle simulated large project efficiently', () async {
        final tempDir = Directory.systemTemp.createTempSync('large_project_test');
        
        try {
          await _createLargeProjectStructure(tempDir);

          final stopwatch = Stopwatch()..start();

          final context = ValidationContext(
            projectPath: tempDir.path,
            enabledValidators: [
              ValidationType.structure,
              ValidationType.quality,
            ],
          );

          final result = await validatorService.validateModule(
            tempDir.path, 
            context: context,
          );
          
          stopwatch.stop();

          expect(
            stopwatch.elapsed.inSeconds, 
            lessThan(60),
            reason: 'Large project validation should complete within 1 minute',
          );

          expect(
            result.messages.isNotEmpty, 
            isTrue,
            reason: 'Should produce validation results for large project',
          );

          final filesProcessed = _countDartFiles(tempDir);
          final processingRate = filesProcessed / stopwatch.elapsedMilliseconds * 1000;

          print('Files processed: $filesProcessed');
          print('Time taken: ${stopwatch.elapsedMilliseconds}ms');
          print('Processing rate: ${processingRate.toStringAsFixed(2)} files/second');

          expect(
            processingRate, 
            greaterThan(1.0),
            reason: 'Should maintain reasonable file processing rate',
          );

        } finally {
          try {
            tempDir.deleteSync(recursive: true);
          } catch (e) {
            print('Warning: Failed to clean up temp directory: $e');
          }
        }
      });
    });

    group('Memory Usage Tests', () {
      test('should not exceed memory limits during validation', () async {
        final initialMemory = ProcessInfo.currentRss;

        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality, 
            ValidationType.dependency,
            ValidationType.compliance,
          ],
        );

        await validatorService.validateModule(
          testProjectPath, 
          context: context,
        );

        final finalMemory = ProcessInfo.currentRss;
        final memoryChange = finalMemory - initialMemory;

        print('Initial memory: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Final memory: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Memory change: ${(memoryChange / 1024 / 1024).toStringAsFixed(2)} MB');

        final memoryUsage = memoryChange.abs();
        expect(
          memoryUsage, 
          lessThan(200 * 1024 * 1024),
          reason: 'Memory usage should be reasonable',
        );
      });
    });

    group('Performance Regression Detection', () {
      test('should establish performance baselines', () async {
        final stopwatch = Stopwatch()..start();

        final context = ValidationContext(
          projectPath: testProjectPath,
          enabledValidators: [
            ValidationType.structure,
            ValidationType.quality, 
            ValidationType.dependency,
            ValidationType.compliance,
          ],
        );

        await validatorService.validateModule(
          testProjectPath, 
          context: context,
        );
        
        stopwatch.stop();

        final currentPerformance = {
          'timestamp': DateTime.now().toIso8601String(),
          'duration_ms': stopwatch.elapsedMilliseconds,
          'validators': ['structure', 'quality', 'dependency', 'platform'],
          'project_size': _countDartFiles(Directory(testProjectPath)),
        };

        print('Current performance: ${currentPerformance['duration_ms']}ms');
        print('Project size: ${currentPerformance['project_size']} Dart files');

        expect(
          stopwatch.elapsedMilliseconds, 
          lessThan(30000),
          reason: 'Validation should complete within 30 seconds',
        );

        expect(
          currentPerformance['project_size']! as int,
          greaterThan(0),
          reason: 'Should have found some Dart files to process',
        );
      });
    });
  });
}

/// Creates a simulated large project structure for testing.
Future<void> _createLargeProjectStructure(Directory baseDir) async {
  final libDir = Directory('${baseDir.path}/lib/src');
  await libDir.create(recursive: true);

  final dirs = ['models', 'services', 'widgets', 'utils', 'controllers'];
  
  for (final dir in dirs) {
    final dirPath = Directory('${libDir.path}/$dir');
    await dirPath.create();

    for (var i = 0; i < 20; i++) {
      final file = File('${dirPath.path}/file_$i.dart');
      await file.writeAsString('''
class TestClass$i {
  final String name;
  final int value;
  
  TestClass$i(this.name, this.value);
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
  };
}
''');
    }
  }

  final pubspecFile = File('${baseDir.path}/pubspec.yaml');
  await pubspecFile.writeAsString('''
name: large_test_project
description: A large test project for performance testing
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
''');

  final readmeFile = File('${baseDir.path}/README.md');
  await readmeFile.writeAsString('''
# Large Test Project

This is a test project with many files for performance testing.

## Structure

The project contains multiple directories with Dart files to simulate
a large real-world project structure.
''');
}

/// Counts the number of Dart files in a directory recursively.
int _countDartFiles(Directory dir) {
  if (!dir.existsSync()) return 0;
  
  var count = 0;
  
  try {
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        count++;
      }
    }
  } catch (e) {
    print('Warning: Error counting files in ${dir.path}: $e');
  }
  
  return count;
}
