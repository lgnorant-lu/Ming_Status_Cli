/*
---------------------------------------------------------------
File name:          string_utils_test.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        字符串工具单元测试 (String utilities unit tests)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/ming_status_cli.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils', () {
    group('命名约定转换', () {
      test('should convert to PascalCase correctly', () {
        expect(StringUtils.toPascalCase('hello_world'), equals('HelloWorld'));
        expect(StringUtils.toPascalCase('user-service'), equals('UserService'));
        expect(
          StringUtils.toPascalCase('my_module_name'),
          equals('MyModuleName'),
        );
        expect(StringUtils.toPascalCase('single'), equals('Single'));
        expect(StringUtils.toPascalCase(''), equals(''));
      });

      test('should convert to camelCase correctly', () {
        expect(StringUtils.toCamelCase('hello_world'), equals('helloWorld'));
        expect(StringUtils.toCamelCase('user-service'), equals('userService'));
        expect(
            StringUtils.toCamelCase('my_module_name'), equals('myModuleName'),);
        expect(StringUtils.toCamelCase('single'), equals('single'));
        expect(StringUtils.toCamelCase(''), equals(''));
      });

      test('should convert to snake_case correctly', () {
        expect(StringUtils.toSnakeCase('HelloWorld'), equals('hello_world'));
        expect(StringUtils.toSnakeCase('userService'), equals('user_service'));
        expect(
            StringUtils.toSnakeCase('MyModuleName'), equals('my_module_name'),);
        expect(StringUtils.toSnakeCase('single'), equals('single'));
        expect(StringUtils.toSnakeCase(''), equals(''));
      });

      test('should convert to kebab-case correctly', () {
        expect(StringUtils.toKebabCase('HelloWorld'), equals('hello-world'));
        expect(StringUtils.toKebabCase('userService'), equals('user-service'));
        expect(
            StringUtils.toKebabCase('MyModuleName'), equals('my-module-name'),);
        expect(StringUtils.toKebabCase('single'), equals('single'));
        expect(StringUtils.toKebabCase(''), equals(''));
      });
    });

    group('验证方法', () {
      test('should validate identifiers correctly', () {
        expect(StringUtils.isValidIdentifier('validName'), isTrue);
        expect(StringUtils.isValidIdentifier('valid_name'), isTrue);
        expect(StringUtils.isValidIdentifier('valid123'), isTrue);
        expect(StringUtils.isValidIdentifier('_validName'), isTrue);

        expect(StringUtils.isValidIdentifier('123invalid'), isFalse);
        expect(StringUtils.isValidIdentifier('invalid-name'), isFalse);
        expect(StringUtils.isValidIdentifier('invalid name'), isFalse);
        expect(StringUtils.isValidIdentifier(''), isFalse);
      });

      test('should validate package names correctly', () {
        expect(StringUtils.isValidPackageName('valid_package'), isTrue);
        expect(StringUtils.isValidPackageName('my_module'), isTrue);
        expect(StringUtils.isValidPackageName('package123'), isTrue);

        expect(StringUtils.isValidPackageName('Invalid_Package'), isFalse);
        expect(StringUtils.isValidPackageName('invalid-package'), isFalse);
        expect(StringUtils.isValidPackageName('123invalid'), isFalse);
        expect(StringUtils.isValidPackageName(''), isFalse);
      });

      test('should validate class names correctly', () {
        expect(StringUtils.isValidClassName('ValidClass'), isTrue);
        expect(StringUtils.isValidClassName('MyModule'), isTrue);
        expect(StringUtils.isValidClassName('Class123'), isTrue);

        expect(StringUtils.isValidClassName('invalidClass'), isFalse);
        expect(StringUtils.isValidClassName('invalid_class'), isFalse);
        expect(StringUtils.isValidClassName('123Invalid'), isFalse);
        expect(StringUtils.isValidClassName(''), isFalse);
      });
    });

    group('字符串检查', () {
      test('should check blank strings correctly', () {
        expect(StringUtils.isBlank(''), isTrue);
        expect(StringUtils.isBlank('   '), isTrue);
        expect(StringUtils.isBlank('\t\n'), isTrue);

        expect(StringUtils.isBlank('hello'), isFalse);
        expect(StringUtils.isBlank(' hello '), isFalse);
      });
    });

    group('文本处理', () {
      test('should truncate text correctly', () {
        expect(StringUtils.truncate('Hello World', 8), equals('Hello...'));
        expect(StringUtils.truncate('Short', 10), equals('Short'));
        expect(StringUtils.truncate('Exact', 5), equals('Exact'));
        expect(StringUtils.truncate('', 5), equals(''));
      });

      test('should format file size correctly', () {
        expect(StringUtils.formatFileSize(0), equals('0 B'));
        expect(StringUtils.formatFileSize(1024), equals('1.0 KB'));
        expect(StringUtils.formatFileSize(1536), equals('1.5 KB'));
        expect(StringUtils.formatFileSize(1048576), equals('1.0 MB'));
      });
    });
  });
}
