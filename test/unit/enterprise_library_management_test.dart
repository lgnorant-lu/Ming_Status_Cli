/*
---------------------------------------------------------------
File name:          enterprise_library_management_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板库管理系统单元测试 (Enterprise Library Management Unit Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板库管理系统测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/library/library_manager.dart';
import 'package:ming_status_cli/src/core/library/metadata_manager.dart';
import 'package:ming_status_cli/src/core/library/version_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Library Manager Tests', () {
    late LibraryManager manager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('library_test_');
      manager = LibraryManager(configPath: '${tempDir.path}/config.json');
      await manager.initialize();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('LibraryConfig should be created correctly', () {
      const config = LibraryConfig(
        id: 'test_lib',
        name: 'Test Library',
        type: LibraryType.enterprise,
        url: 'https://example.com/templates',
        description: 'Test enterprise library',
        priority: 10,
        permissions: {LibraryPermission.read, LibraryPermission.write},
      );

      expect(config.id, equals('test_lib'));
      expect(config.name, equals('Test Library'));
      expect(config.type, equals(LibraryType.enterprise));
      expect(config.url, equals('https://example.com/templates'));
      expect(config.description, equals('Test enterprise library'));
      expect(config.priority, equals(10));
      expect(config.permissions, hasLength(2));
      expect(config.status, equals(LibraryStatus.active));
      expect(config.canRead, isTrue);
      expect(config.canWrite, isTrue);
      expect(config.canManage, isFalse);
      expect(config.isOwner, isFalse);
      expect(config.isActive, isTrue);
    });

    test('LibraryManager should add and retrieve libraries', () async {
      const config = LibraryConfig(
        id: 'enterprise_lib',
        name: 'Enterprise Library',
        type: LibraryType.enterprise,
        url: 'https://enterprise.example.com/templates',
        description: 'Enterprise template library',
        priority: 5,
      );

      final addResult = await manager.addLibrary(config);
      expect(addResult, isTrue);

      final retrievedConfig = manager.getLibrary('enterprise_lib');
      expect(retrievedConfig, isNotNull);
      expect(retrievedConfig!.name, equals('Enterprise Library'));
      expect(retrievedConfig.type, equals(LibraryType.enterprise));
      expect(retrievedConfig.priority, equals(5));
    });

    test('LibraryManager should filter libraries correctly', () async {
      final configs = [
        const LibraryConfig(
          id: 'official_lib',
          name: 'Official Library',
          type: LibraryType.official,
          url: 'https://official.example.com',
          priority: 1,
        ),
        const LibraryConfig(
          id: 'enterprise_lib',
          name: 'Enterprise Library',
          type: LibraryType.enterprise,
          url: 'https://enterprise.example.com',
          priority: 5,
          permissions: {LibraryPermission.read, LibraryPermission.write},
        ),
        const LibraryConfig(
          id: 'personal_lib',
          name: 'Personal Library',
          type: LibraryType.personal,
          url: 'https://personal.example.com',
          priority: 10,
          status: LibraryStatus.readonly,
        ),
      ];

      for (final config in configs) {
        await manager.addLibrary(config);
      }

      // 按类型过滤
      final enterpriseLibs = manager.getLibraries(type: LibraryType.enterprise);
      expect(enterpriseLibs, hasLength(1));
      expect(enterpriseLibs.first.name, equals('Enterprise Library'));

      // 按状态过滤 (包括默认的官方库)
      final activeLibs = manager.getLibraries(status: LibraryStatus.active);
      expect(activeLibs, hasLength(3)); // 包括默认的官方库

      // 按权限过滤
      final writeLibs = manager.getLibraries(
        requiredPermissions: {LibraryPermission.write},
      );
      expect(writeLibs, hasLength(1));
      expect(writeLibs.first.name, equals('Enterprise Library'));

      // 检查优先级排序
      final allLibs = manager.getLibraries();
      expect(allLibs.first.priority, equals(1)); // 官方库优先级最高
      expect(allLibs.last.priority, equals(10)); // 个人库优先级最低
    });

    test('LibraryManager should update library configuration', () async {
      const config = LibraryConfig(
        id: 'update_test',
        name: 'Update Test Library',
        type: LibraryType.team,
        url: 'https://team.example.com',
        priority: 15,
      );

      await manager.addLibrary(config);

      final updateResult = await manager.updateLibrary('update_test', {
        'name': 'Updated Library Name',
        'priority': 20,
        'status': 'readonly',
      });

      expect(updateResult, isTrue);

      final updatedConfig = manager.getLibrary('update_test');
      expect(updatedConfig, isNotNull);
      expect(updatedConfig!.name, equals('Updated Library Name'));
      expect(updatedConfig.priority, equals(20));
      expect(updatedConfig.status, equals(LibraryStatus.readonly));
    });

    test('LibraryManager should remove libraries', () async {
      const config = LibraryConfig(
        id: 'remove_test',
        name: 'Remove Test Library',
        type: LibraryType.personal,
        url: 'https://remove.example.com',
      );

      await manager.addLibrary(config);

      final beforeRemoval = manager.getLibrary('remove_test');
      expect(beforeRemoval, isNotNull);

      final removeResult = await manager.removeLibrary('remove_test');
      expect(removeResult, isTrue);

      final afterRemoval = manager.getLibrary('remove_test');
      expect(afterRemoval, isNull);
    });

    test('LibraryManager should handle sync operations', () async {
      const config = LibraryConfig(
        id: 'sync_test',
        name: 'Sync Test Library',
        type: LibraryType.enterprise,
        url: 'https://sync.example.com',
      );

      await manager.addLibrary(config);

      final syncResult = await manager.syncLibrary('sync_test');
      expect(syncResult.success, isTrue);
      expect(syncResult.libraryId, equals('sync_test'));
      expect(syncResult.totalChanges, equals(0)); // 基础实现返回0变更
    });
  });

  group('Version Manager Tests', () {
    late VersionManager versionManager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('version_test_');
      versionManager = VersionManager(versionsPath: tempDir.path);
      await versionManager.initialize();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('SemanticVersion should parse correctly', () {
      final version1 = SemanticVersion.parse('1.2.3');
      expect(version1.major, equals(1));
      expect(version1.minor, equals(2));
      expect(version1.patch, equals(3));
      expect(version1.prerelease, isNull);
      expect(version1.build, isNull);
      expect(version1.isStable, isTrue);
      expect(version1.isPrerelease, isFalse);

      final version2 = SemanticVersion.parse('2.0.0-beta.1+build.123');
      expect(version2.major, equals(2));
      expect(version2.minor, equals(0));
      expect(version2.patch, equals(0));
      expect(version2.prerelease, equals('beta.1'));
      expect(version2.build, equals('build.123'));
      expect(version2.isStable, isFalse);
      expect(version2.isPrerelease, isTrue);
    });

    test('SemanticVersion should compare correctly', () {
      final v1 = SemanticVersion.parse('1.0.0');
      final v2 = SemanticVersion.parse('1.0.1');
      final v3 = SemanticVersion.parse('1.1.0');
      final v4 = SemanticVersion.parse('2.0.0');
      final v5 = SemanticVersion.parse('2.0.0-beta');

      expect(v1.compareTo(v2), lessThan(0));
      expect(v2.compareTo(v3), lessThan(0));
      expect(v3.compareTo(v4), lessThan(0));
      expect(v5.compareTo(v4), lessThan(0)); // 预发布版本小于正式版本
      expect(v1.compareTo(v1), equals(0));
    });

    test('SemanticVersion should handle version constraints', () {
      final version = SemanticVersion.parse('1.2.3');

      expect(version.satisfies('^1.0.0'), isTrue);
      expect(version.satisfies('^1.2.0'), isTrue);
      expect(version.satisfies('^2.0.0'), isFalse);
      expect(version.satisfies('~1.2.0'), isTrue);
      expect(version.satisfies('~1.1.0'), isFalse);
      expect(version.satisfies('>=1.0.0'), isTrue);
      expect(version.satisfies('<=2.0.0'), isTrue);
      expect(version.satisfies('>1.2.3'), isFalse);
      expect(version.satisfies('<1.2.3'), isFalse);
      expect(version.satisfies('1.2.3'), isTrue);
    });

    test('SemanticVersion should increment correctly', () {
      final version = SemanticVersion.parse('1.2.3');

      final majorIncrement = version.incrementMajor();
      expect(majorIncrement.toString(), equals('2.0.0'));

      final minorIncrement = version.incrementMinor();
      expect(minorIncrement.toString(), equals('1.3.0'));

      final patchIncrement = version.incrementPatch();
      expect(patchIncrement.toString(), equals('1.2.4'));
    });

    test('VersionManager should add and retrieve versions', () async {
      final version = VersionInfo(
        version: SemanticVersion.parse('1.0.0'),
        branch: VersionBranch.stable,
        releaseDate: DateTime.now(),
        changelog: 'Initial release',
        author: 'Test Author',
      );

      final addResult =
          await versionManager.addVersion('test_template', version);
      expect(addResult, isTrue);

      final versions = versionManager.getVersions('test_template');
      expect(versions, hasLength(1));
      expect(versions.first.version.toString(), equals('1.0.0'));
      expect(versions.first.branch, equals(VersionBranch.stable));
      expect(versions.first.changelog, equals('Initial release'));

      final latestVersion = versionManager.getLatestVersion('test_template');
      expect(latestVersion, isNotNull);
      expect(latestVersion!.version.toString(), equals('1.0.0'));
    });

    test('VersionManager should handle multiple versions', () async {
      final versions = [
        VersionInfo(
          version: SemanticVersion.parse('1.0.0'),
          branch: VersionBranch.stable,
          releaseDate: DateTime(2023),
        ),
        VersionInfo(
          version: SemanticVersion.parse('1.1.0'),
          branch: VersionBranch.stable,
          releaseDate: DateTime(2023, 6),
        ),
        VersionInfo(
          version: SemanticVersion.parse('2.0.0-beta'),
          branch: VersionBranch.testing,
          releaseDate: DateTime(2023, 12),
        ),
      ];

      for (final version in versions) {
        await versionManager.addVersion('multi_template', version);
      }

      final allVersions = versionManager.getVersions('multi_template');
      expect(allVersions, hasLength(3));

      // 检查版本排序 (降序)
      expect(allVersions[0].version.toString(), equals('2.0.0-beta'));
      expect(allVersions[1].version.toString(), equals('1.1.0'));
      expect(allVersions[2].version.toString(), equals('1.0.0'));

      // 获取最新稳定版本
      final latestStable =
          versionManager.getLatestVersion('multi_template');
      expect(latestStable, isNotNull);
      expect(latestStable!.version.toString(), equals('1.1.0'));

      // 获取指定分支版本
      final testingVersions = versionManager.getVersions('multi_template',
          branch: VersionBranch.testing,);
      expect(testingVersions, hasLength(1));
      expect(testingVersions.first.version.toString(), equals('2.0.0-beta'));
    });

    test('VersionManager should check compatibility', () async {
      final v1 = VersionInfo(
        version: SemanticVersion.parse('1.0.0'),
        branch: VersionBranch.stable,
        releaseDate: DateTime.now(),
      );

      final v2 = VersionInfo(
        version: SemanticVersion.parse('1.1.0'),
        branch: VersionBranch.stable,
        releaseDate: DateTime.now(),
      );

      final v3 = VersionInfo(
        version: SemanticVersion.parse('2.0.0'),
        branch: VersionBranch.stable,
        releaseDate: DateTime.now(),
      );

      await versionManager.addVersion('compat_template', v1);
      await versionManager.addVersion('compat_template', v2);
      await versionManager.addVersion('compat_template', v3);

      // 兼容的升级 (次版本)
      final compatResult1 = await versionManager.checkCompatibility(
        'compat_template',
        SemanticVersion.parse('1.0.0'),
        SemanticVersion.parse('1.1.0'),
      );
      expect(compatResult1.isCompatible, isTrue);
      expect(compatResult1.issues, isEmpty);

      // 主版本升级 (可能有破坏性变更)
      final compatResult2 = await versionManager.checkCompatibility(
        'compat_template',
        SemanticVersion.parse('1.1.0'),
        SemanticVersion.parse('2.0.0'),
      );
      expect(compatResult2.isCompatible, isTrue);
      expect(compatResult2.warnings, isNotEmpty);

      // 版本降级 (不支持)
      final compatResult3 = await versionManager.checkCompatibility(
        'compat_template',
        SemanticVersion.parse('2.0.0'),
        SemanticVersion.parse('1.0.0'),
      );
      expect(compatResult3.isCompatible, isFalse);
      expect(compatResult3.issues, isNotEmpty);
    });
  });

  group('Metadata Manager Tests', () {
    late MetadataManager metadataManager;

    setUp(() async {
      metadataManager = MetadataManager();
      await metadataManager.initialize();
    });

    test('MetadataFieldDefinition should be created correctly', () {
      const field = MetadataFieldDefinition(
        name: 'test_field',
        type: MetadataFieldType.string,
        required: true,
        description: 'Test field description',
        defaultValue: 'default_value',
        validationRules: ['min_length:3', 'max_length:50'],
      );

      expect(field.name, equals('test_field'));
      expect(field.type, equals(MetadataFieldType.string));
      expect(field.required, isTrue);
      expect(field.description, equals('Test field description'));
      expect(field.defaultValue, equals('default_value'));
      expect(field.validationRules, hasLength(2));
    });

    test('MetadataSchema should be created correctly', () {
      const schema = MetadataSchema(
        name: 'test_schema',
        version: '1.0.0',
        type: MetadataType.enterprise,
        fields: [
          MetadataFieldDefinition(
            name: 'name',
            type: MetadataFieldType.string,
            required: true,
          ),
          MetadataFieldDefinition(
            name: 'version',
            type: MetadataFieldType.string,
            required: true,
          ),
        ],
        description: 'Test schema',
      );

      expect(schema.name, equals('test_schema'));
      expect(schema.version, equals('1.0.0'));
      expect(schema.type, equals(MetadataType.enterprise));
      expect(schema.fields, hasLength(2));
      expect(schema.description, equals('Test schema'));
    });

    test('MetadataManager should validate metadata correctly', () async {
      // 测试基础模式验证
      final validMetadata = {
        'name': 'Test Template',
        'version': '1.0.0',
        'description': 'Test description',
      };

      final validResult = await metadataManager.validateMetadata(
        'test_template',
        validMetadata,
        'basic',
      );

      expect(validResult.isValid, isTrue);
      expect(validResult.errors, isEmpty);
      expect(validResult.missingFields, isEmpty);

      // 测试缺少必需字段
      final invalidMetadata = {
        'description': 'Test description',
      };

      final invalidResult = await metadataManager.validateMetadata(
        'test_template',
        invalidMetadata,
        'basic',
      );

      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors, isNotEmpty);
      expect(invalidResult.missingFields, contains('name'));
      expect(invalidResult.missingFields, contains('version'));
    });

    test('EnterpriseTemplateMetadata should be created correctly', () {
      final metadata = EnterpriseTemplateMetadata(
        templateId: 'test_template',
        name: 'Test Template',
        version: SemanticVersion.parse('1.0.0'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: 'Test enterprise template',
        author: 'Test Author',
        organization: 'Test Organization',
        department: 'Engineering',
        category: 'web',
        tags: ['flutter', 'web', 'enterprise'],
        platforms: ['web', 'mobile'],
        frameworks: ['flutter'],
        languages: ['dart'],
        rating: 4.5,
        downloadCount: 1000,
      );

      expect(metadata.templateId, equals('test_template'));
      expect(metadata.name, equals('Test Template'));
      expect(metadata.version.toString(), equals('1.0.0'));
      expect(metadata.description, equals('Test enterprise template'));
      expect(metadata.author, equals('Test Author'));
      expect(metadata.organization, equals('Test Organization'));
      expect(metadata.department, equals('Engineering'));
      expect(metadata.category, equals('web'));
      expect(metadata.tags, hasLength(3));
      expect(metadata.platforms, hasLength(2));
      expect(metadata.frameworks, contains('flutter'));
      expect(metadata.languages, contains('dart'));
      expect(metadata.rating, equals(4.5));
      expect(metadata.downloadCount, equals(1000));
      expect(metadata.complexity, equals('medium'));
      expect(metadata.maturity, equals('stable'));
    });
  });
}
