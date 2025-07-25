/*
---------------------------------------------------------------
File name:          {{plugin_name.snakeCase()}}_test.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件主测试文件
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件主测试文件;
---------------------------------------------------------------
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:{{plugin_name}}/{{plugin_name}}.dart';

void main() {
  group('{{plugin_name.titleCase()}} Plugin Tests', () {
    late {{plugin_name.pascalCase()}}Plugin plugin;

    setUp(() {
      plugin = {{plugin_name.pascalCase()}}Plugin();
    });

    tearDown(() async {
      if (plugin.currentState != PluginState.unloaded) {
        await plugin.dispose();
      }
    });

    group('Plugin Basic Properties', () {
      test('should have correct plugin information', () {
        expect(plugin.id, equals('{{plugin_name}}'));
        expect(plugin.name, isNotEmpty);
        expect(plugin.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
        expect(plugin.description, isNotEmpty);
        expect(plugin.author, equals('{{author}}'));
        expect(plugin.category, equals(PluginType.{{plugin_type}}));
      });

      test('should have correct platform support', () {
        expect(plugin.supportedPlatforms, isNotEmpty);{{#support_android}}
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.android));{{/support_android}}{{#support_ios}}
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.ios));{{/support_ios}}{{#support_web}}
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.web));{{/support_web}}{{#support_desktop}}
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.windows));
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.macos));
        expect(plugin.supportedPlatforms, contains(SupportedPlatform.linux));{{/support_desktop}}
      });

      test('should have correct required permissions', () {
        final permissions = plugin.requiredPermissions;{{#need_file_system}}
        expect(permissions, contains(PluginPermission.fileSystem));{{/need_file_system}}{{#need_network}}
        expect(permissions, contains(PluginPermission.network));{{/need_network}}{{#need_camera}}
        expect(permissions, contains(PluginPermission.camera));{{/need_camera}}{{#need_microphone}}
        expect(permissions, contains(PluginPermission.microphone));{{/need_microphone}}{{#need_location}}
        expect(permissions, contains(PluginPermission.location));{{/need_location}}{{#need_notifications}}
        expect(permissions, contains(PluginPermission.notifications));{{/need_notifications}}
      });

      test('should start with unloaded state', () {
        expect(plugin.currentState, equals(PluginState.unloaded));
      });
    });

    group('Plugin Lifecycle', () {
      test('should initialize successfully', () async {
        expect(plugin.currentState, equals(PluginState.unloaded));
        
        await plugin.initialize();
        
        expect(plugin.currentState, equals(PluginState.initialized));
      });

      test('should start after initialization', () async {
        await plugin.initialize();
        expect(plugin.currentState, equals(PluginState.initialized));
        
        await plugin.start();
        
        expect(plugin.currentState, equals(PluginState.started));
      });

      test('should pause when started', () async {
        await plugin.initialize();
        await plugin.start();
        expect(plugin.currentState, equals(PluginState.started));
        
        await plugin.pause();
        
        expect(plugin.currentState, equals(PluginState.paused));
      });

      test('should resume when paused', () async {
        await plugin.initialize();
        await plugin.start();
        await plugin.pause();
        expect(plugin.currentState, equals(PluginState.paused));
        
        await plugin.resume();
        
        expect(plugin.currentState, equals(PluginState.started));
      });

      test('should stop when started', () async {
        await plugin.initialize();
        await plugin.start();
        expect(plugin.currentState, equals(PluginState.started));
        
        await plugin.stop();
        
        expect(plugin.currentState, equals(PluginState.stopped));
      });

      test('should dispose properly', () async {
        await plugin.initialize();
        await plugin.start();
        
        await plugin.dispose();
        
        expect(plugin.currentState, equals(PluginState.unloaded));
      });

      test('should not start without initialization', () async {
        expect(
          () => plugin.start(),
          throwsA(isA<{{plugin_name.pascalCase()}}Exception>()),
        );
      });

      test('should not pause when not started', () async {
        await plugin.initialize();
        
        await plugin.pause();
        
        // Should not change state if not started
        expect(plugin.currentState, equals(PluginState.initialized));
      });
    });

    group('Plugin State Changes', () {
      test('should emit state changes', () async {
        final states = <PluginState>[];
        plugin.stateChanges.listen((state) {
          states.add(state);
        });

        await plugin.initialize();
        await plugin.start();
        await plugin.stop();

        expect(states, contains(PluginState.initialized));
        expect(states, contains(PluginState.started));
        expect(states, contains(PluginState.stopped));
      });

      test('should handle multiple state listeners', () async {
        var listener1Called = false;
        var listener2Called = false;

        plugin.stateChanges.listen((_) {
          listener1Called = true;
        });

        plugin.stateChanges.listen((_) {
          listener2Called = true;
        });

        await plugin.initialize();

        expect(listener1Called, isTrue);
        expect(listener2Called, isTrue);
      });
    });

    group('Plugin Messages', () {
      test('should handle getStatus message', () async {
        await plugin.initialize();
        
        final result = await plugin.handleMessage('getStatus', {});
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['state'], equals('initialized'));
        expect(result['initialized'], isTrue);
        expect(result['version'], equals(plugin.version));
      });

      test('should handle getConfig message', () async {
        await plugin.initialize();
        
        final result = await plugin.handleMessage('getConfig', {});
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result, containsKey('enabled'));
        expect(result, containsKey('logLevel'));
      });

      test('should handle updateConfig message', () async {
        await plugin.initialize();
        
        final newConfig = {
          'enabled': false,
          'debugMode': true,
          'logLevel': 'debug',
        };
        
        final result = await plugin.handleMessage('updateConfig', newConfig);
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['success'], isTrue);
      });

      test('should handle unknown message', () async {
        await plugin.initialize();
        
        final result = await plugin.handleMessage('unknownAction', {});
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result, containsKey('error'));
      });
    });{{#include_ui_components}}

    group('Plugin UI', () {
      test('should provide main widget', () async {
        await plugin.initialize();
        
        final widget = plugin.getMainWidget();
        
        expect(widget, isNotNull);
      });

      test('should provide config widget', () async {
        await plugin.initialize();
        
        final widget = plugin.getConfigWidget();
        
        expect(widget, isNotNull);
      });
    });{{/include_ui_components}}

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // 模拟初始化错误的情况
        // 这里可以通过mock或其他方式模拟错误
        
        expect(plugin.currentState, equals(PluginState.unloaded));
      });

      test('should handle invalid state transitions', () async {
        // 测试无效的状态转换
        expect(
          () => plugin.start(),
          throwsA(isA<{{plugin_name.pascalCase()}}Exception>()),
        );
      });
    });

    group('Performance Tests', () {
      test('should initialize within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await plugin.initialize();
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内
      });

      test('should start within reasonable time', () async {
        await plugin.initialize();
        
        final stopwatch = Stopwatch()..start();
        
        await plugin.start();
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3秒内
      });

      test('should handle multiple rapid state changes', () async {
        await plugin.initialize();
        await plugin.start();
        
        // 快速状态变更
        await plugin.pause();
        await plugin.resume();
        await plugin.pause();
        await plugin.resume();
        
        expect(plugin.currentState, equals(PluginState.started));
      });
    });
  });
}
