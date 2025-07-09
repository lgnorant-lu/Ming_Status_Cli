#!/usr/bin/env dart

/*
---------------------------------------------------------------
File name:          version_manager.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.2 - 版本管理脚本
                    管理项目版本号和发布标签
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 版本管理脚本;
---------------------------------------------------------------
*/

import 'dart:io';

/// 版本类型
enum VersionType {
  major,    // 主版本号 (1.0.0 -> 2.0.0)
  minor,    // 次版本号 (1.0.0 -> 1.1.0)
  patch,    // 补丁版本号 (1.0.0 -> 1.0.1)
}

/// 版本信息
class Version {

  Version(this.major, this.minor, this.patch, [this.preRelease, this.build]);

  /// 从字符串解析版本
  factory Version.parse(String version) {
    final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-\.]+))?(?:\+([a-zA-Z0-9\-\.]+))?$');
    final match = regex.firstMatch(version.trim());
    
    if (match == null) {
      throw FormatException('Invalid version format: $version');
    }
    
    return Version(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      match.group(4),
      match.group(5),
    );
  }
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? build;

  /// 增加版本号
  Version bump(VersionType type) {
    switch (type) {
      case VersionType.major:
        return Version(major + 1, 0, 0);
      case VersionType.minor:
        return Version(major, minor + 1, 0);
      case VersionType.patch:
        return Version(major, minor, patch + 1);
    }
  }

  @override
  String toString() {
    var version = '$major.$minor.$patch';
    if (preRelease != null) version += '-$preRelease';
    if (build != null) version += '+$build';
    return version;
  }

  /// 比较版本
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    
    // 处理预发布版本
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }
    
    return 0;
  }
}

/// 版本管理器
class VersionManager {
  
  VersionManager(this.projectRoot);
  /// 项目根目录
  final String projectRoot;

  /// 获取当前版本
  Future<Version> getCurrentVersion() async {
    final pubspecFile = File('$projectRoot/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml文件不存在');
    }
    
    final content = await pubspecFile.readAsString();
    final versionMatch = RegExp(r'version:\s*(.+)').firstMatch(content);
    
    if (versionMatch == null) {
      throw Exception('无法从pubspec.yaml读取版本信息');
    }
    
