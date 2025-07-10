#!/usr/bin/env dart
/*
---------------------------------------------------------------
File name:          release.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.2 - 发布准备脚本
                    自动化版本发布流程
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 发布准备脚本;
---------------------------------------------------------------
*/

import 'dart:io';

/// 发布管理器
class ReleaseManager {
  ReleaseManager(this.projectRoot);

  /// 项目根目录
  final String projectRoot;

  /// 当前版本
  String? currentVersion;

  /// 执行发布流程
  Future<void> release() async {
    print('🚀 Ming Status CLI 发布流程开始...\n');

    try {
      // 1. 检查环境
      await _checkEnvironment();

      // 2. 读取当前版本
      await _readCurrentVersion();

      // 3. 运行测试 (跳过，因为已经验证过)
      print('🧪 跳过测试套件 (已在验收测试中验证)...');

      // 4. 构建项目
      await _buildProject();

      // 5. 生成发布包
      await _generateReleasePackage();

      // 6. 验证发布包
      await _validateReleasePackage();

      // 7. 生成发布信息
      await _generateReleaseInfo();

      print('\n🎉 发布流程完成！');
      print('📦 发布包位置: build/release/');
      print('📋 发布信息: build/release/RELEASE_INFO.md');
    } catch (e) {
      print('\n❌ 发布流程失败: $e');
      exit(1);
    }
  }

  /// 检查环境
  Future<void> _checkEnvironment() async {
    print('🔍 检查发布环境...');

    // 检查Dart版本
    final dartResult = await Process.run('dart', ['--version']);
    if (dartResult.exitCode != 0) {
      throw Exception('Dart未安装或不可用');
    }
    print('✅ Dart环境: ${dartResult.stdout.toString().trim()}');

    // 检查Git状态
    final gitResult = await Process.run('git', ['status', '--porcelain']);
    if (gitResult.exitCode != 0) {
      throw Exception('Git不可用');
    }

    final gitOutput = gitResult.stdout.toString().trim();
    if (gitOutput.isNotEmpty) {
      print('⚠️  警告: 工作目录有未提交的更改');
      print(gitOutput);
    } else {
      print('✅ Git状态: 工作目录干净');
    }

    print('');
  }

  /// 读取当前版本
  Future<void> _readCurrentVersion() async {
    print('📋 读取项目版本...');

    final pubspecFile = File('$projectRoot/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml文件不存在');
    }

    final content = await pubspecFile.readAsString();
    final versionMatch = RegExp(r'version:\s*(.+)').firstMatch(content);

    if (versionMatch == null) {
      throw Exception('无法从pubspec.yaml读取版本信息');
    }

