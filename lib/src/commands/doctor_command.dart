/*
---------------------------------------------------------------
File name:          doctor_command.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        环境检查命令 (Doctor command for environment diagnosis)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 环境诊断和健康检查命令;
---------------------------------------------------------------
*/

import 'dart:io';

import 'base_command.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../utils/progress_manager.dart';
import '../models/validation_result.dart';

/// 环境检查命令
/// 类似Flutter doctor，检查开发环境和工作空间状态
class DoctorCommand extends BaseCommand {
  @override
  String get name => 'doctor';

  @override
  String get description => '检查开发环境和工作空间状态';

  @override
  String get invocation => 'ming doctor';

  DoctorCommand() {
    argParser.addFlag(
      'detailed',
      abbr: 'd',
      help: '显示详细的检查信息',
      negatable: false,
    );
    
    argParser.addFlag(
      'fix',
      abbr: 'f',
      help: '自动修复可修复的问题',
      negatable: false,
    );
  }

  @override
  Future<int> execute() async {
    final detailed = argResults?['detailed'] as bool? ?? false;
    final autoFix = argResults?['fix'] as bool? ?? false;

    // 创建进度管理器
    final progress = ProgressManager(
      showProgressBar: true,
      showTaskDetails: true,
      showTimestamp: detailed, // 详细模式下显示时间戳
    );

    // 添加检查任务
    final checkers = _getCheckers();
    for (final checker in checkers) {
      progress.addTask(
        checker.name.toLowerCase().replaceAll(' ', '_'),
        '检查${checker.name}',
        '验证${checker.name}的状态和配置',
      );
    }

    // 如果启用自动修复，为需要修复的任务准备额外任务
    if (autoFix) {
      // 预扫描哪些检查器支持自动修复
      for (final checker in checkers.where((c) => c.canAutoFix)) {
        progress.addTask(
          '${checker.name.toLowerCase().replaceAll(' ', '_')}_fix',
          '修复${checker.name}',
          '自动修复${checker.name}中发现的问题',
        );
      }
    }

    // 开始进度跟踪
    progress.start(title: 'Ming Status CLI 环境检查');

    // 执行检查任务
    final result = ValidationResult();
    int passedChecks = 0;
    final failedCheckers = <HealthChecker>[];

    for (final checker in checkers) {
      try {
        final checkResult = await progress.executeTask(() async {
          return await checker.check();
        });
        
        if (checkResult.isValid) {
          passedChecks++;
        } else {
          result.messages.addAll(checkResult.messages);
          failedCheckers.add(checker);
        }
        
        if (detailed) {
          _showDetailedResult(checkResult);
        }
        
      } catch (e) {
        Logger.structuredError(
          title: '${checker.name} 检查失败',
          description: '执行环境检查时发生错误',
          context: e.toString(),
          suggestions: [
            '检查系统环境是否正常',
            '确认文件权限设置',
            '尝试重新运行检查',
            '使用 --verbose 获取详细错误信息',
          ],
        );
        result.addError('检查器 ${checker.name} 执行失败: $e');
      }
    }

    // 执行自动修复任务
    if (autoFix && failedCheckers.isNotEmpty) {
      Logger.newLine();
      Logger.subtitle('🔧 自动修复阶段');
      
      for (final checker in failedCheckers.where((c) => c.canAutoFix)) {
        try {
          final fixed = await progress.executeTask(() async {
            return await checker.autoFix();
          });
          
          if (fixed) {
            Logger.success('✅ ${checker.name} 自动修复成功');
            passedChecks++;
            failedCheckers.remove(checker);
          } else {
            Logger.warning('⚠️  ${checker.name} 自动修复失败');
          }
          
        } catch (e) {
          Logger.error('❌ ${checker.name} 自动修复异常: $e');
        }
      }
    }

    // 完成进度跟踪
    final totalChecks = checkers.length;
    final successRate = totalChecks > 0 ? (passedChecks / totalChecks * 100).round() : 0;
    progress.complete(
      summary: '环境检查完成，成功率: $successRate% ($passedChecks/$totalChecks)',
    );

    // 显示总结
    _showSummary(passedChecks, totalChecks, result);
    
    return result.isValid ? 0 : 1;
  }

  /// 获取所有检查器
  List<HealthChecker> _getCheckers() {
    return [
      SystemEnvironmentChecker(),
      WorkspaceConfigChecker(configManager),
      DependencyChecker(),
      FilePermissionChecker(),
    ];
  }

  /// 显示详细结果
  void _showDetailedResult(ValidationResult result) {
    if (result.messages.isNotEmpty) {
      for (final message in result.messages) {
        final icon = _getMessageIcon(message.severity);
        Logger.info('  $icon ${message.message}');
        if (message.file != null) {
          Logger.info('    📁 ${message.file}');
        }
      }
    }
  }

  /// 获取消息图标
  String _getMessageIcon(ValidationSeverity severity) {
    switch (severity) {
      case ValidationSeverity.error:
        return '❌';
      case ValidationSeverity.warning:
        return '⚠️ ';
      case ValidationSeverity.info:
        return 'ℹ️ ';
      case ValidationSeverity.success:
        return '✅';
    }
  }

