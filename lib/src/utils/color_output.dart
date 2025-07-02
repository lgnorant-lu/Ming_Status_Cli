/*
---------------------------------------------------------------
File name:          color_output.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        彩色输出和格式化工具 (Color output and formatting utilities)
---------------------------------------------------------------
*/

import 'dart:io';

/// ANSI颜色代码
/// 
/// 提供标准ANSI转义序列常量，用于终端彩色输出和文本格式化。
/// 包括前景色、背景色、文本样式等完整的ANSI颜色代码集。
class AnsiColor {
  /// 重置所有格式到默认状态
  static const String reset = '\x1B[0m';
  
  /// 前景色 - 基础颜色
  /// 
  /// 黑色前景色
  static const String black = '\x1B[30m';
  
  /// 红色前景色
  static const String red = '\x1B[31m';
  
  /// 绿色前景色
  static const String green = '\x1B[32m';
  
  /// 黄色前景色
  static const String yellow = '\x1B[33m';
  
  /// 蓝色前景色
  static const String blue = '\x1B[34m';
  
  /// 洋红色前景色
  static const String magenta = '\x1B[35m';
  
  /// 青色前景色
  static const String cyan = '\x1B[36m';
  
  /// 白色前景色
  static const String white = '\x1B[37m';
  
  /// 明亮前景色
  /// 明亮黑色前景色（灰色）
  static const String brightBlack = '\x1B[90m';
  /// 明亮红色前景色
  static const String brightRed = '\x1B[91m';
  /// 明亮绿色前景色
  static const String brightGreen = '\x1B[92m';
  /// 明亮黄色前景色
  static const String brightYellow = '\x1B[93m';
  /// 明亮蓝色前景色
  static const String brightBlue = '\x1B[94m';
  /// 明亮洋红色前景色
  static const String brightMagenta = '\x1B[95m';
  /// 明亮青色前景色
  static const String brightCyan = '\x1B[96m';
  /// 明亮白色前景色
  static const String brightWhite = '\x1B[97m';
  
  /// 背景色
  /// 黑色背景色
  static const String bgBlack = '\x1B[40m';
  /// 红色背景色
  static const String bgRed = '\x1B[41m';
  /// 绿色背景色
  static const String bgGreen = '\x1B[42m';
  /// 黄色背景色
  static const String bgYellow = '\x1B[43m';
  /// 蓝色背景色
  static const String bgBlue = '\x1B[44m';
  /// 洋红色背景色
  static const String bgMagenta = '\x1B[45m';
  /// 青色背景色
  static const String bgCyan = '\x1B[46m';
  /// 白色背景色
  static const String bgWhite = '\x1B[47m';
  
  /// 文本样式
  /// 粗体样式
  static const String bold = '\x1B[1m';
  /// 暗淡样式（变暗）
  static const String dim = '\x1B[2m';
  /// 斜体样式
  static const String italic = '\x1B[3m';
  /// 下划线样式
  static const String underline = '\x1B[4m';
  /// 闪烁样式
  static const String blink = '\x1B[5m';
  /// 反色样式（前景色和背景色互换）
  static const String reverse = '\x1B[7m';
  /// 删除线样式
  static const String strikethrough = '\x1B[9m';
}

/// 彩色输出工具
/// 
/// 提供丰富的终端文本着色和格式化功能，支持：
/// - 多种颜色和样式的文本输出
/// - 进度条、状态指示器等UI组件
/// - 表格、文本框等结构化显示
/// - 光标控制和终端操作
/// 
/// 自动检测终端支持情况，优雅降级到普通文本输出。
class ColorOutput {
  /// 是否启用彩色输出的内部状态标志
  static bool _enabled = true;
  
  /// 检查是否支持彩色输出
  static bool get isSupported {
    return stdout.hasTerminal;
  }
  
  /// 启用或禁用彩色输出
  static void setEnabled({required bool enabled}) {
    _enabled = enabled && isSupported;
  }
  
  /// 应用颜色格式
  static String _applyFormat(String text, String format) {
    if (!_enabled) return text;
    return '$format$text\x1B[0m';
  }
  
  /// 成功消息（绿色）
  static String success(String text) {
    return _applyFormat(text, '\x1B[32m');
  }
  
  /// 错误消息（红色）
  static String error(String text) {
    return _applyFormat(text, '\x1B[31m');
  }
  
  /// 警告消息（黄色）
  static String warning(String text) {
    return _applyFormat(text, '\x1B[33m');
  }
  
  /// 信息消息（蓝色）
  static String info(String text) {
    return _applyFormat(text, '\x1B[34m');
  }
  
