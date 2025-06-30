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
class AnsiColor {
  /// 重置所有格式
  static const String reset = '\x1B[0m';
  
  /// 前景色
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  
  /// 明亮前景色
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';
  
  /// 背景色
  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';
  
  /// 文本样式
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';
  static const String blink = '\x1B[5m';
  static const String reverse = '\x1B[7m';
  static const String strikethrough = '\x1B[9m';
}

/// 彩色输出工具
class ColorOutput {
  /// 是否启用彩色输出
  static bool _enabled = true;
  
  /// 检查是否支持彩色输出
  static bool get isSupported {
    return stdout.hasTerminal;
  }
  
  /// 启用或禁用彩色输出
  static void setEnabled(bool enabled) {
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
    current = current.clamp(0, total);
    
    final ratio = current / total;
    final completed = (ratio * width).round();
    final remaining = width - completed;
    
    final bar = '\x1B[32m${'█' * completed}\x1B[90m${'░' * remaining}\x1B[0m';
    final percentage = (ratio * 100).toInt();
    
    return '[$bar] $percentage% ($current/$total)';
  }
  
  /// 状态指示器
  static String statusIndicator(String status, {bool success = true}) {
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
    final maxLength = lines.map((line) => line.length).reduce((a, b) => a > b ? a : b);
    final width = maxLength + 4;
    
    final buffer = StringBuffer();
    
    // 顶部边框
    buffer.writeln('${AnsiColor.cyan}╭${'─' * (width - 2)}╮${AnsiColor.reset}');
    
    // 标题
    if (title != null) {
      final paddedTitle = ' $title '.padRight(width - 2);
      buffer.writeln('${AnsiColor.cyan}│${AnsiColor.bold}$paddedTitle${AnsiColor.reset}${AnsiColor.cyan}│${AnsiColor.reset}');
      buffer.writeln('${AnsiColor.cyan}├${'─' * (width - 2)}┤${AnsiColor.reset}');
    }
    
    // 内容
    for (final line in lines) {
      final paddedLine = ' $line '.padRight(width - 2);
      buffer.writeln('${AnsiColor.cyan}│${AnsiColor.reset}$paddedLine${AnsiColor.cyan}│${AnsiColor.reset}');
    }
    
    // 底部边框
    buffer.write('${AnsiColor.cyan}╰${'─' * (width - 2)}╯${AnsiColor.reset}');
    
    return buffer.toString();
  }
}

/// 格式化工具
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
      buffer.writeln(_formatTableRow(headers, columnWidths, isHeader: true));
      buffer.writeln(_formatTableSeparator(columnWidths));
    }
    
    // 数据行
    for (var i = 0; i < rows.length; i++) {
      buffer.writeln(_formatTableRow(rows[i], columnWidths, isEven: i % 2 == 0));
    }
    
    return buffer.toString();
  }
  
  static String _formatTableRow(List<String> row, List<int> widths, {bool isHeader = false, bool isEven = false}) {
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