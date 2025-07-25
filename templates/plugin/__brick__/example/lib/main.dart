/*
---------------------------------------------------------------
File name:          main.dart
Author:             {{author}}{{#author_email}}
Email:              {{author_email}}{{/author_email}}
Date created:       {{generated_date}}
Last modified:      {{generated_date}}
Dart Version:       {{dart_version}}
Description:        {{plugin_name.titleCase()}}插件示例应用
---------------------------------------------------------------
Change History:
    {{generated_date}}: Initial creation - 插件示例应用;
---------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:{{plugin_name}}/{{plugin_name}}.dart';

void main() {
  runApp(const {{plugin_name.pascalCase()}}ExampleApp());
}

/// {{plugin_name.titleCase()}}插件示例应用
class {{plugin_name.pascalCase()}}ExampleApp extends StatelessWidget {
  /// 创建示例应用实例
  const {{plugin_name.pascalCase()}}ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{plugin_name.titleCase()}} Plugin Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const {{plugin_name.pascalCase()}}ExamplePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// {{plugin_name.titleCase()}}插件示例页面
class {{plugin_name.pascalCase()}}ExamplePage extends StatefulWidget {
  /// 创建示例页面实例
  const {{plugin_name.pascalCase()}}ExamplePage({super.key});

  @override
  State<{{plugin_name.pascalCase()}}ExamplePage> createState() => _{{plugin_name.pascalCase()}}ExamplePageState();
}

class _{{plugin_name.pascalCase()}}ExamplePageState extends State<{{plugin_name.pascalCase()}}ExamplePage> {
  late {{plugin_name.pascalCase()}}Plugin _plugin;
  PluginState _currentState = PluginState.unloaded;
  String _statusMessage = '插件未加载';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  @override
  void dispose() {
    _plugin.dispose();
    super.dispose();
  }

  /// 初始化插件
  void _initializePlugin() {
    _plugin = {{plugin_name.pascalCase()}}Plugin();
    
    // 监听状态变化
    _plugin.stateChanges.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _statusMessage = _getStatusMessage(state);
        });
      }
    });
  }

  /// 获取状态消息
  String _getStatusMessage(PluginState state) {
    switch (state) {
      case PluginState.uninitialized:
        return '插件未初始化';
      case PluginState.initializing:
        return '插件初始化中';
      case PluginState.unloaded:
        return '插件未加载';
      case PluginState.loaded:
        return '插件已加载';
      case PluginState.initialized:
        return '插件已初始化';
      case PluginState.starting:
        return '插件启动中';
      case PluginState.started:
        return '插件运行中';
      case PluginState.pausing:
        return '插件暂停中';
      case PluginState.paused:
        return '插件已暂停';
      case PluginState.resuming:
        return '插件恢复中';
      case PluginState.stopping:
        return '插件停止中';
      case PluginState.stopped:
        return '插件已停止';
      case PluginState.disposing:
        return '插件销毁中';
      case PluginState.disposed:
        return '插件已销毁';
      case PluginState.error:
        return '插件错误';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(PluginState state) {
    switch (state) {
      case PluginState.uninitialized:
        return Colors.grey.shade300;
      case PluginState.initializing:
        return Colors.blue.shade200;
      case PluginState.unloaded:
        return Colors.grey;
      case PluginState.loaded:
        return Colors.orange;
      case PluginState.initialized:
        return Colors.blue;
      case PluginState.starting:
        return Colors.green.shade200;
      case PluginState.started:
        return Colors.green;
      case PluginState.pausing:
        return Colors.yellow.shade200;
      case PluginState.paused:
        return Colors.yellow;
      case PluginState.resuming:
        return Colors.green.shade300;
      case PluginState.stopping:
        return Colors.red.shade200;
      case PluginState.stopped:
        return Colors.red;
      case PluginState.disposing:
        return Colors.grey.shade400;
      case PluginState.disposed:
        return Colors.grey.shade600;
      case PluginState.error:
        return Colors.red.shade700;
    }
  }

  /// 执行插件操作
  Future<void> _executeAction(String action) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      switch (action) {
        case 'initialize':
          await _plugin.initialize();
          break;
        case 'start':
          await _plugin.start();
          break;
        case 'pause':
          await _plugin.pause();
          break;
        case 'resume':
          await _plugin.resume();
          break;
        case 'stop':
          await _plugin.stop();
          break;
        case 'dispose':
          await _plugin.dispose();
          _initializePlugin(); // 重新创建插件实例
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示插件信息
  void _showPluginInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('插件信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('插件ID', _plugin.id),
            _buildInfoRow('插件名称', _plugin.name),
            _buildInfoRow('版本', _plugin.version),
            _buildInfoRow('描述', _plugin.description),
            _buildInfoRow('作者', _plugin.author),
            _buildInfoRow('类型', _plugin.category.name),
            const SizedBox(height: 16),
            const Text('支持的平台:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(_plugin.supportedPlatforms.map((platform) => 
              Text('• ${platform.name}'))),
            const SizedBox(height: 16),
            const Text('所需权限:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(_plugin.requiredPermissions.map((permission) => 
              Text('• ${permission.displayName}'))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{plugin_name.titleCase()}} Plugin Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showPluginInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: '插件信息',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态显示卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentState),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '当前状态: $_statusMessage',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 控制按钮
            const Text(
              '插件控制',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _currentState == PluginState.unloaded && !_isLoading
                      ? () => _executeAction('initialize')
                      : null,
                  child: const Text('初始化'),
                ),
                ElevatedButton(
                  onPressed: _currentState == PluginState.initialized && !_isLoading
                      ? () => _executeAction('start')
                      : null,
                  child: const Text('启动'),
                ),
                ElevatedButton(
                  onPressed: _currentState == PluginState.started && !_isLoading
                      ? () => _executeAction('pause')
                      : null,
                  child: const Text('暂停'),
                ),
                ElevatedButton(
                  onPressed: _currentState == PluginState.paused && !_isLoading
                      ? () => _executeAction('resume')
                      : null,
                  child: const Text('恢复'),
                ),
                ElevatedButton(
                  onPressed: (_currentState == PluginState.started || 
                             _currentState == PluginState.paused) && !_isLoading
                      ? () => _executeAction('stop')
                      : null,
                  child: const Text('停止'),
                ),
                ElevatedButton(
                  onPressed: _currentState != PluginState.unloaded && !_isLoading
                      ? () => _executeAction('dispose')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('销毁'),
                ),
              ],
            ),
            
            const SizedBox(height: 32),{{#include_ui_components}}
            
            // 插件UI组件
            if (_currentState == PluginState.started) ...[
              const Text(
                '插件界面',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: (_plugin.getMainWidget() as Widget?) ??
                        const Center(
                          child: Text(
                            '插件主界面\n(实际实现中应返回Widget)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    '请先启动插件以查看插件界面',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],{{/include_ui_components}}{{^include_ui_components}}
            
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.extension,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '{{plugin_name.titleCase()}} Plugin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '{{description}}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),{{/include_ui_components}}
          ],
        ),
      ),
    );
  }
}
