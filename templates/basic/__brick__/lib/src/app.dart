import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// {{module_name}} Application
/// 
/// Main application widget for {{module_name}}
/// {{description}}
/// 
/// Created by {{author}} on {{generated_date}}
class {{module_name.pascalCase()}}App extends StatelessWidget {
  const {{module_name.pascalCase()}}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{module_name}}',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 