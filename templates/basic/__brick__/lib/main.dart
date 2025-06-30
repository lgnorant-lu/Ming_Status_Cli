import 'package:flutter/material.dart';
{{#use_provider}}
import 'package:provider/provider.dart';
{{/use_provider}}

import 'src/app.dart';
{{#use_provider}}
import 'src/providers/{{module_name.snakeCase()}}_provider.dart';
{{/use_provider}}

/// {{module_name}} - {{description}}
/// Created by {{author}} on {{generated_date}}
void main() {
  runApp(
{{#use_provider}}
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => {{module_name.pascalCase()}}Provider()),
      ],
      child: const {{module_name.pascalCase()}}App(),
    ),
{{/use_provider}}
{{^use_provider}}
    const {{module_name.pascalCase()}}App(),
{{/use_provider}}
  );
} 