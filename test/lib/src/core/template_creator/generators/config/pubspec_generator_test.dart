/*
---------------------------------------------------------------
File name:          pubspec_generator_test.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        PubspecGenerator类测试文件 (PubspecGenerator Class Tests)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - pubspec生成器测试;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/config/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('PubspecGenerator', () {
    late PubspecGenerator generator;
    late ScaffoldConfig config;
    late Directory tempDir;

    setUp(() async {
      generator = const PubspecGenerator();
      config = const ScaffoldConfig(
        templateName: 'test_flutter_app',
        templateType: TemplateType.full,
        author: 'Test Author',
        description: 'A test Flutter application',
        framework: TemplateFramework.flutter,
        complexity: TemplateComplexity.medium,
      );
      
      // 创建临时目录
      tempDir = await Directory.systemTemp.createTemp('pubspec_test_');
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should return correct file name', () {
      expect(generator.getFileName(), equals('pubspec.yaml'));
    });

    test('should generate Flutter pubspec content', () {
      final content = generator.generateContent(config);
      
      expect(content, contains('name: test_flutter_app'));
      expect(content, contains('description: A test Flutter application'));
      expect(content, contains('flutter:'));
      expect(content, contains('sdk: flutter'));
      expect(content, contains('flutter_riverpod:'));
      expect(content, contains('go_router:'));
      expect(content, contains('build_runner:'));
      expect(content, contains('uses-material-design: true'));
    });

    test('should generate Dart pubspec content for dart framework', () {
      final dartConfig = config.copyWith(framework: TemplateFramework.dart);
      final content = generator.generateContent(dartConfig);
      
      expect(content, contains('name: test_flutter_app'));
      expect(content, contains('description: A test Flutter application'));
      expect(content, isNot(contains('flutter:')));
      expect(content, isNot(contains('sdk: flutter')));
      expect(content, contains('freezed_annotation:'));
      expect(content, contains('json_annotation:'));
    });

    test('should include networking dependencies for service templates', () {
      final serviceConfig = config.copyWith(templateType: TemplateType.service);
      final content = generator.generateContent(serviceConfig);
      
      expect(content, contains('dio:'));
      expect(content, contains('retrofit:'));
      expect(content, contains('retrofit_generator:'));
    });

    test('should include storage dependencies for data templates', () {
      final dataConfig = config.copyWith(templateType: TemplateType.data);
      final content = generator.generateContent(dataConfig);
      
      expect(content, contains('shared_preferences:'));
      expect(content, contains('hive:'));
      expect(content, contains('hive_flutter:'));
    });

    test('should include UI components for UI templates', () {
      final uiConfig = config.copyWith(templateType: TemplateType.ui);
      final content = generator.generateContent(uiConfig);
      
      expect(content, contains('flutter_svg:'));
      expect(content, contains('cached_network_image:'));
      expect(content, contains('shimmer:'));
    });

    test('should generate file successfully', () async {
      final filePath = await generator.generateFile(tempDir.path, config);
      final file = File(filePath);
      
      expect(await file.exists(), isTrue);
      expect(path.basename(filePath), equals('pubspec.yaml'));
      
      final content = await file.readAsString();
      expect(content, contains('name: test_flutter_app'));
      expect(content, contains('description: A test Flutter application'));
    });

    test('should validate file correctly', () async {
      // 先生成文件
      await generator.generateFile(tempDir.path, config);
      
      // 验证文件
      final validation = await generator.validateFile(tempDir.path, config);
      
      expect(validation.isValid, isTrue);
      expect(validation.fileName, equals('pubspec.yaml'));
    });

    test('should detect missing file', () async {
      final validation = await generator.validateFile(tempDir.path, config);
      
      expect(validation.isMissing, isTrue);
      expect(validation.fileName, equals('pubspec.yaml'));
    });

    test('should detect outdated file', () async {
      // 生成文件
      await generator.generateFile(tempDir.path, config);
      
      // 修改配置
      final newConfig = config.copyWith(description: 'Updated description');
      
      // 验证文件（应该检测到过期）
      final validation = await generator.validateFile(tempDir.path, newConfig);
      
      expect(validation.isOutdated, isTrue);
    });

    test('should update file when needed', () async {
      // 生成初始文件
      await generator.generateFile(tempDir.path, config);
      
      // 修改配置
      final newConfig = config.copyWith(description: 'Updated description');
      
      // 更新文件
      final updated = await generator.updateFile(tempDir.path, newConfig);
      expect(updated, isTrue);
      
      // 验证更新后的内容
      final filePath = path.join(tempDir.path, 'pubspec.yaml');
      final content = await File(filePath).readAsString();
      expect(content, contains('Updated description'));
    });

    test('should not update file when not needed', () async {
      // 生成文件
      await generator.generateFile(tempDir.path, config);
      
      // 尝试更新（配置未变）
      final updated = await generator.updateFile(tempDir.path, config);
      expect(updated, isFalse);
    });

    test('should backup and restore file', () async {
      // 生成文件
      await generator.generateFile(tempDir.path, config);
      
      // 备份文件
      final backupPath = await generator.backupFile(tempDir.path);
      expect(backupPath, isNotNull);
      expect(await File(backupPath!).exists(), isTrue);
      
      // 删除原文件
      final originalPath = path.join(tempDir.path, 'pubspec.yaml');
      await File(originalPath).delete();
      expect(await File(originalPath).exists(), isFalse);
      
      // 恢复文件
      final restored = await generator.restoreFile(tempDir.path, backupPath);
      expect(restored, isTrue);
      expect(await File(originalPath).exists(), isTrue);
    });

    test('should get file info correctly', () async {
      // 获取不存在文件的信息
      var fileInfo = await generator.getFileInfo(tempDir.path);
      expect(fileInfo.exists, isFalse);
      expect(fileInfo.fileName, equals('pubspec.yaml'));
      
      // 生成文件后获取信息
      await generator.generateFile(tempDir.path, config);
      fileInfo = await generator.getFileInfo(tempDir.path);
      expect(fileInfo.exists, isTrue);
      expect(fileInfo.size, greaterThan(0));
      expect(fileInfo.lastModified, isNotNull);
    });
  });
}
