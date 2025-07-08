/*
---------------------------------------------------------------
File name:          cli_test_helper.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        CLI集成测试助手类 (CLI integration test helper)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI测试基础设施;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// CLI测试结果
class CliTestResult {
  const CliTestResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;

  /// 是否成功执行（退出码为0）
  bool get isSuccess => exitCode == 0;

  /// 是否包含指定文本
  bool containsOutput(String text) =>
      stdout.contains(text) || stderr.contains(text);

  /// 是否在stdout中包含指定文本
  bool containsStdout(String text) => stdout.contains(text);

  /// 是否在stderr中包含指定文本
  bool containsStderr(String text) => stderr.contains(text);

  @override
  String toString() {
    return 'CliTestResult(exitCode: $exitCode, '
        'duration: ${duration.inMilliseconds}ms)\n'
        'STDOUT:\n$stdout\n'
        'STDERR:\n$stderr';
  }
}

/// CLI集成测试助手类
class CliTestHelper {
  /// CLI可执行文件路径
  static late String _cliPath;

  /// 临时测试目录
  static late Directory _tempDir;

  /// 初始化测试环境
  static Future<void> setUpAll() async {
    // 设置CLI可执行文件路径
    _cliPath = path.join('bin', 'ming_status_cli.dart');

    // 验证CLI文件存在
    if (!File(_cliPath).existsSync()) {
      throw StateError('CLI可执行文件不存在: $_cliPath');
    }

    // 创建临时测试目录
    _tempDir = await Directory.systemTemp.createTemp('ming_cli_test_');
    stderr.writeln('📁 测试临时目录: ${_tempDir.path}');
  }

  /// 清理测试环境
  static Future<void> tearDownAll() async {
    if (_tempDir.existsSync()) {
      await _tempDir.delete(recursive: true);
      stderr.writeln('🗑️  清理临时目录: ${_tempDir.path}');
    }
  }

  /// 执行CLI命令
  static Future<CliTestResult> runCommand(
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Duration timeout = const Duration(seconds: 30),
    String? input,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final workdir = workingDirectory ?? Directory.current.path;
      stderr
        ..writeln('🚀 执行命令: dart $_cliPath ${arguments.join(' ')}')
        ..writeln('📁 工作目录: $workdir');

      final process = await Process.start(
        'dart',
        [_cliPath, ...arguments],
        workingDirectory: workdir,
        environment: environment,
      );

      // 处理输入
      if (input != null) {
        process.stdin.writeln(input);
        await process.stdin.close();
      }

      // 设置超时
      Timer? timeoutTimer;
      final completer = Completer<int>();

      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          process.kill();
          completer.completeError(TimeoutException('命令执行超时', timeout));
        }
      });

      // 监听进程退出 - 使用变量避免unawaited警告
      final _ = process.exitCode.then((code) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(code);
        }
      });

      // 收集输出
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      await Future.wait([
        process.stdout
            .transform(const SystemEncoding().decoder)
            .forEach(stdoutBuffer.write),
        process.stderr
            .transform(const SystemEncoding().decoder)
            .forEach(stderrBuffer.write),
      ]);

      final exitCode = await completer.future;
      stopwatch.stop();

      final result = CliTestResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        duration: stopwatch.elapsed,
      );

      stderr.writeln(
        '✅ 命令完成: 退出码=$exitCode, 耗时=${result.duration.inMilliseconds}ms',
      );
      return result;
    } catch (e) {
      stopwatch.stop();
      stderr.writeln('❌ 命令执行失败: $e');

      return CliTestResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 在临时目录中执行命令
  static Future<CliTestResult> runInTempDir(
    List<String> arguments, {
    Map<String, String>? environment,
    Duration timeout = const Duration(seconds: 30),
    String? input,
  }) async {
    return runCommand(
      arguments,
      workingDirectory: _tempDir.path,
      environment: environment,
      timeout: timeout,
      input: input,
    );
  }

  /// 创建临时工作空间进行测试
  static Future<Directory> createTempWorkspace(String name) async {
    final workspaceDir = Directory(path.join(_tempDir.path, name));
    await workspaceDir.create(recursive: true);
    return workspaceDir;
  }

  /// 创建临时文件
  static Future<File> createTempFile(String fileName, String content) async {
    final file = File(path.join(_tempDir.path, fileName));
    await file.writeAsString(content);
    return file;
  }

  /// 验证命令输出包含指定文本
  static void expectOutput(CliTestResult result, String expectedText) {
    expect(
      result.containsOutput(expectedText),
      isTrue,
      reason: '输出中应包含: "$expectedText"\n实际输出:\n$result',
    );
  }

  /// 验证命令成功执行
  static void expectSuccess(CliTestResult result) {
    expect(
      result.exitCode,
      equals(0),
      reason: '命令应成功执行 (退出码=0)\n实际结果:\n$result',
    );
  }

  /// 验证命令执行失败
  static void expectFailure(CliTestResult result, {int? expectedExitCode}) {
    if (expectedExitCode != null) {
      expect(
        result.exitCode,
        equals(expectedExitCode),
        reason: '命令应失败并返回退出码 $expectedExitCode\n实际结果:\n$result',
      );
    } else {
      expect(
        result.exitCode,
        isNot(equals(0)),
        reason: '命令应失败执行 (退出码≠0)\n实际结果:\n$result',
      );
    }
  }

  /// 验证命令执行时间
  static void expectDuration(CliTestResult result, Duration maxDuration) {
    expect(
      result.duration,
      lessThan(maxDuration),
      reason: '命令执行时间应小于 ${maxDuration.inMilliseconds}ms\n'
          '实际时间: ${result.duration.inMilliseconds}ms',
    );
  }

  /// 获取临时目录路径
  static String get tempDirPath => _tempDir.path;

  /// 获取CLI可执行文件路径
  static String get cliPath => _cliPath;
}