  /// 调试消息（灰色）
  static String debug(String text) {
    return _applyFormat(text, AnsiColor.brightBlack);
  }
  
  /// 标题（粗体蓝色）
  static String title(String text) {
    return _applyFormat(text, '\x1B[1m\x1B[34m');
  }
  
  /// 子标题（粗体）
  static String subtitle(String text) {
    return _applyFormat(text, AnsiColor.bold);
  }
  
  /// 高亮文本（青色）
  static String highlight(String text) {
    return _applyFormat(text, '\x1B[36m');
  }
  
  /// 重要文本（粗体红色）
  static String important(String text) {
    return _applyFormat(text, '${AnsiColor.bold}${AnsiColor.red}');
  }
  
  /// 次要文本（暗色）
  static String secondary(String text) {
    return _applyFormat(text, AnsiColor.dim);
  }
  
  /// 下划线文本
  static String underline(String text) {
    return _applyFormat(text, AnsiColor.underline);
  }
  
  /// 粗体文本
  static String bold(String text) {
    return _applyFormat(text, AnsiColor.bold);
  }
  
  /// 斜体文本
  static String italic(String text) {
    return _applyFormat(text, AnsiColor.italic);
  }
  
  /// 自定义颜色
  static String custom(String text, String colorCode) {
    return _applyFormat(text, colorCode);
  }
  
  /// 彩虹文本（循环颜色）
  static String rainbow(String text) {
    if (!_enabled) return text;
    
    final colors = [
      AnsiColor.red,
      AnsiColor.yellow,
      AnsiColor.green,
      AnsiColor.cyan,
      AnsiColor.blue,
      AnsiColor.magenta,
    ];
    
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final color = colors[i % colors.length];
      buffer.write('$color${text[i]}');
    }
    buffer.write(AnsiColor.reset);
    
    return buffer.toString();
  }
  
  /// 进度条
  static String progressBar(int current, int total, {int width = 20}) {
    if (!_enabled) return '[$current/$total]';
    
    // 边界检查
    if (total <= 0) {
      return '[0/0] 0% (0/0)'; // 处理total为0或负数的情况
    }
    
    // 确保current在有效范围内
    final clampedCurrent = current.clamp(0, total);
    
    final ratio = clampedCurrent / total;
    final completed = (ratio * width).round();
    final remaining = width - completed;
    
    final bar = '\x1B[32m${'█' * completed}\x1B[90m${'░' * remaining}\x1B[0m';
    final percentage = (ratio * 100).toInt();
    
    return '[$bar] $percentage% ($clampedCurrent/$total)';
  }
  
  /// 状态指示器
  static String statusIndicator(String status, {required bool success}) {
    final color = success ? AnsiColor.green : AnsiColor.red;
    return _applyFormat(status, color);
  }
  
  /// 表格行着色（交替颜色）
  static String tableRow(String text, {bool isEven = false}) {
    if (!_enabled) return text;
    final color = isEven ? AnsiColor.brightBlack : '';
    return '$color$text${AnsiColor.reset}';
  }
  
  /// 代码块（灰色背景）
  static String codeBlock(String code) {
    return _applyFormat(code, '${AnsiColor.bgBlack}${AnsiColor.white}');
  }
  
  /// 链接样式（下划线蓝色）
  static String link(String url) {
    return _applyFormat(url, '${AnsiColor.underline}${AnsiColor.blue}');
  }
  
  /// 文件路径（青色）
  static String filePath(String path) {
    return _applyFormat(path, '\x1B[36m');
  }
  
  /// 命令（粗体绿色）
  static String command(String cmd) {
    return _applyFormat(cmd, '\x1B[1m\x1B[32m');
  }
  
  /// 变量名（黄色）
  static String variable(String varName) {
    return _applyFormat(varName, AnsiColor.yellow);
  }
  
  /// 数字（洋红色）
  static String number(String num) {
    return _applyFormat(num, AnsiColor.magenta);
  }
  
  /// 清除当前行
  static void clearLine() {
    if (_enabled) {
      stdout.write('\r\x1B[2K');
    }
  }
  
  /// 移动光标
  static void moveCursor(int line, int column) {
    if (_enabled) {
      stdout.write('\x1B[$line;${column}H');
    }
  }
  
  /// 隐藏光标
  static void hideCursor() {
    if (_enabled) {
      stdout.write('\x1B[?25l');
    }
  }
  
  /// 显示光标
  static void showCursor() {
    if (_enabled) {
      stdout.write('\x1B[?25h');
    }
  }
  
  /// 创建带边框的文本框
  static String textBox(String content, {String? title}) {
    if (!_enabled) {
      return title != null ? '$title\n$content' : content;
    }
    
    final lines = content.split('\n');
    final maxLength = lines.map((line) => line.length)
        .reduce((a, b) => a > b ? a : b);
    final width = maxLength + 4;
    
    final buffer = StringBuffer()
    
    // 顶部边框
      ..writeln('${AnsiColor.cyan}╭${'─' * (width - 2)}╮${AnsiColor.reset}');
    
    // 标题
    if (title != null) {
      final paddedTitle = ' $title '.padRight(width - 2);
      buffer
        ..writeln('${AnsiColor.cyan}│${AnsiColor.bold}$paddedTitle'
            '${AnsiColor.reset}${AnsiColor.cyan}│${AnsiColor.reset}')
        ..writeln('${AnsiColor.cyan}├${'─' * (width - 2)}┤${AnsiColor.reset}');
    }
    
    // 内容
    for (final line in lines) {
      final paddedLine = ' $line '.padRight(width - 2);
      buffer.writeln('${AnsiColor.cyan}│${AnsiColor.reset}$paddedLine'
          '${AnsiColor.cyan}│${AnsiColor.reset}');
    }
    
    // 底部边框
    buffer.write('${AnsiColor.cyan}╰${'─' * (width - 2)}╯${AnsiColor.reset}');
    
    return buffer.toString();
  }
}

