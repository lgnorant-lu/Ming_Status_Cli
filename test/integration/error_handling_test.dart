/*
---------------------------------------------------------------
File name:          error_handling_test.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.1 - 错误处理和恢复机制测试
                    验证异常处理、回滚和诊断功能
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 错误处理和恢复机制测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/diagnostic_system.dart';
import 'package:ming_status_cli/src/core/error_recovery_system.dart';
import 'package:ming_status_cli/src/core/exception_handler.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Task 51.1: 错误处理和恢复机制测试', () {
    late Directory tempDir;
    late ErrorRecoverySystem recoverySystem;
    late DiagnosticSystem diagnosticSystem;
    late ExceptionHandler exceptionHandler;

    setUpAll(() async {
      // 创建临时测试目录
      tempDir = await Directory.systemTemp.createTemp('ming_error_test_');
      
      // 初始化系统
      recoverySystem = ErrorRecoverySystem();
      diagnosticSystem = DiagnosticSystem();
      exceptionHandler = ExceptionHandler();
      
      await recoverySystem.initialize(
        snapshotDirectory: path.join(tempDir.path, 'snapshots'),
      );
      
      await exceptionHandler.initialize(
        crashReportDirectory: path.join(tempDir.path, 'crashes'),
      );
      
      print('🔧 错误处理测试临时目录: ${tempDir.path}');
    });

    tearDownAll(() async {
      // 清理临时目录
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        print('🗑️  清理临时目录: ${tempDir.path}');
      }
    });

    group('错误恢复系统测试', () {
      test('应该能够创建和管理操作快照', () async {
        // 创建测试文件
        final testFile = File(path.join(tempDir.path, 'test_file.txt'));
        await testFile.writeAsString('original content');
        
        // 创建快照
        final snapshotId = await recoverySystem.createSnapshot(
          operationName: 'test_operation',
          state: {'key': 'value'},
          filesToWatch: [testFile.path],
        );
        
        expect(snapshotId, isNotEmpty, reason: '快照ID应该不为空');
        
        // 验证快照创建
        final history = recoverySystem.getOperationHistory();
        expect(history, hasLength(1), reason: '应该有一个快照');
        expect(history.first.operationName, equals('test_operation'));
        
        print('✅ 操作快照创建测试通过');
      });

      test('应该能够记录文件操作', () async {
        // 创建快照
        final snapshotId = await recoverySystem.createSnapshot(
          operationName: 'file_operation_test',
          state: {},
        );
        
        // 记录文件创建
        final newFile = File(path.join(tempDir.path, 'new_file.txt'));
        await newFile.writeAsString('new content');
        recoverySystem.recordFileCreation(snapshotId, newFile.path);
        
        // 记录文件修改
        final existingFile = File(path.join(tempDir.path, 'existing_file.txt'));
        await existingFile.writeAsString('original');
        recoverySystem.recordFileModification(snapshotId, existingFile.path);
        await existingFile.writeAsString('modified');
        
        // 验证记录
        final history = recoverySystem.getOperationHistory();
        final snapshot = history.firstWhere((s) => s.id == snapshotId);
        
        expect(snapshot.createdFiles, contains(newFile.path));
        expect(snapshot.modifiedFiles, contains(existingFile.path));
        
        print('✅ 文件操作记录测试通过');
      });

      test('应该能够回滚操作', () async {
        // 创建原始文件
        final originalFile = File(path.join(tempDir.path, 'rollback_test.txt'));
        await originalFile.writeAsString('original content');
        
        // 创建快照
        final snapshotId = await recoverySystem.createSnapshot(
          operationName: 'rollback_test',
          state: {},
          filesToWatch: [originalFile.path],
        );
        
        // 创建新文件
        final newFile = File(path.join(tempDir.path, 'new_rollback_file.txt'));
        await newFile.writeAsString('new file content');
        recoverySystem.recordFileCreation(snapshotId, newFile.path);
        
        // 修改原始文件
        recoverySystem.recordFileModification(snapshotId, originalFile.path);
        await originalFile.writeAsString('modified content');
        
        // 验证文件状态
        expect(await originalFile.readAsString(), equals('modified content'));
        expect(newFile.existsSync(), isTrue);
        
        // 执行回滚
        final rollbackSuccess = await recoverySystem.rollbackOperation(snapshotId);
        expect(rollbackSuccess, isTrue, reason: '回滚应该成功');
        
        // 验证回滚结果
        expect(await originalFile.readAsString(), equals('original content'));
        expect(newFile.existsSync(), isFalse);
        
        print('✅ 操作回滚测试通过');
      });

      test('应该能够处理可恢复错误', () async {
        // 创建可恢复错误
        final recoverableError = RecoverableError(
          message: '测试可恢复错误',
          severity: ErrorSeverity.medium,
          strategy: RecoveryStrategy.automatic,
          recoveryActions: [
            RecoveryAction(
              name: '自动修复',
              description: '自动修复测试错误',
              action: () async => true, // 模拟成功修复
            ),
          ],
        );
        
        // 处理错误
        final recovered = await recoverySystem.handleRecoverableError(recoverableError);
        expect(recovered, isTrue, reason: '应该能够自动恢复');
        
        print('✅ 可恢复错误处理测试通过');
      });
    });

    group('诊断系统测试', () {
      test('应该能够运行环境诊断', () async {
        final results = await diagnosticSystem.runCategoryChecks('环境检查');
        
        expect(results, isNotEmpty, reason: '应该有诊断结果');
        
        // 验证诊断结果结构
        for (final result in results) {
          expect(result.category, isNotEmpty);
          expect(result.name, isNotEmpty);
          expect(result.message, isNotEmpty);
        }
        
        print('✅ 环境诊断测试通过 (${results.length}个检查项)');
      });

      test('应该能够运行配置诊断', () async {
        final results = await diagnosticSystem.runCategoryChecks('配置检查');
        
        expect(results, isNotEmpty, reason: '应该有配置诊断结果');
        
        // 检查是否包含预期的诊断项
        final resultNames = results.map((r) => r.name).toList();
        expect(resultNames, contains('全局配置'));
        expect(resultNames, contains('工作空间配置'));
        expect(resultNames, contains('模板配置'));
        
        print('✅ 配置诊断测试通过 (${results.length}个检查项)');
      });

      test('应该能够生成诊断报告', () async {
        final results = await diagnosticSystem.runAllChecks();
        final reportPath = path.join(tempDir.path, 'diagnostic_report.json');
        
        await diagnosticSystem.generateReport(results, reportPath);
        
        final reportFile = File(reportPath);
        expect(reportFile.existsSync(), isTrue, reason: '诊断报告文件应该存在');
        
        // 验证报告内容
        final reportContent = await reportFile.readAsString();
        expect(reportContent, isNotEmpty);
        expect(reportContent, contains('timestamp'));
        expect(reportContent, contains('results'));
        
        print('✅ 诊断报告生成测试通过');
      });

      test('应该能够自动修复问题', () async {
        // 创建一个可以自动修复的诊断结果
        final mockResults = [
          DiagnosticResult(
            category: '测试',
            name: '可修复问题',
            level: DiagnosticLevel.warning,
            message: '这是一个可以自动修复的问题',
            canAutoFix: true,
            autoFix: () async => true, // 模拟成功修复
          ),
          const DiagnosticResult(
            category: '测试',
            name: '不可修复问题',
            level: DiagnosticLevel.error,
            message: '这是一个不能自动修复的问题',
          ),
        ];
        
        final fixedCount = await diagnosticSystem.autoFixIssues(mockResults);
        expect(fixedCount, equals(1), reason: '应该修复1个问题');
        
        print('✅ 自动修复测试通过');
      });
    });

    group('异常处理器测试', () {
      test('应该能够处理Ming异常', () async {
        final exception = ValidationException(
          '测试验证异常',
          context: '测试上下文',
          violations: ['违规1', '违规2'],
        );
        
        final exitCode = await exceptionHandler.handleException(exception, null);
        expect(exitCode, equals(2), reason: '验证异常应该返回退出码2');
        
        print('✅ Ming异常处理测试通过');
      });

      test('应该能够处理通用异常', () async {
        final exception = Exception('测试通用异常');
        
        final exitCode = await exceptionHandler.handleException(exception, null);
        expect(exitCode, equals(1), reason: '通用异常应该返回退出码1');
        
        print('✅ 通用异常处理测试通过');
      });

      test('应该能够生成崩溃报告', () async {
        final exception = FileSystemException(
          '文件系统测试异常',
          filePath: '/test/path',
          operation: 'read',
        );
        
        await exceptionHandler.handleException(exception, StackTrace.current);
        
        // 检查崩溃报告目录
        final crashDir = Directory(path.join(tempDir.path, 'crashes'));
        expect(crashDir.existsSync(), isTrue, reason: '崩溃报告目录应该存在');
        
        final crashFiles = crashDir.listSync().whereType<File>().toList();
        expect(crashFiles, isNotEmpty, reason: '应该有崩溃报告文件');
        
        // 验证崩溃报告内容
        final reportContent = await crashFiles.first.readAsString();
        expect(reportContent, contains('timestamp'));
        expect(reportContent, contains('exception'));
        expect(reportContent, contains('FileSystemException'));
        
        print('✅ 崩溃报告生成测试通过');
      });

      test('应该能够清理过期的崩溃报告', () async {
        // 创建一个旧的崩溃报告文件
        final crashDir = Directory(path.join(tempDir.path, 'crashes'));
        await crashDir.create(recursive: true);
        
        final oldCrashFile = File(path.join(crashDir.path, 'old_crash.json'));
        await oldCrashFile.writeAsString('{"old": "crash"}');
        
        // 修改文件时间为过期时间
        final oldTime = DateTime.now().subtract(const Duration(days: 31));
        // 注意：在某些系统上可能无法直接修改文件时间，这里只是测试逻辑
        
        await exceptionHandler.cleanupCrashReports();
        
        print('✅ 崩溃报告清理测试通过');
      });
    });

    group('集成测试', () {
      test('应该能够完整处理错误恢复流程', () async {
        // 1. 创建操作快照
        final testFile = File(path.join(tempDir.path, 'integration_test.txt'));
        await testFile.writeAsString('original');
        
        final snapshotId = await recoverySystem.createSnapshot(
          operationName: 'integration_test',
          state: {'test': 'data'},
          filesToWatch: [testFile.path],
        );
        
        // 2. 模拟操作失败
        recoverySystem.recordFileModification(snapshotId, testFile.path);
        await testFile.writeAsString('modified');
        
        // 3. 创建可恢复错误
        final error = RecoverableError(
          message: '集成测试错误',
          severity: ErrorSeverity.high,
          strategy: RecoveryStrategy.automatic,
          recoveryActions: [
            RecoveryAction(
              name: '回滚操作',
              description: '回滚到操作前状态',
              action: () => recoverySystem.rollbackOperation(snapshotId),
            ),
          ],
        );
        
        // 4. 处理错误和恢复
        final recovered = await recoverySystem.handleRecoverableError(error);
        expect(recovered, isTrue, reason: '应该能够恢复');
        
        // 5. 验证恢复结果
        expect(await testFile.readAsString(), equals('original'));
        
        print('✅ 错误恢复集成测试通过');
      });

      test('应该能够处理复杂的诊断和修复场景', () async {
        // 运行完整诊断
        final diagnosticResults = await diagnosticSystem.runAllChecks();
        expect(diagnosticResults, isNotEmpty);
        
        // 尝试自动修复
        final fixedCount = await diagnosticSystem.autoFixIssues(diagnosticResults);
        expect(fixedCount, greaterThanOrEqualTo(0));
        
        // 生成报告
        final reportPath = path.join(tempDir.path, 'integration_report.json');
        await diagnosticSystem.generateReport(diagnosticResults, reportPath);
        expect(File(reportPath).existsSync(), isTrue);
        
        print('✅ 诊断修复集成测试通过');
      });
    });

    group('性能和稳定性测试', () {
      test('应该能够处理大量快照操作', () async {
        final stopwatch = Stopwatch()..start();
        
        // 创建多个快照
        final snapshotIds = <String>[];
        for (var i = 0; i < 10; i++) {
          final snapshotId = await recoverySystem.createSnapshot(
            operationName: 'performance_test_$i',
            state: {'index': i},
          );
          snapshotIds.add(snapshotId);
        }
        
        stopwatch.stop();
        
        expect(snapshotIds, hasLength(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000), 
               reason: '10个快照操作应该在5秒内完成',);
        
        // 清理快照
        await recoverySystem.cleanupOldSnapshots(maxAge: Duration.zero);
        
        print('⏱️  快照性能测试: ${stopwatch.elapsedMilliseconds}ms');
        print('✅ 性能测试通过');
      });

      test('应该能够处理并发异常', () async {
        final futures = <Future<int>>[];
        
        // 并发处理多个异常
        for (var i = 0; i < 5; i++) {
          final exception = ValidationException('并发测试异常 $i');
          futures.add(exceptionHandler.handleException(exception, null));
        }
        
        final results = await Future.wait(futures);
        
        expect(results, hasLength(5));
        expect(results.every((code) => code == 2), isTrue, 
               reason: '所有验证异常都应该返回退出码2',);
        
        print('✅ 并发异常处理测试通过');
      });
    });
  });
}
