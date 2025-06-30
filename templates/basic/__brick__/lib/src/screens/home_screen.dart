import 'package:flutter/material.dart';
{{#use_provider}}
import 'package:provider/provider.dart';

import '../providers/{{module_name.snakeCase()}}_provider.dart';
{{/use_provider}}

/// Home Screen for {{module_name}}
/// 
/// The main screen of the {{module_name}} application
/// {{description}}
/// 
/// Created by {{author}} on {{generated_date}}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{module_name}}'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.flutter_dash,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to {{module_name}}!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '{{description}}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
{{#use_provider}}
            const SizedBox(height: 32),
            Consumer<{{module_name.pascalCase()}}Provider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: provider.increment,
                  child: Text('Counter: ${provider.counter}'),
                );
              },
            ),
{{/use_provider}}
          ],
        ),
      ),
{{#use_provider}}
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<{{module_name.pascalCase()}}Provider>().increment();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
{{/use_provider}}
    );
  }
} 