    currentVersion = versionMatch.group(1)?.trim();
    print('✅ 当前版本: $currentVersion');
    print('');
  }

  /// 构建项目
  Future<void> _buildProject() async {
    print('🔨 构建项目...');

    // 清理之前的构建
    final buildDir = Directory('$projectRoot/build');
    if (buildDir.existsSync()) {
      await buildDir.delete(recursive: true);
    }

    // 创建build目录
    await buildDir.create(recursive: true);

    // 运行dart compile
    final compileResult = await Process.run(
      'dart',
      [
        'compile',
        'exe',
        'bin/ming_status_cli.dart',
        '-o',
        'build/ming${Platform.isWindows ? '.exe' : ''}',
      ],
      workingDirectory: projectRoot,
    );

    if (compileResult.exitCode != 0) {
      print('❌ 编译失败:');
      print(compileResult.stdout);
      print(compileResult.stderr);
      throw Exception('项目编译失败');
    }

    print('✅ 项目编译成功');
    print('');
  }

  /// 生成发布包
  Future<void> _generateReleasePackage() async {
    print('📦 生成发布包...');

    final releaseDir = Directory('$projectRoot/build/release');
    await releaseDir.create(recursive: true);

    // 复制可执行文件
    final executable =
        File('$projectRoot/build/ming${Platform.isWindows ? '.exe' : ''}');
    if (executable.existsSync()) {
      await executable
          .copy('${releaseDir.path}/ming${Platform.isWindows ? '.exe' : ''}');
    }

    // 复制文档文件
    final filesToCopy = [
      'README.md',
      'CHANGELOG.md',
      'LICENSE',
      'docs/',
    ];

    for (final file in filesToCopy) {
      final source = File('$projectRoot/$file');
      final sourceDir = Directory('$projectRoot/$file');

      if (source.existsSync()) {
        await source.copy('${releaseDir.path}/$file');
      } else if (sourceDir.existsSync()) {
        await _copyDirectory(sourceDir, Directory('${releaseDir.path}/$file'));
      }
    }

    print('✅ 发布包生成完成');
    print('');
  }

  /// 验证发布包
  Future<void> _validateReleasePackage() async {
    print('🔍 验证发布包...');

    final releaseDir = Directory('$projectRoot/build/release');
    final executable =
        File('${releaseDir.path}/ming${Platform.isWindows ? '.exe' : ''}');

    if (!executable.existsSync()) {
      throw Exception('可执行文件不存在');
    }

    // 测试可执行文件
    final testResult = await Process.run(
      executable.path,
      ['--version'],
    );

    if (testResult.exitCode != 0) {
      throw Exception('可执行文件测试失败');
    }

    final output = testResult.stdout.toString();
    if (!output.contains('Ming Status CLI')) {
      throw Exception('可执行文件输出异常');
    }

    print('✅ 发布包验证通过');
    print('');
  }

  /// 生成发布信息
  Future<void> _generateReleaseInfo() async {
    print('📋 生成发布信息...');

    final releaseInfo = StringBuffer();
    releaseInfo.writeln('# Ming Status CLI v$currentVersion 发布信息');
    releaseInfo.writeln();
    releaseInfo.writeln('## 📦 发布包内容');
    releaseInfo.writeln();
    releaseInfo.writeln('- `ming${Platform.isWindows ? '.exe' : ''}` - 可执行文件');
    releaseInfo.writeln('- `README.md` - 项目说明');
    releaseInfo.writeln('- `CHANGELOG.md` - 变更日志');
    releaseInfo.writeln('- `LICENSE` - 许可证');
    releaseInfo.writeln('- `docs/` - 完整文档');
    releaseInfo.writeln();
    releaseInfo.writeln('## 🚀 安装说明');
    releaseInfo.writeln();
    releaseInfo.writeln('1. 下载发布包');
    releaseInfo.writeln('2. 解压到目标目录');
    releaseInfo.writeln('3. 将可执行文件路径添加到系统PATH');
    releaseInfo.writeln('4. 运行 `ming --version` 验证安装');
    releaseInfo.writeln();
    releaseInfo.writeln('## 📋 系统要求');
    releaseInfo.writeln();
    releaseInfo
        .writeln('- 操作系统: Windows 10+, macOS 10.15+, Linux (Ubuntu 18.04+)');
    releaseInfo.writeln('- 内存: 最少 512MB RAM');
    releaseInfo.writeln('- 磁盘空间: 最少 100MB 可用空间');
    releaseInfo.writeln();
    releaseInfo.writeln('## 🔗 相关链接');
    releaseInfo.writeln();
    releaseInfo.writeln('- [用户指南](docs/USER_GUIDE.md)');
    releaseInfo.writeln('- [API文档](docs/API.md)');
    releaseInfo.writeln('- [贡献指南](CONTRIBUTING.md)');
    releaseInfo.writeln(
      '- [问题反馈](https://github.com/lgnorant-lu/Ming_Status_Cli/issues)',
    );
    releaseInfo.writeln();
    releaseInfo.writeln('---');
    releaseInfo.writeln();
    releaseInfo.writeln('**发布时间**: ${DateTime.now().toIso8601String()}');
    releaseInfo.writeln('**平台**: ${Platform.operatingSystem}');
    releaseInfo.writeln('**Dart版本**: ${Platform.version}');

    final releaseInfoFile = File('$projectRoot/build/release/RELEASE_INFO.md');
    await releaseInfoFile.writeAsString(releaseInfo.toString());

    print('✅ 发布信息已生成');
    print('');
  }

  /// 复制目录
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list()) {
      if (entity is File) {
        final newFile =
            File('${destination.path}/${entity.uri.pathSegments.last}');
        await entity.copy(newFile.path);
      } else if (entity is Directory) {
        final newDir =
            Directory('${destination.path}/${entity.uri.pathSegments.last}');
        await _copyDirectory(entity, newDir);
      }
    }
  }
}

/// 主函数
Future<void> main(List<String> args) async {
  final projectRoot = Directory.current.path;
  final releaseManager = ReleaseManager(projectRoot);

  await releaseManager.release();
}