/// 格式化工具
/// 
/// 提供各种数据的格式化和美化显示功能，包括：
/// - 文件大小、时间持续时间的人性化显示
/// - 百分比、列表、键值对的格式化
/// - 表格数据的结构化输出
/// 
/// 与ColorOutput配合使用，提供美观的终端数据展示。
class Formatter {
  /// 格式化字节大小
  static String fileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;
    
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    
    final formatted = size < 10 
        ? size.toStringAsFixed(1)
        : size.toStringAsFixed(0);
    
    return ColorOutput.number('$formatted ${suffixes[suffixIndex]}');
  }
  
  /// 格式化持续时间
  static String duration(Duration duration) {
    if (duration.inSeconds < 60) {
      return ColorOutput.number('${duration.inMilliseconds}ms');
    } else if (duration.inMinutes < 60) {
      return ColorOutput.number('${duration.inSeconds}s');
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return ColorOutput.number('${minutes}m ${seconds}s');
    }
  }
  
  /// 格式化百分比
  static String percentage(double value) {
    return ColorOutput.number('${(value * 100).toStringAsFixed(1)}%');
  }
  
  /// 格式化列表
  static String list(List<String> items, {String bullet = '•'}) {
    return items.map((item) => 
      '${ColorOutput.secondary(bullet)} $item',
    ).join('\n');
  }
  
  /// 格式化键值对
  static String keyValue(String key, String value, {String separator = ': '}) {
    return '${ColorOutput.bold(key)}$separator${ColorOutput.info(value)}';
  }
  
  /// 格式化表格
  static String table(List<List<String>> rows, {List<String>? headers}) {
    if (rows.isEmpty) return '';
    
    // 计算列宽
    final allRows = headers != null ? [headers, ...rows] : rows;
    final columnWidths = <int>[];
    
    for (var col = 0; col < allRows[0].length; col++) {
      var maxWidth = 0;
      for (final row in allRows) {
        if (col < row.length && row[col].length > maxWidth) {
          maxWidth = row[col].length;
        }
      }
      columnWidths.add(maxWidth + 2);
    }
    
    final buffer = StringBuffer();
    
    // 标题行
    if (headers != null) {
      buffer
        ..writeln(_formatTableRow(headers, columnWidths, isHeader: true,))
        ..writeln(_formatTableSeparator(columnWidths));
    }
    
    // 数据行
    for (var i = 0; i < rows.length; i++) {
      buffer
        ..writeln(_formatTableRow(
          rows[i], columnWidths, isEven: i.isEven,),)
        ..writeln(_formatTableSeparator(columnWidths));
    }
    
    return buffer.toString();
  }
  
  static String _formatTableRow(
      List<String> row, List<int> widths, 
      {bool isHeader = false, bool isEven = false,}) {
    final formattedCells = <String>[];
    
    for (var i = 0; i < row.length; i++) {
      final width = i < widths.length ? widths[i] : 10;
      var cell = row[i].padRight(width - 2);
      
      if (isHeader) {
        cell = ColorOutput.bold(cell);
      } else if (isEven) {
        cell = ColorOutput.tableRow(cell, isEven: true);
      }
      
      formattedCells.add(cell);
    }
    
    return '│ ${formattedCells.join(' │ ')} │';
  }
  
  static String _formatTableSeparator(List<int> widths) {
    final segments = widths.map((width) => '─' * width).toList();
    return '├─${segments.join('─┼─')}─┤';
  }
}
