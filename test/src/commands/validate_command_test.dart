/*
---------------------------------------------------------------
File name:          validate_command_test.dart
Author:             Ignorant-lu
Date created:       2025/07/04
Last modified:      2025/07/04
Dart Version:       3.32.4
Description:        ValidateCommand集成测试套件 - Task 44.3
---------------------------------------------------------------
Change History:
    2025/07/04: Initial creation - 验证命令集成测试套件实现;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/commands/validate_command.dart';
import 'package:test/test.dart';

void main() {
  group('ValidateCommand Integration Tests', () {
    late ValidateCommand command;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('validate_cmd_test_');
    });

    setUp(() async {
      command = ValidateCommand();
      // 确保每个测试都有清洁的环境
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('validate_cmd_test_');
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Command Basic Properties', () {
      test('should have correct command name', () {
        expect(command.name, equals('validate'));
      });

      test('should have correct description', () {
        expect(command.description, contains('验证模块'));
      });

      test('should have correct aliases', () {
        expect(command.aliases, contains('v'));
        expect(command.aliases, contains('val'));
        expect(command.aliases, contains('check'));
      });

      test('should register all required arguments', () {
        final parser = command.argParser;

        expect(parser.options.containsKey('level'), isTrue);
        expect(parser.options.containsKey('output'), isTrue);
        expect(parser.options.containsKey('validator'), isTrue);
        expect(parser.options.containsKey('strict'), isTrue);
        expect(parser.options.containsKey('fix'), isTrue);
        expect(parser.options.containsKey('watch'), isTrue);
        expect(parser.options.containsKey('cache'), isTrue);
        expect(parser.options.containsKey('parallel'), isTrue);
        expect(parser.options.containsKey('timeout'), isTrue);
        expect(parser.options.containsKey('stats'), isTrue);
        expect(parser.options.containsKey('health-check'), isTrue);
        expect(parser.options.containsKey('output-file'), isTrue);
        expect(parser.options.containsKey('continue-on-error'), isTrue);
        expect(parser.options.containsKey('exclude'), isTrue);
      });
    });

    group('Argument Parsing Tests', () {
      test('should parse health check flag', () {
        final parser = command.argParser;
        final argResults = parser.parse(['--health-check']);

        expect(argResults['health-check'], isTrue);
      });

      test('should parse validation levels', () {
        final parser = command.argParser;

        var argResults = parser.parse(['--level=basic']);
        expect(argResults['level'], equals('basic'));

        argResults = parser.parse(['--level=standard']);
        expect(argResults['level'], equals('standard'));

        argResults = parser.parse(['--level=strict']);
        expect(argResults['level'], equals('strict'));

        argResults = parser.parse(['--level=enterprise']);
        expect(argResults['level'], equals('enterprise'));
      });

      test('should parse output formats', () {
        final parser = command.argParser;

        var argResults = parser.parse(['--output=console']);
        expect(argResults['output'], equals('console'));

        argResults = parser.parse(['--output=json']);
        expect(argResults['output'], equals('json'));

        argResults = parser.parse(['--output=junit']);
        expect(argResults['output'], equals('junit'));

        argResults = parser.parse(['--output=compact']);
        expect(argResults['output'], equals('compact'));
      });

      test('should parse validator selections', () {
        final parser = command.argParser;

        var argResults = parser.parse(['--validator=structure']);
        expect(argResults['validator'], contains('structure'));

        argResults = parser.parse(['--validator=quality']);
        expect(argResults['validator'], contains('quality'));

        argResults = parser.parse(['--validator=dependency']);
        expect(argResults['validator'], contains('dependency'));

        argResults = parser.parse(['--validator=platform']);
        expect(argResults['validator'], contains('platform'));
      });

      test('should parse boolean flags', () {
        final parser = command.argParser;

        var argResults = parser.parse(['--strict']);
        expect(argResults['strict'], isTrue);

        argResults = parser.parse(['--fix']);
        expect(argResults['fix'], isTrue);

        argResults = parser.parse(['--watch']);
        expect(argResults['watch'], isTrue);

        argResults = parser.parse(['--stats']);
        expect(argResults['stats'], isTrue);

        argResults = parser.parse(['--continue-on-error']);
        expect(argResults['continue-on-error'], isTrue);
      });

      test('should parse negated flags', () {
        final parser = command.argParser;

        var argResults = parser.parse(['--no-cache']);
        expect(argResults['cache'], isFalse);

        argResults = parser.parse(['--no-parallel']);
        expect(argResults['parallel'], isFalse);
      });

      test('should use default values', () {
        final parser = command.argParser;
        final argResults = parser.parse([]);

        expect(argResults['level'], equals('standard'));
        expect(argResults['output'], equals('console'));
        expect(argResults['strict'], isFalse);
        expect(argResults['fix'], isFalse);
        expect(argResults['watch'], isFalse);
        expect(argResults['cache'], isTrue);
        expect(argResults['parallel'], isTrue);
        expect(argResults['stats'], isFalse);
        expect(argResults['health-check'], isFalse);
        expect(argResults['continue-on-error'], isFalse);
        expect(argResults['timeout'], equals('300'));
      });

      test('should handle complex argument combinations', () {
        final parser = command.argParser;
        final argResults = parser.parse([
          '--level=enterprise',
          '--output=json',
          '--strict',
          '--fix',
          '--stats',
          '--validator=structure',
          '--validator=quality',
          '--timeout=600',
          '--output-file=results.json',
          '--exclude=*.g.dart',
          tempDir.path,
        ]);

        expect(argResults['level'], equals('enterprise'));
        expect(argResults['output'], equals('json'));
        expect(argResults['strict'], isTrue);
        expect(argResults['fix'], isTrue);
        expect(argResults['stats'], isTrue);
        expect(argResults['validator'], contains('structure'));
        expect(argResults['validator'], contains('quality'));
        expect(argResults['timeout'], equals('600'));
        expect(argResults['output-file'], equals('results.json'));
        expect(argResults['exclude'], contains('*.g.dart'));
        expect(argResults.rest, contains(tempDir.path));
      });
    });

    group('Validation Service Integration', () {
      test('should create validator service with default validators', () {
        final validatorService = command.validatorService;
        expect(validatorService, isNotNull);
        expect(validatorService.registeredValidators, hasLength(4));

        final validatorNames = validatorService.registeredValidators
            .map((v) => v.validatorName)
            .toList();
        expect(validatorNames, contains('structure'));
        expect(validatorNames, contains('quality'));
        expect(validatorNames, contains('dependency'));
        expect(validatorNames, contains('platform'));
      });

      test('should support health check', () async {
        final validatorService = command.validatorService;
        final healthStatus = await validatorService.checkValidatorsHealth();

        expect(healthStatus, isNotEmpty);
        expect(healthStatus.keys, hasLength(4));
        expect(healthStatus.keys, contains('structure'));
        expect(healthStatus.keys, contains('quality'));
        expect(healthStatus.keys, contains('dependency'));
        expect(healthStatus.keys, contains('platform'));
      });
    });

    group('Error Handling', () {
      test('should handle invalid validation level', () {
        final parser = command.argParser;

        expect(
          () => parser.parse(['--level=invalid']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle invalid output format', () {
        final parser = command.argParser;

        expect(
          () => parser.parse(['--output=invalid']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle invalid validator type', () {
        final parser = command.argParser;

        expect(
          () => parser.parse(['--validator=invalid']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Path Handling', () {
      test('should handle current directory when no path specified', () {
        final parser = command.argParser;
        final argResults = parser.parse([]);

        expect(argResults.rest, isEmpty);
      });

      test('should handle specific path argument', () {
        final parser = command.argParser;
        final argResults = parser.parse([tempDir.path]);

        expect(argResults.rest, hasLength(1));
        expect(argResults.rest.first, equals(tempDir.path));
      });

      test('should handle multiple path arguments', () {
        final parser = command.argParser;
        final argResults = parser.parse([tempDir.path, '/another/path']);

        expect(argResults.rest, hasLength(2));
        expect(argResults.rest.first, equals(tempDir.path));
        expect(argResults.rest.last, equals('/another/path'));
      });
    });

    group('Help Information', () {
      test('should provide usage information', () {
        final parser = command.argParser;
        final usage = parser.usage;

        expect(usage, contains('level'));
        expect(usage, contains('output'));
        expect(usage, contains('validator'));
        expect(usage, contains('strict'));
        expect(usage, contains('fix'));
        expect(usage, contains('watch'));
        expect(usage, contains('cache'));
        expect(usage, contains('parallel'));
        expect(usage, contains('timeout'));
        expect(usage, contains('stats'));
        expect(usage, contains('health-check'));
        expect(usage, contains('output-file'));
        expect(usage, contains('continue-on-error'));
        expect(usage, contains('exclude'));
      });
    });
  });
}
