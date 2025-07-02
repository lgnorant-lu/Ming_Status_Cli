/*
---------------------------------------------------------------
File name:          color_output_test.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        彩色输出工具测试 (Color output utilities tests)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/utils/color_output.dart';
import 'package:test/test.dart';

void main() {
  group('ColorOutput Tests', () {
    group('Basic Color Methods Tests', () {
      test('应该提供成功消息格式化', () {
        final result = ColorOutput.success('Success message');
        
        expect(result, isA<String>());
        expect(result, contains('Success message'));
        
        // 如果彩色输出启用，应该包含颜色代码
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[32m')); // 绿色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供错误消息格式化', () {
        final result = ColorOutput.error('Error message');
        
        expect(result, isA<String>());
        expect(result, contains('Error message'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[31m')); // 红色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供警告消息格式化', () {
        final result = ColorOutput.warning('Warning message');
        
        expect(result, isA<String>());
        expect(result, contains('Warning message'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[33m')); // 黄色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供信息消息格式化', () {
        final result = ColorOutput.info('Info message');
        
        expect(result, isA<String>());
        expect(result, contains('Info message'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[34m')); // 蓝色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供标题格式化', () {
        final result = ColorOutput.title('Title text');
        
        expect(result, isA<String>());
        expect(result, contains('Title text'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[1m'));  // 粗体
          expect(result, contains('\x1B[34m')); // 蓝色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供高亮文本格式化', () {
        final result = ColorOutput.highlight('Highlighted text');
        
        expect(result, isA<String>());
        expect(result, contains('Highlighted text'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[36m')); // 青色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });
    });

    group('Specialized Formatting Tests', () {
      test('应该提供文件路径格式化', () {
        final result = ColorOutput.filePath('/path/to/file.txt');
        
        expect(result, isA<String>());
        expect(result, contains('/path/to/file.txt'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[36m')); // 青色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });

      test('应该提供命令格式化', () {
        final result = ColorOutput.command('npm install');
        
        expect(result, isA<String>());
        expect(result, contains('npm install'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('\x1B[1m'));  // 粗体
          expect(result, contains('\x1B[32m')); // 绿色
          expect(result, contains('\x1B[0m'));  // 重置
        }
      });
    });

    group('Progress Bar Tests', () {
      test('应该生成基本进度条', () {
        final result = ColorOutput.progressBar(50, 100);
        
        expect(result, isA<String>());
        expect(result, contains('50%'));
        expect(result, contains('(50/100)'));
        
        if (ColorOutput.isSupported) {
          expect(result, contains('█')); // 完成字符
          expect(result, contains('░')); // 未完成字符
        }
      });

      test('应该生成0%进度条', () {
        final result = ColorOutput.progressBar(0, 100);
        
        expect(result, isA<String>());
        expect(result, contains('0%'));
        expect(result, contains('(0/100)'));
      });

      test('应该生成100%进度条', () {
        final result = ColorOutput.progressBar(100, 100);
        
        expect(result, isA<String>());
        expect(result, contains('100%'));
        expect(result, contains('(100/100)'));
      });

      test('应该生成自定义宽度进度条', () {
        final result = ColorOutput.progressBar(25, 100, width: 10);
        
        expect(result, isA<String>());
        expect(result, contains('25%'));
        expect(result, contains('(25/100)'));
      });

      test('应该处理超出范围的进度值', () {
        // 测试超出最大值
        final result1 = ColorOutput.progressBar(150, 100);
        expect(result1, isA<String>());
        
        // 测试负值
        final result2 = ColorOutput.progressBar(-10, 100);
        expect(result2, isA<String>());
        
        // 测试零除数
        final result3 = ColorOutput.progressBar(0, 0);
        expect(result3, isA<String>());
      });
    });

    group('Color Support Tests', () {
      test('应该检查颜色支持', () {
        final isSupported = ColorOutput.isSupported;
        expect(isSupported, isA<bool>());
      });

      test('应该允许启用/禁用彩色输出', () {
        // 保存原始状态
        final originalState = ColorOutput.isSupported;
        
        // 测试禁用彩色输出
        ColorOutput.setEnabled(enabled: false);
        final disabledResult = ColorOutput.success('Test');
        expect(disabledResult, equals('Test')); // 应该没有颜色代码
        
        // 测试启用彩色输出
        ColorOutput.setEnabled(enabled: true);
        final enabledResult = ColorOutput.success('Test');
        expect(enabledResult, isA<String>());
        
        // 恢复原始状态
        ColorOutput.setEnabled(enabled: originalState);
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('应该处理空字符串', () {
        expect(() => ColorOutput.success(''), returnsNormally);
        expect(() => ColorOutput.error(''), returnsNormally);
        expect(() => ColorOutput.warning(''), returnsNormally);
        expect(() => ColorOutput.info(''), returnsNormally);
        expect(() => ColorOutput.title(''), returnsNormally);
        expect(() => ColorOutput.highlight(''), returnsNormally);
        expect(() => ColorOutput.filePath(''), returnsNormally);
        expect(() => ColorOutput.command(''), returnsNormally);
      });

      test('应该处理特殊字符', () {
        const specialText = 'Text with\nnewlines\tand\tspecial chars: éñ中文';
        
        expect(() => ColorOutput.success(specialText), returnsNormally);
        expect(() => ColorOutput.error(specialText), returnsNormally);
        expect(() => ColorOutput.warning(specialText), returnsNormally);
        expect(() => ColorOutput.info(specialText), returnsNormally);
      });

      test('应该处理长文本', () {
        final longText = 'A' * 1000; // 1000个字符的长文本
        
        expect(() => ColorOutput.success(longText), returnsNormally);
        expect(() => ColorOutput.error(longText), returnsNormally);
        expect(() => ColorOutput.warning(longText), returnsNormally);
        expect(() => ColorOutput.info(longText), returnsNormally);
      });

      test('应该处理Unicode字符', () {
        const unicodeText = '🎉 项目创建完成！ ✅ 成功 ❌ 失败 ⚠️ 警告';
        
        expect(() => ColorOutput.success(unicodeText), returnsNormally);
        expect(() => ColorOutput.error(unicodeText), returnsNormally);
        expect(() => ColorOutput.warning(unicodeText), returnsNormally);
        expect(() => ColorOutput.info(unicodeText), returnsNormally);
      });
    });

    group('Consistency Tests', () {
      test('所有格式化方法应该返回非空字符串', () {
        const testText = 'Test message';
        
        final results = [
          ColorOutput.success(testText),
          ColorOutput.error(testText),
          ColorOutput.warning(testText),
          ColorOutput.info(testText),
          ColorOutput.title(testText),
          ColorOutput.highlight(testText),
          ColorOutput.filePath(testText),
          ColorOutput.command(testText),
        ];
        
        for (final result in results) {
          expect(result, isNotEmpty);
          expect(result, contains(testText));
        }
      });

      test('进度条应该保持一致的格式', () {
        final results = [
          ColorOutput.progressBar(0, 100),
          ColorOutput.progressBar(25, 100),
          ColorOutput.progressBar(50, 100),
          ColorOutput.progressBar(75, 100),
          ColorOutput.progressBar(100, 100),
        ];
        
        for (final result in results) {
          expect(result, isNotEmpty);
          expect(result, contains('%'));
          expect(result, contains('('));
          expect(result, contains('/'));
          expect(result, contains(')'));
        }
      });
    });
  });
} 
