/*
---------------------------------------------------------------
File name:          ming.dart
Author:             lgnorant-lu
Date created:       2025/07/14
Last modified:      2025/07/14
Dart Version:       3.2+
Description:        智能CLI路由器 (Smart CLI Router)
---------------------------------------------------------------
Change History:
    2025/07/14: Initial creation - 双入口架构实现;
---------------------------------------------------------------
*/

import 'dart:io';

/// 智能CLI路由器
/// 根据命令类型自动选择快速入口或完整入口
void main(List<String> arguments) async {
  // 快速命令列表 - 这些命令使用轻量级实现
  const fastCommands = {
    'version', '--version', '-v',
    'help', '--help', '-h',
    'doctor',
  };

  // 检查是否为快速命令
  final isFastCommand = arguments.isEmpty || 
      fastCommands.contains(arguments.first) ||
      arguments.any((arg) => fastCommands.contains(arg));

  if (isFastCommand) {
    // 使用快速入口
    await _runFastMode(arguments);
  } else {
    // 使用完整入口
    await _runFullMode(arguments);
  }
}

/// 快速模式 - 轻量级实现
Future<void> _runFastMode(List<String> arguments) async {
  if (arguments.isEmpty || arguments.contains('--help') || arguments.contains('-h')) {
    _showFastHelp();
    return;
  }

  if (arguments.contains('--version') || arguments.contains('-v')) {
    _showVersion();
    return;
  }

  final command = arguments.isNotEmpty ? arguments.first : '';

  switch (command) {
    case 'version':
      _showVersion();
      break;
    case 'help':
      _showFastHelp();
      break;
    case 'doctor':
      await _runFastDoctor();
      break;
    default:
      _showFastHelp();
  }
}

/// 完整模式 - 调用原始CLI
Future<void> _runFullMode(List<String> arguments) async {
  print('🔄 加载完整功能...');
  
  // 调用完整的CLI实现
  final result = await Process.run(
    'dart',
    ['run', 'bin/ming_status_cli.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
  
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}

/// 显示版本信息
void _showVersion() {
  print('ℹ️  ming_status_cli 1.0.0');
}

/// 显示快速帮助
void _showFastHelp() {
  print('''
┌─────────────────────────────────────────────────────────────────────────────┐
│  🌟 MING STATUS CLI - 企业级项目管理和模板生态系统                              │
│                                                                             │
│  ⚡ 让代码组织更简单，让开发更高效                                              │
│  🎯 专为现代化企业级开发而设计                                                  │
│                                                                             │
│  👨‍💻 Created by lgnorant-lu                                                  │
│  🔗 https://github.com/lgnorant-lu/Ming_Status_Cli                         │
└─────────────────────────────────────────────────────────────────────────────┘

📋 🚀 快速开始
  ming doctor                    # 检查开发环境 (快速)
  ming init my-project           # 创建新项目
  ming template list             # 浏览模板

📋 📖 基本用法
  ming <command> [arguments]     # 基本格式
  ming help <command>            # 查看命令帮助

📋 🏗️  核心命令
  init     - 🚀 初始化工作空间
  create   - 📦 创建模块或项目
  config   - ⚙️  配置管理
  doctor   - 🔍 环境检查 (快速模式)
  validate - ✅ 验证项目
  optimize - ⚡ 性能优化
  version  - ℹ️  版本信息 (快速模式)

📋 📚 高级功能
  template - 🎨 模板管理系统
  registry - 🗄️  注册表管理

📋 💡 获取详细帮助
  ming help <command>            # 命令详细帮助
  ming <command> --help          # 子命令帮助

⚡ 性能提示: 
  • version, help, doctor 命令使用快速模式 (~2秒)
  • 其他命令使用完整模式 (~6秒) 但功能完整

✨ 感谢使用 Ming Status CLI！
''');
}

/// 快速环境检查
Future<void> _runFastDoctor() async {
  print('🔍 快速环境检查...');
  
  final checks = <String, Future<bool>>{
    'Dart环境': _checkDart(),
    '工作目录': _checkWorkingDirectory(),
    '项目配置': _checkProjectConfig(),
  };
  
  var passedChecks = 0;
  final totalChecks = checks.length;
  
  for (final entry in checks.entries) {
    final name = entry.key;
    final checkFuture = entry.value;
    
    try {
      final passed = await checkFuture;
      if (passed) {
        print('✅ $name: 正常');
        passedChecks++;
      } else {
        print('❌ $name: 异常');
      }
    } catch (e) {
      print('⚠️  $name: 检查失败 - $e');
    }
  }
  
  print('');
  print('📊 检查结果: $passedChecks/$totalChecks 通过');
  
  if (passedChecks == totalChecks) {
    print('🎉 环境检查通过！');
  } else {
    print('⚠️  发现问题，使用 "ming doctor --detailed" 获取详细信息');
  }
}

/// 检查Dart环境
Future<bool> _checkDart() async {
  try {
    final result = await Process.run('dart', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// 检查工作目录
Future<bool> _checkWorkingDirectory() async {
  try {
    final currentDir = Directory.current;
    return await currentDir.exists();
  } catch (e) {
    return false;
  }
}

/// 检查项目配置
Future<bool> _checkProjectConfig() async {
  try {
    final pubspecFile = File('pubspec.yaml');
    return await pubspecFile.exists();
  } catch (e) {
    return false;
  }
}