    final versionString = versionMatch.group(1)!.trim();
    return Version.parse(versionString);
  }

  /// 更新版本
  Future<void> updateVersion(Version newVersion) async {
    // 更新pubspec.yaml
    await _updatePubspecVersion(newVersion);
    
    // 更新其他版本相关文件
    await _updateVersionFiles(newVersion);
    
    print('✅ 版本已更新为: $newVersion');
  }

  /// 创建Git标签
  Future<void> createGitTag(Version version, {String? message}) async {
    final tagName = 'v$version';
    final tagMessage = message ?? 'Release $version';
    
    // 检查标签是否已存在
    final checkResult = await Process.run('git', ['tag', '-l', tagName]);
    if (checkResult.stdout.toString().trim().isNotEmpty) {
      throw Exception('Git标签 $tagName 已存在');
    }
    
    // 创建标签
    final tagResult = await Process.run('git', ['tag', '-a', tagName, '-m', tagMessage]);
    if (tagResult.exitCode != 0) {
      throw Exception('创建Git标签失败: ${tagResult.stderr}');
    }
    
    print('✅ Git标签已创建: $tagName');
  }

  /// 推送标签到远程
  Future<void> pushTag(Version version) async {
    final tagName = 'v$version';
    
    final pushResult = await Process.run('git', ['push', 'origin', tagName]);
    if (pushResult.exitCode != 0) {
      throw Exception('推送Git标签失败: ${pushResult.stderr}');
    }
    
    print('✅ Git标签已推送: $tagName');
  }

  /// 获取版本历史
  Future<List<Version>> getVersionHistory() async {
    final tagResult = await Process.run('git', ['tag', '-l', 'v*', '--sort=-version:refname']);
    if (tagResult.exitCode != 0) {
      return [];
    }
    
    final tags = tagResult.stdout.toString().trim().split('\n');
    final versions = <Version>[];
    
    for (final tag in tags) {
      if (tag.isNotEmpty && tag.startsWith('v')) {
        try {
          final version = Version.parse(tag.substring(1));
          versions.add(version);
        } catch (e) {
          // 忽略无效的标签
        }
      }
    }
    
    return versions;
  }

  /// 生成版本报告
  Future<String> generateVersionReport() async {
    final currentVersion = await getCurrentVersion();
    final versionHistory = await getVersionHistory();
    
    final report = StringBuffer();
    report.writeln('# Ming Status CLI 版本报告');
    report.writeln();
    report.writeln('## 📋 当前版本');
    report.writeln();
    report.writeln('**版本**: $currentVersion');
    report.writeln('**发布日期**: ${DateTime.now().toIso8601String().split('T')[0]}');
    report.writeln();
    report.writeln('## 📈 版本历史');
    report.writeln();
    
    if (versionHistory.isNotEmpty) {
      for (final version in versionHistory.take(10)) {
        report.writeln('- v$version');
      }
      
      if (versionHistory.length > 10) {
        report.writeln('- ... (${versionHistory.length - 10} 个更早版本)');
      }
    } else {
      report.writeln('暂无版本历史');
    }
    
    report.writeln();
    report.writeln('## 🚀 版本规划');
    report.writeln();
    report.writeln('### Phase 1 (v1.x.x) - 基础功能');
    report.writeln('- ✅ v1.0.0 - 核心CLI框架和配置系统');
    report.writeln('- 📋 v1.1.0 - 模板引擎和基础模块生成');
    report.writeln('- 📋 v1.2.0 - 验证系统和质量检查');
    report.writeln();
    report.writeln('### Phase 2 (v2.x.x) - 高级功能');
    report.writeln('- 🚀 v2.0.0 - 高级模板系统');
    report.writeln('- 🚀 v2.1.0 - 远程模板库');
    report.writeln('- 🚀 v2.2.0 - 团队协作功能');
    report.writeln();
    report.writeln('### Phase 3 (v3.x.x) - 智能化');
    report.writeln('- 🔮 v3.0.0 - AI辅助开发');
    report.writeln('- 🔮 v3.1.0 - 开发平台化');
    report.writeln('- 🔮 v3.2.0 - 生态系统完善');
    
    return report.toString();
  }

  /// 更新pubspec.yaml版本
  Future<void> _updatePubspecVersion(Version version) async {
    final pubspecFile = File('$projectRoot/pubspec.yaml');
    final content = await pubspecFile.readAsString();
    
    final updatedContent = content.replaceFirst(
      RegExp(r'version:\s*.+'),
      'version: $version',
    );
    
    await pubspecFile.writeAsString(updatedContent);
  }

  /// 更新其他版本相关文件
  Future<void> _updateVersionFiles(Version version) async {
    // 更新版本常量文件
    final versionFile = File('$projectRoot/lib/src/version.dart');
    if (!versionFile.existsSync()) {
      await versionFile.create(recursive: true);
    }
    
    final versionContent = '''
// 自动生成的版本文件 - 请勿手动编辑
const String packageVersion = '$version';
const String packageName = 'Ming Status CLI';
const String packageDescription = '模块化脚手架工具for Pet App平台';
''';
    
    await versionFile.writeAsString(versionContent);
  }
}

/// 主函数
Future<void> main(List<String> args) async {
  final projectRoot = Directory.current.path;
  final versionManager = VersionManager(projectRoot);
  
  if (args.isEmpty) {
    print('用法: dart version_manager.dart <command> [options]');
    print('');
    print('命令:');
    print('  current              显示当前版本');
    print('  bump <type>          增加版本号 (major|minor|patch)');
    print('  set <version>        设置指定版本');
    print('  tag [message]        创建Git标签');
    print('  push-tag             推送Git标签');
    print('  history              显示版本历史');
    print('  report               生成版本报告');
    return;
  }
  
  final command = args[0];
  
  try {
    switch (command) {
      case 'current':
        final version = await versionManager.getCurrentVersion();
        print('当前版本: $version');
        
      case 'bump':
        if (args.length < 2) {
          print('错误: 请指定版本类型 (major|minor|patch)');
          return;
        }
        
        final typeString = args[1];
        final type = VersionType.values.firstWhere(
          (t) => t.name == typeString,
          orElse: () => throw ArgumentError('无效的版本类型: $typeString'),
        );
        
        final currentVersion = await versionManager.getCurrentVersion();
        final newVersion = currentVersion.bump(type);
        await versionManager.updateVersion(newVersion);
        
      case 'set':
        if (args.length < 2) {
          print('错误: 请指定版本号');
          return;
        }
        
        final newVersion = Version.parse(args[1]);
        await versionManager.updateVersion(newVersion);
        
      case 'tag':
        final currentVersion = await versionManager.getCurrentVersion();
        final message = args.length > 1 ? args[1] : null;
        await versionManager.createGitTag(currentVersion, message: message);
        
      case 'push-tag':
        final currentVersion = await versionManager.getCurrentVersion();
        await versionManager.pushTag(currentVersion);
        
      case 'history':
        final history = await versionManager.getVersionHistory();
        print('版本历史:');
        for (final version in history) {
          print('  v$version');
        }
        
      case 'report':
        final report = await versionManager.generateVersionReport();
        print(report);
        
      default:
        print('错误: 未知命令 $command');
        exit(1);
    }
  } catch (e) {
    print('错误: $e');
    exit(1);
  }
}
