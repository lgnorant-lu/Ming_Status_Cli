#!/usr/bin/env dart
/*
---------------------------------------------------------------
File name:          ming_status_cli.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        Ming Status CLI 主可执行文件 (Main executable)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI工具主入口点;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/ming_status_cli.dart';

/// Ming Status CLI 主入口点
/// 
/// 这是Ming Status CLI工具的主要可执行文件。
/// 负责初始化应用程序并处理命令行参数。
Future<void> main(List<String> arguments) async {
  // 创建CLI应用实例
  final app = MingStatusCliApp();
  
  // 运行应用并获取退出码
  final exitCode = await app.run(arguments);
  
  // 以指定的退出码退出程序
  exit(exitCode);
}