  /// 显示检查总结
  void _showSummary(int passed, int total, ValidationResult result) {
    Logger.subtitle('检查总结');
    
    if (passed == total) {
      Logger.success('🎉 所有检查都通过了！ ($passed/$total)');
      Logger.info('您的Ming Status CLI环境配置良好。');
    } else {
      Logger.warning('⚠️  发现问题 (通过: $passed/$total)');
      
      final errorCount = result.errors.length;
      final warningCount = result.warnings.length;
      
      if (errorCount > 0) {
        Logger.error('错误: $errorCount 个');
      }
      if (warningCount > 0) {
        Logger.warning('警告: $warningCount 个');
      }
      
      Logger.newLine();
      Logger.info('建议：');
      Logger.info('• 使用 "ming doctor --detailed" 查看详细信息');
      Logger.info('• 使用 "ming doctor --fix" 尝试自动修复');
      Logger.info('• 参考文档: https://github.com/ignorant-lu/ming-status-cli/wiki');
    }
  }
}

/// 健康检查器基类
abstract class HealthChecker {
  /// 检查器名称
  String get name;
  
  /// 是否支持自动修复
  bool get canAutoFix => false;
  
  /// 执行检查
  Future<ValidationResult> check();
  
  /// 自动修复（如果支持）
  Future<bool> autoFix() async => false;
}

/// 系统环境检查器
class SystemEnvironmentChecker extends HealthChecker {
  @override
  String get name => 'Dart环境';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();
    
    try {
      // 检查Dart版本
      final dartVersion = Platform.version;
      result.addSuccess('Dart SDK: ${dartVersion.split(' ').first}');
      
      // 检查操作系统
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      result.addSuccess('操作系统: $os $osVersion');
      
      // 检查可执行文件路径
      final executable = Platform.resolvedExecutable;
      if (await File(executable).exists()) {
        result.addSuccess('Dart可执行文件: $executable');
      } else {
        result.addError('Dart可执行文件不存在: $executable');
      }
      
    } catch (e) {
      result.addError('系统环境检查失败: $e');
    }
    
    return result;
  }
}

/// 工作空间配置检查器
class WorkspaceConfigChecker extends HealthChecker {
  final dynamic configManager;
  
  WorkspaceConfigChecker(this.configManager);
  
  @override
  String get name => '工作空间配置';
  
  @override
  bool get canAutoFix => true;

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();
    
    try {
      if (configManager.isWorkspaceInitialized() == true) {
        result.addSuccess('工作空间已初始化');
        
        final config = await configManager.loadWorkspaceConfig();
        if (config != null) {
          result.addSuccess('配置文件有效: ${configManager.configFilePath}');
          result.addInfo('工作空间名称: ${config.workspace.name}');
          result.addInfo('工作空间版本: ${config.workspace.version}');
        } else {
          result.addError('配置文件无法加载');
        }
      } else {
        result.addWarning('当前目录未初始化为Ming Status工作空间');
        result.addInfo('提示: 使用 "ming init" 初始化工作空间');
      }
    } catch (e) {
      result.addError('工作空间配置检查失败: $e');
    }
    
    return result;
  }
  
  @override
  Future<bool> autoFix() async {
    try {
      if (configManager.isWorkspaceInitialized() != true) {
        // 可以在这里实现自动初始化逻辑
        // 但通常需要用户确认，所以这里返回false
        return false;
      }
    } catch (e) {
      return false;
    }
    return true;
  }
}

/// 依赖包检查器
class DependencyChecker extends HealthChecker {
  @override
  String get name => '依赖包状态';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();
    
    try {
      // 检查pubspec.yaml
      const pubspecPath = 'pubspec.yaml';
      if (await File(pubspecPath).exists()) {
        result.addSuccess('pubspec.yaml文件存在');
        
        // 检查.dart_tool目录
        if (await Directory('.dart_tool').exists()) {
          result.addSuccess('依赖包已安装');
        } else {
          result.addWarning('依赖包未安装');
          result.addInfo('提示: 运行 "dart pub get" 安装依赖');
        }
      } else {
        result.addInfo('当前目录不是Dart项目');
      }
    } catch (e) {
      result.addError('依赖包检查失败: $e');
    }
    
    return result;
  }
}

/// 文件权限检查器
class FilePermissionChecker extends HealthChecker {
  @override
  String get name => '文件权限';

  @override
  Future<ValidationResult> check() async {
    final result = ValidationResult();
    
    try {
      final currentDir = Directory.current;
      
      // 检查读权限
      try {
        await currentDir.list().first;
        result.addSuccess('目录读取权限正常');
      } catch (e) {
        result.addError('目录读取权限不足: $e');
      }
      
      // 检查写权限
      try {
        final testFile = File('${currentDir.path}/.ming_temp_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        result.addSuccess('目录写入权限正常');
      } catch (e) {
        result.addError('目录写入权限不足: $e');
      }
      
    } catch (e) {
      result.addError('文件权限检查失败: $e');
    }
    
    return result;
  }
} 