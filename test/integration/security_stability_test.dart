/*
---------------------------------------------------------------
File name:          security_stability_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.2 - 安全性和稳定性测试
                    验证安全验证、文件安全和依赖安全功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 安全性和稳定性测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/security_system/dependency_security_checker.dart';
import 'package:ming_status_cli/src/core/security_system/file_security_manager.dart';
import 'package:ming_status_cli/src/core/security_system/security_validator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 51.2: 安全性和稳定性测试', () {
    late Directory tempDir;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_security_test_');
      print('🔒 安全性测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }
    });

    group('安全验证器测试', () {
      test('应该能够验证安全的路径', () {
        final result = PathSecurityValidator.validatePath('lib/src/test.dart');
        expect(result, equals(SecurityValidationResult.safe));
        print('✅ 安全路径验证通过');
      });

      test('应该能够检测危险的路径', () {
        expect(
          () => PathSecurityValidator.validatePath('../../../etc/passwd'),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 危险路径检测通过');
      });

      test('应该能够验证文件名', () {
        final result = PathSecurityValidator.validateFileName('test_file.dart');
        expect(result, equals(SecurityValidationResult.safe));
        print('✅ 安全文件名验证通过');
      });

      test('应该能够检测非法文件名', () {
        expect(
          () => PathSecurityValidator.validateFileName('CON'),
          throwsA(isA<SecurityValidationError>()),
        );

        expect(
          () => PathSecurityValidator.validateFileName('test<file>.dart'),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 非法文件名检测通过');
      });

      test('应该能够验证项目名称', () {
        final result = InputValidator.validateProjectName('my_test_project');
        expect(result, equals(SecurityValidationResult.safe));
        print('✅ 项目名称验证通过');
      });

      test('应该能够检测无效项目名称', () {
        expect(
          () => InputValidator.validateProjectName(''),
          throwsA(isA<SecurityValidationError>()),
        );

        expect(
          () => InputValidator.validateProjectName('123invalid'),
          throwsA(isA<SecurityValidationError>()),
        );

        expect(
          () => InputValidator.validateProjectName('invalid@name'),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 无效项目名称检测通过');
      });

      test('应该能够验证URL', () {
        final result1 = InputValidator.validateUrl('https://example.com');
        expect(result1, equals(SecurityValidationResult.safe));

        final result2 = InputValidator.validateUrl('file:///local/path');
        expect(result2, equals(SecurityValidationResult.warning));
        print('✅ URL验证通过');
      });

      test('应该能够检测无效URL', () {
        expect(
          () => InputValidator.validateUrl(''),
          throwsA(isA<SecurityValidationError>()),
        );

        expect(
          () => InputValidator.validateUrl('ftp://invalid.com'),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 无效URL检测通过');
      });

      test('应该能够检查路径是否在允许目录内', () {
        final allowed = tempDir.path;
        final validPath = path.join(tempDir.path, 'subdir', 'file.txt');
        final invalidPath =
            path.join(Directory.systemTemp.path, 'other', 'file.txt');

        expect(
            PathSecurityValidator.isPathWithinAllowedDirectory(
                validPath, allowed,),
            isTrue,);
        expect(
            PathSecurityValidator.isPathWithinAllowedDirectory(
                invalidPath, allowed,),
            isFalse,);
        print('✅ 路径范围检查通过');
      });
    });

    group('文件安全管理器测试', () {
      late FileSecurityManager fileManager;

      setUp(() {
        fileManager = FileSecurityManager();
        fileManager.setSandboxRoot(tempDir.path);
        fileManager.setPolicy(FileSecurityPolicy.defaultPolicy);
      });

      test('应该能够安全读取文件', () async {
        // 创建测试文件
        final testFile = File(path.join(tempDir.path, 'test_read.txt'));
        await testFile.writeAsString('test content');

        // 安全读取
        final content = await fileManager.secureReadFile(testFile.path);
        expect(content, equals('test content'));

        // 检查操作日志
        final log = fileManager.getOperationLog();
        expect(log, isNotEmpty);
        expect(log.last.type, equals(FileOperationType.read));
        expect(log.last.success, isTrue);

        print('✅ 安全文件读取测试通过');
      });

      test('应该能够安全写入文件', () async {
        final testFile = path.join(tempDir.path, 'test_write.dart');
        const testContent = 'void main() { print("Hello"); }';

        // 安全写入
        await fileManager.secureWriteFile(testFile, testContent);

        // 验证文件内容
        final file = File(testFile);
        expect(file.existsSync(), isTrue);
        expect(await file.readAsString(), equals(testContent));

        // 检查操作日志
        final log = fileManager.getOperationLog();
        final writeOp =
            log.where((op) => op.type == FileOperationType.write).last;
        expect(writeOp.success, isTrue);

        print('✅ 安全文件写入测试通过');
      });

      test('应该能够安全创建目录', () async {
        final testDir = path.join(tempDir.path, 'test_subdir');

        // 安全创建目录
        await fileManager.secureCreateDirectory(testDir);

        // 验证目录存在
        expect(Directory(testDir).existsSync(), isTrue);

        // 检查操作日志
        final log = fileManager.getOperationLog();
        final createOp =
            log.where((op) => op.type == FileOperationType.create).last;
        expect(createOp.success, isTrue);

        print('✅ 安全目录创建测试通过');
      });

      test('应该能够阻止危险文件操作', () async {
        // 尝试访问沙箱外的文件
        final outsideFile = path.join(Directory.systemTemp.path, 'outside.txt');

        expect(
          () => fileManager.secureReadFile(outsideFile),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 沙箱外文件访问阻止测试通过');
      });

      test('应该能够阻止非法文件扩展名', () async {
        final executableFile = path.join(tempDir.path, 'malware.exe');

        expect(
          () => fileManager.secureWriteFile(executableFile, 'malware'),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 非法文件扩展名阻止测试通过');
      });

      test('应该能够限制文件大小', () async {
        // 设置严格策略
        fileManager.setPolicy(FileSecurityPolicy.strictPolicy);

        final largeFile = path.join(tempDir.path, 'large.txt');
        final largeContent = 'x' * (2 * 1024 * 1024); // 2MB

        expect(
          () => fileManager.secureWriteFile(largeFile, largeContent),
          throwsA(isA<SecurityValidationError>()),
        );
        print('✅ 文件大小限制测试通过');
      });

      test('应该能够获取安全统计信息', () {
        final stats = fileManager.getSecurityStats();

        expect(stats, containsPair('totalOperations', isA<int>()));
        expect(stats, containsPair('successfulOperations', isA<int>()));
        expect(stats, containsPair('failedOperations', isA<int>()));
        expect(stats, containsPair('successRate', isA<String>()));
        expect(stats, containsPair('sandboxRoot', tempDir.path));

        print('✅ 安全统计信息测试通过');
      });
    });

    group('依赖安全检查器测试', () {
      late DependencySecurityChecker depChecker;

      setUp(() {
        depChecker = DependencySecurityChecker();
      });

      test('应该能够创建依赖安全检查器实例', () {
        expect(depChecker, isNotNull);
        print('✅ 依赖安全检查器实例创建成功');
      });

      test('应该能够扫描pubspec.yaml文件', () async {
        // 创建测试pubspec.yaml
        final pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: test_project
version: 1.0.0

dependencies:
  http: ^0.13.5
  path: ^1.8.3

dev_dependencies:
  test: ^1.21.0
  lints: ^2.0.0
''');

        // 扫描依赖
        final report = await depChecker.scanPubspecFile(pubspecFile.path);

        expect(report.totalDependencies, greaterThan(0));
        expect(report.dependencies, isNotEmpty);
        expect(report.scanTime, isA<DateTime>());

        // 检查依赖信息
        final httpDep = report.dependencies.firstWhere((d) => d.name == 'http');
        expect(httpDep.currentVersion, equals('^0.13.5'));
        expect(httpDep.isDev, isFalse);

        final testDep = report.dependencies.firstWhere((d) => d.name == 'test');
        expect(testDep.isDev, isTrue);

        print('✅ pubspec.yaml扫描测试通过 (${report.totalDependencies}个依赖)');
      });

      test('应该能够检测不安全的依赖', () async {
        // 创建包含不安全依赖的pubspec.yaml
        final pubspecFile =
            File(path.join(tempDir.path, 'unsafe_pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: unsafe_project
version: 1.0.0

dependencies:
  unsafe_package_example: ^1.0.0
  http: ^0.12.0

dev_dependencies:
  test: ^1.21.0
''');

        // 扫描依赖
        final report = await depChecker.scanPubspecFile(pubspecFile.path);

        expect(report.vulnerableDependencies, greaterThan(0));
        expect(report.totalVulnerabilities, greaterThan(0));

        // 检查不安全包
        final unsafeDep = report.dependencies.firstWhere(
          (d) => d.name == 'unsafe_package_example',
        );
        expect(unsafeDep.securityLevel, equals(DependencySecurityLevel.high));
        expect(unsafeDep.vulnerabilities, isNotEmpty);

        print('✅ 不安全依赖检测测试通过');
      });

      test('应该能够生成安全建议', () async {
        // 创建测试报告
        final dependencies = [
          const DependencyInfo(
            name: 'safe_package',
            currentVersion: '1.0.0',
          ),
          const DependencyInfo(
            name: 'vulnerable_package',
            currentVersion: '0.9.0',
            securityLevel: DependencySecurityLevel.high,
            vulnerabilities: [
              DependencyVulnerability(
                id: 'TEST-001',
                title: '测试漏洞',
                description: '这是一个测试漏洞',
                severity: DependencySecurityLevel.high,
                affectedVersions: '<1.0.0',
                fixedVersion: '1.0.0',
              ),
            ],
          ),
        ];

        final report = DependencySecurityReport(
          scanTime: DateTime.now(),
          totalDependencies: 2,
          safeDependencies: 1,
          vulnerableDependencies: 1,
          dependencies: dependencies,
          totalVulnerabilities: 1,
          vulnerabilitiesBySeverity: {DependencySecurityLevel.high: 1},
        );

        // 生成建议
        final recommendations =
            depChecker.generateSecurityRecommendations(report);

        expect(recommendations, isNotEmpty);
        expect(recommendations.any((r) => r.contains('vulnerable_package')),
            isTrue,);

        print('✅ 安全建议生成测试通过 (${recommendations.length}条建议)');
      });

      test('应该能够导出安全报告', () async {
        // 创建简单的测试报告
        final report = DependencySecurityReport(
          scanTime: DateTime.now(),
          totalDependencies: 1,
          safeDependencies: 1,
          vulnerableDependencies: 0,
          dependencies: [
            const DependencyInfo(
              name: 'test_package',
              currentVersion: '1.0.0',
            ),
          ],
          totalVulnerabilities: 0,
          vulnerabilitiesBySeverity: {},
        );

        // 导出报告
        final reportPath = path.join(tempDir.path, 'security_report.json');
        await depChecker.exportReport(report, reportPath);

        // 验证报告文件
        final reportFile = File(reportPath);
        expect(reportFile.existsSync(), isTrue);

        final content = await reportFile.readAsString();
        expect(content, isNotEmpty);
        expect(content, contains('test_package'));

        print('✅ 安全报告导出测试通过');
      });
    });

    group('集成安全测试', () {
      test('应该能够进行综合安全验证', () async {
        // 综合验证多个输入
        final results = await SecurityValidator.validateAll(
          projectName: 'test_project',
          templateName: 'basic_template',
          targetPath: path.join(tempDir.path, 'new_project'),
          configValues: {
            'user.name': 'Test User',
            'user.email': 'test@example.com',
          },
          url: 'https://github.com/example/repo.git',
        );

        expect(results, isNotEmpty);
        expect(results['projectName'], equals(SecurityValidationResult.safe));
        expect(results['templateName'], equals(SecurityValidationResult.safe));
        expect(results['targetPath'], equals(SecurityValidationResult.safe));
        expect(results['url'], equals(SecurityValidationResult.safe));

        // 检查是否有危险结果
        expect(SecurityValidator.hasDangerousResults(results), isFalse);

        print('✅ 综合安全验证测试通过 (${results.length}项检查)');
      });

      test('应该能够检测综合安全风险', () async {
        expect(
          () => SecurityValidator.validateAll(
            projectName: '123invalid',
            targetPath: '../../../dangerous/path',
            url: 'ftp://unsafe.com',
          ),
          throwsA(isA<SecurityValidationError>()),
        );

        print('✅ 综合安全风险检测测试通过');
      });
    });

    group('性能和稳定性测试', () {
      test('应该能够处理大量安全验证', () async {
        final stopwatch = Stopwatch()..start();

        // 执行多次验证
        for (var i = 0; i < 100; i++) {
          PathSecurityValidator.validatePath('lib/src/test_$i.dart');
          InputValidator.validateProjectName('test_project_$i');
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
          reason: '100次安全验证应该在1秒内完成',
        );

        print('⏱️  安全验证性能测试: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 性能测试通过');
      });

      test('应该能够处理并发文件操作', () async {
        final fileManager = FileSecurityManager();
        fileManager.setSandboxRoot(tempDir.path);

        // 并发创建多个文件
        final futures = <Future<void>>[];
        for (var i = 0; i < 10; i++) {
          final filePath = path.join(tempDir.path, 'concurrent_$i.txt');
          futures.add(fileManager.secureWriteFile(filePath, 'content $i'));
        }

        await Future.wait(futures);

        // 验证所有文件都创建成功
        for (var i = 0; i < 10; i++) {
          final filePath = path.join(tempDir.path, 'concurrent_$i.txt');
          expect(File(filePath).existsSync(), isTrue);
        }

        // 检查操作日志
        final log = fileManager.getOperationLog();
        final writeOps =
            log.where((op) => op.type == FileOperationType.write).toList();
        expect(writeOps.length, greaterThanOrEqualTo(10));

        print('✅ 并发文件操作测试通过');
      });
    });
  });
}
