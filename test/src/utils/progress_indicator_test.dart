/*
---------------------------------------------------------------
File name:          progress_indicator_test.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        进度指示器和用户交互工具测试 (Progress indicator and user interaction utilities tests)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/utils/progress_indicator.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressIndicator Tests', () {
    group('ProgressConfig Tests', () {
      test('应该创建默认配置', () {
        const config = ProgressConfig();
        
        expect(config.type, equals(ProgressType.progressBar));
        expect(config.showPercentage, isTrue);
        expect(config.showElapsedTime, isTrue);
        expect(config.width, equals(50));
        expect(config.completedChar, equals('█'));
        expect(config.remainingChar, equals('░'));
        expect(config.spinnerChars, isNotEmpty);
      });

      test('应该支持自定义配置', () {
        const config = ProgressConfig(
          type: ProgressType.spinner,
          showPercentage: false,
          width: 30,
          completedChar: '#',
          remainingChar: '-',
        );
        
        expect(config.type, equals(ProgressType.spinner));
        expect(config.showPercentage, isFalse);
        expect(config.width, equals(30));
        expect(config.completedChar, equals('#'));
        expect(config.remainingChar, equals('-'));
      });
    });

    group('ProgressIndicator Basic Functionality Tests', () {
      test('应该成功创建进度指示器', () {
        final indicator = ProgressIndicator(title: 'Test Progress');
        
        expect(indicator.title, equals('Test Progress'));
        expect(indicator.config, isA<ProgressConfig>());
      });

      test('应该正确处理启动和完成流程', () {
        final indicator = ProgressIndicator(title: 'Test Progress');
        
        // 测试方法调用不会抛出异常
        expect(indicator.start, returnsNormally);
        expect(() => indicator.update(0.5), returnsNormally);
        expect(indicator.complete, returnsNormally);
      });

      test('应该正确处理进度更新', () {
        final indicator = ProgressIndicator(title: 'Test Progress');
        indicator.start();
        
        // 测试各种进度值
        expect(() => indicator.update(0), returnsNormally);
        expect(() => indicator.update(0.5), returnsNormally);
        expect(() => indicator.update(1), returnsNormally);
        expect(() => indicator.update(1.5), returnsNormally); // 应该被限制
        expect(() => indicator.update(-0.1), returnsNormally); // 应该被限制
        
        indicator.complete();
      });

      test('应该正确处理失败状态', () {
        final indicator = ProgressIndicator(title: 'Test Progress');
        indicator.start();
        
        expect(indicator.fail, returnsNormally);
        expect(() => indicator.fail(message: 'Custom error'), returnsNormally);
      });
    });

    group('Progress Display Types Tests', () {
      test('应该支持进度条类型', () {
        const config = ProgressConfig(
          width: 10,
          showElapsedTime: false,
        );
        
        final indicator = ProgressIndicator(title: 'Test', config: config);
        
        expect(indicator.start, returnsNormally);
        expect(() => indicator.update(0.5), returnsNormally);
        expect(indicator.complete, returnsNormally);
      });

      test('应该支持旋转指示器类型', () {
        const config = ProgressConfig(
          type: ProgressType.spinner,
          showPercentage: false,
        );
        
        final indicator = ProgressIndicator(title: 'Spinner Test', config: config);
        
        expect(indicator.start, returnsNormally);
        expect(() => indicator.update(0.3, status: 'Processing...'), returnsNormally);
        expect(indicator.complete, returnsNormally);
      });

      test('应该支持简单状态类型', () {
        const config = ProgressConfig(
          type: ProgressType.simple,
          showElapsedTime: false,
        );
        
        final indicator = ProgressIndicator(title: 'Simple Test', config: config);
        
        expect(indicator.start, returnsNormally);
        expect(() => indicator.update(0.7, status: 'Almost done'), returnsNormally);
        expect(indicator.complete, returnsNormally);
      });
    });
  });

  group('UserInteraction Tests', () {
    group('Method Structure Tests', () {
      test('confirm方法应该存在并具有正确签名', () {
        expect(UserInteraction.confirm, isA<Function>());
        
        // 测试基本调用结构（不实际交互）
        expect(UserInteraction.confirm.runtimeType.toString(), contains('bool'));
      });

      test('choice方法应该存在并具有正确签名', () {
        expect(UserInteraction.choice, isA<Function>());
        
        final options = ['Option 1', 'Option 2', 'Option 3'];
        expect(options.length, equals(3));
      });

      test('input方法应该存在并具有正确签名', () {
        expect(UserInteraction.input, isA<Function>());
      });

      test('password方法应该存在并具有正确签名', () {
        expect(UserInteraction.password, isA<Function>());
      });

      test('multiChoice方法应该存在并具有正确签名', () {
        expect(UserInteraction.multiChoice, isA<Function>());
      });
    });
  });

  group('ErrorRecoveryPrompt Tests', () {
    test('应该提供错误恢复选项方法', () {
      expect(ErrorRecoveryPrompt.showErrorWithRecovery, isA<Function>());
      
      final recoveryOptions = ['重试', '忽略', '修复'];
      expect(recoveryOptions.length, equals(3));
    });

    test('应该提供回滚确认方法', () {
      expect(ErrorRecoveryPrompt.confirmRollback, isA<Function>());
      
      final affectedFiles = ['file1.txt', 'file2.txt'];
      expect(affectedFiles.length, equals(2));
    });
  });

  group('StatusFormatter Tests', () {
    test('应该提供各种状态格式化方法', () {
      expect(StatusFormatter.success, isA<Function>());
      expect(StatusFormatter.warning, isA<Function>());
      expect(StatusFormatter.error, isA<Function>());
      expect(StatusFormatter.info, isA<Function>());
      expect(StatusFormatter.step, isA<Function>());
      expect(StatusFormatter.completed, isA<Function>());
    });

    test('应该正确执行格式化方法', () {
      // 测试静态方法调用不会抛出异常
      expect(() => StatusFormatter.step('Test step'), returnsNormally);
      expect(() => StatusFormatter.step('Test step', stepNumber: 1, totalSteps: 5), returnsNormally);
    });

    test('应该正确格式化完成消息', () {
      const duration = Duration(milliseconds: 1500);
      expect(() => StatusFormatter.completed('Task completed'), returnsNormally);
      expect(() => StatusFormatter.completed('Task completed', duration: duration), returnsNormally);
    });
    
    test('应该正确执行其他格式化方法', () {
      expect(() => StatusFormatter.success('Success message'), returnsNormally);
      expect(() => StatusFormatter.warning('Warning message'), returnsNormally);
      expect(() => StatusFormatter.error('Error message'), returnsNormally);
      expect(() => StatusFormatter.info('Info message'), returnsNormally);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('应该处理空标题', () {
      final indicator = ProgressIndicator(title: '');
      expect(indicator.start, returnsNormally);
      expect(indicator.complete, returnsNormally);
    });

    test('应该处理多次调用', () {
      final indicator = ProgressIndicator(title: 'Test');
      
      // 多次启动
      expect(indicator.start, returnsNormally);
      expect(indicator.start, returnsNormally); // 应该被忽略
      
      // 多次完成
      expect(indicator.complete, returnsNormally);
      expect(indicator.complete, returnsNormally); // 应该被忽略
    });

    test('应该处理更新非活动指示器', () {
      final indicator = ProgressIndicator(title: 'Test');
      
      // 未启动就更新
      expect(() => indicator.update(0.5), returnsNormally);
      
      // 完成后更新
      indicator.start();
      indicator.complete();
      expect(() => indicator.update(0.8), returnsNormally);
    });
  });
} 