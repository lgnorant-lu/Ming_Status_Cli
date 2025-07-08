/*
---------------------------------------------------------------
File name:          validation_result_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        验证结果模型单元测试 (Validation result model unit tests)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/ming_status_cli.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationResult', () {
    test('should initialize with empty state', () {
      final result = ValidationResult();

      expect(result.isValid, isTrue);
      expect(result.endTime, isNull);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.successes, isEmpty);
      expect(result.infos, isEmpty);
    });

    test('should add error messages correctly', () {
      final result = ValidationResult()
        ..addError('Test error')
        ..addError('Another error', file: 'test.dart');

      expect(result.errors, hasLength(2));
      expect(result.isValid, isFalse);
      expect(result.errors.first.message, equals('Test error'));
      expect(result.errors.last.file, equals('test.dart'));
    });

    test('should add warning messages correctly', () {
      final result = ValidationResult()
        ..addWarning('Test warning')
        ..addWarning('Another warning', file: 'test.dart');

      expect(result.warnings, hasLength(2));
      expect(result.isValid, isTrue); // warnings don't make it invalid
      expect(result.warnings.first.message, equals('Test warning'));
      expect(result.warnings.last.file, equals('test.dart'));
    });

    test('should add success messages correctly', () {
      final result = ValidationResult()
        ..addSuccess('Test success')
        ..addSuccess('Another success');

      expect(result.successes, hasLength(2));
      expect(result.successes.first.message, equals('Test success'));
    });

    test('should add info messages correctly', () {
      final result = ValidationResult()
        ..addInfo('Test info')
        ..addInfo('Another info');

      expect(result.infos, hasLength(2));
      expect(result.infos.first.message, equals('Test info'));
    });

    test('should mark as completed', () {
      final result = ValidationResult();

      expect(result.endTime, isNull);

      result.markCompleted();

      expect(result.endTime, isNotNull);
    });

    test('should generate summary correctly', () {
      final result = ValidationResult()
        ..addError('Error 1')
        ..addWarning('Warning 1')
        ..addSuccess('Success 1')
        ..addInfo('Info 1');

      final summary = result.getSummary();

      expect(summary.errorCount, equals(1));
      expect(summary.warningCount, equals(1));
      expect(summary.successCount, equals(1));
      expect(summary.infoCount, equals(1));
    });

    test('should be invalid when has errors', () {
      final result = ValidationResult()
        ..addSuccess('Success')
        ..addWarning('Warning');
      expect(result.isValid, isTrue);

      result.addError('Error');
      expect(result.isValid, isFalse);
    });
  });
}
