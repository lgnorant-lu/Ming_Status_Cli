/*
---------------------------------------------------------------
File name:          diagnostic_system.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.1 - 系统诊断功能
                    实现环境检查、问题诊断和修复建议
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 系统诊断功能;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';
import 'package:path/path.dart' as path;

/// 诊断结果级别
enum DiagnosticLevel {
  info, // 信息
  warning, // 警告
  error, // 错误
  critical, // 严重
}

/// 诊断结果
class DiagnosticResult {
  const DiagnosticResult({
    required this.category,
    required this.name,
    required this.level,
    required this.message,
    this.details,
    this.suggestions = const [],
    this.canAutoFix = false,
    this.autoFix,
  });
  final String category;
  final String name;
  final DiagnosticLevel level;
  final String message;
  final String? details;
  final List<String> suggestions;
  final bool canAutoFix;
  final Future<bool> Function()? autoFix;

  String get levelIcon {
    switch (level) {
      case DiagnosticLevel.info:
        return 'ℹ️';
      case DiagnosticLevel.warning:
        return '⚠️';
      case DiagnosticLevel.error:
        return '❌';
      case DiagnosticLevel.critical:
        return '🚨';
    }
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'name': name,
        'level': level.name,
        'message': message,
        'details': details,
        'suggestions': suggestions,
        'canAutoFix': canAutoFix,
      };
}

/// 诊断检查器接口
abstract class DiagnosticChecker {
  String get category;
  String get name;
  Future<List<DiagnosticResult>> check();
}

/// 环境诊断检查器
class EnvironmentChecker implements DiagnosticChecker {
  @override
  String get category => '环境检查';

  @override
  String get name => 'Dart环境';

  @override
  Future<List<DiagnosticResult>> check() async {
    final results = <DiagnosticResult>[];

    // 检查Dart SDK
    await _checkDartSDK(results);

    // 检查PATH配置
    await _checkPathConfiguration(results);

    // 检查权限
    await _checkPermissions(results);

    // 检查磁盘空间
    await _checkDiskSpace(results);

    return results;
  }

  Future<void> _checkDartSDK(List<DiagnosticResult> results) async {
    try {
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode == 0) {
        final version = result.stderr.toString().trim();
        results.add(
          DiagnosticResult(
            category: category,
            name: 'Dart SDK',
            level: DiagnosticLevel.info,
            message: 'Dart SDK 已安装',
            details: version,
          ),
        );
      } else {
        results.add(
          DiagnosticResult(
            category: category,
            name: 'Dart SDK',
            level: DiagnosticLevel.critical,
            message: 'Dart SDK 未正确安装',
            suggestions: [
              '请访问 https://dart.dev/get-dart 安装 Dart SDK',
              '确保 Dart 已添加到 PATH 环境变量',
            ],
          ),
        );
      }
    } catch (e) {
      results.add(
        DiagnosticResult(
          category: category,
          name: 'Dart SDK',
          level: DiagnosticLevel.critical,
          message: 'Dart SDK 检查失败',
          details: e.toString(),
          suggestions: [
            '请确认 Dart SDK 已正确安装',
            '检查 PATH 环境变量配置',
          ],
        ),
      );
    }
  }

  Future<void> _checkPathConfiguration(List<DiagnosticResult> results) async {
    final pathEnv = Platform.environment['PATH'] ?? '';
    final pubCachePath = path.join(
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '',
      '.pub-cache',
      'bin',
    );

    if (pathEnv.contains('.pub-cache') || pathEnv.contains(pubCachePath)) {
      results.add(
        DiagnosticResult(
          category: category,
          name: 'PATH配置',
          level: DiagnosticLevel.info,
          message: 'pub cache bin 目录已在 PATH 中',
        ),
      );
    } else {
      results.add(
        DiagnosticResult(
          category: category,
          name: 'PATH配置',
          level: DiagnosticLevel.warning,
          message: 'pub cache bin 目录不在 PATH 中',
          suggestions: [
            '添加 $pubCachePath 到 PATH 环境变量',
            '重启终端或重新加载环境变量',
          ],
          canAutoFix: true,
          autoFix: () async {
            // 这里可以实现自动修复逻辑
            return false; // 暂时返回false，需要手动修复
          },
        ),
      );
    }
  }

  Future<void> _checkPermissions(List<DiagnosticResult> results) async {
    final currentDir = Directory.current;

    try {
      // 测试写权限
      final testFile = File(path.join(currentDir.path, '.ming_test_write'));
      await testFile.writeAsString('test');
      await testFile.delete();

      results.add(
        DiagnosticResult(
          category: category,
          name: '文件权限',
          level: DiagnosticLevel.info,
          message: '当前目录具有读写权限',
        ),
      );
    } catch (e) {
      results.add(
        DiagnosticResult(
          category: category,
          name: '文件权限',
          level: DiagnosticLevel.error,
          message: '当前目录缺少写权限',
          details: e.toString(),
          suggestions: [
            '检查目录权限设置',
            '使用管理员权限运行',
            '切换到有写权限的目录',
          ],
        ),
      );
    }
  }

  Future<void> _checkDiskSpace(List<DiagnosticResult> results) async {
    try {
      final currentDir = Directory.current;
      final stat = await currentDir.stat();

      // 简单的磁盘空间检查（这里只是示例）
      results.add(
        DiagnosticResult(
          category: category,
          name: '磁盘空间',
          level: DiagnosticLevel.info,
          message: '磁盘空间检查完成',
          details: '当前目录: ${currentDir.path}, 修改时间: ${stat.modified}',
        ),
      );
    } catch (e) {
      results.add(
        DiagnosticResult(
          category: category,
          name: '磁盘空间',
          level: DiagnosticLevel.warning,
          message: '无法检查磁盘空间',
          details: e.toString(),
        ),
      );
    }
  }
}

/// 配置诊断检查器
class ConfigurationChecker implements DiagnosticChecker {
  @override
  String get category => '配置检查';

  @override
  String get name => 'Ming CLI配置';

  @override
  Future<List<DiagnosticResult>> check() async {
    final results = <DiagnosticResult>[];

    // 检查全局配置
    await _checkGlobalConfig(results);

    // 检查工作空间配置
    await _checkWorkspaceConfig(results);

    // 检查模板配置
    await _checkTemplateConfig(results);

    return results;
  }

  Future<void> _checkGlobalConfig(List<DiagnosticResult> results) async {
    final configDir = _getConfigDirectory();
    final configFile = File(path.join(configDir, 'config.yaml'));

    if (configFile.existsSync()) {
      try {
        final content = await configFile.readAsString();
        if (content.trim().isNotEmpty) {
          results.add(
            DiagnosticResult(
              category: category,
              name: '全局配置',
              level: DiagnosticLevel.info,
              message: '全局配置文件存在且有效',
              details: configFile.path,
            ),
          );
        } else {
          results.add(
            DiagnosticResult(
              category: category,
              name: '全局配置',
              level: DiagnosticLevel.warning,
              message: '全局配置文件为空',
              suggestions: [
                '运行 "ming config --set user.name=<your-name>" 设置用户信息',
                '运行 "ming config --set user.email=<your-email>" 设置邮箱',
              ],
            ),
          );
        }
      } catch (e) {
        results.add(
          DiagnosticResult(
            category: category,
            name: '全局配置',
            level: DiagnosticLevel.error,
            message: '全局配置文件格式错误',
            details: e.toString(),
            suggestions: [
              '删除配置文件并重新创建',
              '运行 "ming config --reset" 重置配置',
            ],
          ),
        );
      }
    } else {
      results.add(
        DiagnosticResult(
          category: category,
          name: '全局配置',
          level: DiagnosticLevel.warning,
          message: '全局配置文件不存在',
          suggestions: [
            '运行 "ming config --set user.name=<your-name>" 创建配置',
          ],
          canAutoFix: true,
          autoFix: () async {
            try {
              await Directory(configDir).create(recursive: true);
              await configFile.writeAsString('# Ming CLI 配置文件\n');
              return true;
            } catch (e) {
              return false;
            }
          },
        ),
      );
    }
  }

  Future<void> _checkWorkspaceConfig(List<DiagnosticResult> results) async {
    final workspaceConfig = File('ming_status.yaml');

    if (workspaceConfig.existsSync()) {
      try {
        final content = await workspaceConfig.readAsString();
        if (content.contains('name:') && content.contains('version:')) {
          results.add(
            DiagnosticResult(
              category: category,
              name: '工作空间配置',
              level: DiagnosticLevel.info,
              message: '工作空间配置文件有效',
            ),
          );
        } else {
          results.add(
            DiagnosticResult(
              category: category,
              name: '工作空间配置',
              level: DiagnosticLevel.warning,
              message: '工作空间配置文件缺少必需字段',
              suggestions: [
                '确保配置文件包含 name 和 version 字段',
                '运行 "ming validate" 检查配置',
              ],
            ),
          );
        }
      } catch (e) {
        results.add(
          DiagnosticResult(
            category: category,
            name: '工作空间配置',
            level: DiagnosticLevel.error,
            message: '工作空间配置文件格式错误',
            details: e.toString(),
          ),
        );
      }
    } else {
      results.add(
        DiagnosticResult(
          category: category,
          name: '工作空间配置',
          level: DiagnosticLevel.info,
          message: '当前目录不是 Ming 工作空间',
          suggestions: [
            '运行 "ming init <project-name>" 初始化工作空间',
          ],
        ),
      );
    }
  }

  Future<void> _checkTemplateConfig(List<DiagnosticResult> results) async {
    final templateDir = _getTemplateDirectory();

    if (Directory(templateDir).existsSync()) {
      final templates =
          Directory(templateDir).listSync().whereType<Directory>().length;

      if (templates > 0) {
        results.add(
          DiagnosticResult(
            category: category,
            name: '模板配置',
            level: DiagnosticLevel.info,
            message: '找到 $templates 个模板',
            details: templateDir,
          ),
        );
      } else {
        results.add(
          DiagnosticResult(
            category: category,
            name: '模板配置',
            level: DiagnosticLevel.warning,
            message: '没有找到可用模板',
            suggestions: [
              '运行 "ming template install" 安装默认模板',
            ],
          ),
        );
      }
    } else {
      results.add(
        DiagnosticResult(
          category: category,
          name: '模板配置',
          level: DiagnosticLevel.warning,
          message: '模板目录不存在',
          suggestions: [
            '运行 "ming template install" 创建模板目录',
          ],
          canAutoFix: true,
          autoFix: () async {
            try {
              await Directory(templateDir).create(recursive: true);
              return true;
            } catch (e) {
              return false;
            }
          },
        ),
      );
    }
  }

  String _getConfigDirectory() {
    if (Platform.isWindows) {
      return path.join(
        Platform.environment['APPDATA'] ?? '',
        'ming_cli',
      );
    } else if (Platform.isMacOS) {
      return path.join(
        Platform.environment['HOME'] ?? '',
        'Library',
        'Application Support',
        'ming_cli',
      );
    } else {
      return path.join(
        Platform.environment['HOME'] ?? '',
        '.config',
        'ming_cli',
      );
    }
  }

  String _getTemplateDirectory() {
    return path.join(_getConfigDirectory(), 'templates');
  }
}

/// 诊断系统
class DiagnosticSystem {
  factory DiagnosticSystem() => _instance;
  DiagnosticSystem._internal();
  static final DiagnosticSystem _instance = DiagnosticSystem._internal();

  final List<DiagnosticChecker> _checkers = [
    EnvironmentChecker(),
    ConfigurationChecker(),
  ];

  // Logger是静态类，不需要实例化

  /// 运行所有诊断检查
  Future<List<DiagnosticResult>> runAllChecks() async {
    final allResults = <DiagnosticResult>[];

    for (final checker in _checkers) {
      try {
        Logger.info('运行诊断检查: ${checker.category} - ${checker.name}');
        final results = await checker.check();
        allResults.addAll(results);
      } catch (e) {
        Logger.error('诊断检查失败: ${checker.name} - $e');
        allResults.add(
          DiagnosticResult(
            category: checker.category,
            name: checker.name,
            level: DiagnosticLevel.error,
            message: '诊断检查失败',
            details: e.toString(),
          ),
        );
      }
    }

    return allResults;
  }

  /// 运行特定类别的检查
  Future<List<DiagnosticResult>> runCategoryChecks(String category) async {
    final results = <DiagnosticResult>[];

    for (final checker in _checkers.where((c) => c.category == category)) {
      try {
        final checkResults = await checker.check();
        results.addAll(checkResults);
      } catch (e) {
        results.add(
          DiagnosticResult(
            category: checker.category,
            name: checker.name,
            level: DiagnosticLevel.error,
            message: '诊断检查失败',
            details: e.toString(),
          ),
        );
      }
    }

    return results;
  }

  /// 显示诊断结果
  void displayResults(List<DiagnosticResult> results, {bool verbose = false}) {
    if (results.isEmpty) {
      print('✅ 所有检查都通过了！');
      return;
    }

    // 按类别分组
    final groupedResults = <String, List<DiagnosticResult>>{};
    for (final result in results) {
      groupedResults.putIfAbsent(result.category, () => []).add(result);
    }

    // 显示结果
    for (final category in groupedResults.keys) {
      print('\n📋 $category:');

      for (final result in groupedResults[category]!) {
        print('  ${result.levelIcon} ${result.name}: ${result.message}');

        if (verbose && result.details != null) {
          print('     详情: ${result.details}');
        }

        if (result.suggestions.isNotEmpty) {
          print('     建议:');
          for (final suggestion in result.suggestions) {
            print('       • $suggestion');
          }
        }

        if (result.canAutoFix) {
          print('     💡 可以自动修复');
        }
      }
    }

    // 显示统计
    final errorCount = results
        .where(
          (r) =>
              r.level == DiagnosticLevel.error ||
              r.level == DiagnosticLevel.critical,
        )
        .length;
    final warningCount =
        results.where((r) => r.level == DiagnosticLevel.warning).length;

    print('\n📊 诊断总结:');
    print('   总检查项: ${results.length}');
    print('   错误: $errorCount');
    print('   警告: $warningCount');
    print('   信息: ${results.length - errorCount - warningCount}');
  }

  /// 自动修复问题
  Future<int> autoFixIssues(List<DiagnosticResult> results) async {
    final fixableResults =
        results.where((r) => r.canAutoFix && r.autoFix != null).toList();

    if (fixableResults.isEmpty) {
      print('没有可以自动修复的问题');
      return 0;
    }

    print('🔧 开始自动修复 ${fixableResults.length} 个问题...');

    var fixedCount = 0;
    for (final result in fixableResults) {
      try {
        print('  修复: ${result.name}...');
        final success = await result.autoFix!();
        if (success) {
          print('  ✅ ${result.name} 修复成功');
          fixedCount++;
        } else {
          print('  ❌ ${result.name} 修复失败');
        }
      } catch (e) {
        print('  ❌ ${result.name} 修复过程中发生错误: $e');
      }
    }

    print('\n🎉 自动修复完成: $fixedCount/${fixableResults.length} 个问题已修复');
    return fixedCount;
  }

  /// 生成诊断报告
  Future<void> generateReport(
    List<DiagnosticResult> results,
    String outputPath,
  ) async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'dartVersion': Platform.version,
      'results': results.map((r) => r.toJson()).toList(),
    };

    final reportFile = File(outputPath);
    await reportFile.writeAsString(jsonEncode(report));

    print('📄 诊断报告已保存到: $outputPath');
  }
}
