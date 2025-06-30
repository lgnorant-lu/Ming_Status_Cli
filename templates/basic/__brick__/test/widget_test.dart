import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
{{#use_provider}}
import 'package:provider/provider.dart';
{{/use_provider}}

import 'package:{{module_name.snakeCase()}}/main.dart';
{{#use_provider}}
import 'package:{{module_name.snakeCase()}}/src/providers/{{module_name.snakeCase()}}_provider.dart';
{{/use_provider}}

void main() {
  group('{{module_name}} App Tests', () {
    testWidgets('App should display welcome message', (WidgetTester tester) async {
      // Build the app
{{#use_provider}}
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => {{module_name.pascalCase()}}Provider()),
          ],
          child: const {{module_name.pascalCase()}}App(),
        ),
      );
{{/use_provider}}
{{^use_provider}}
      await tester.pumpWidget(const {{module_name.pascalCase()}}App());
{{/use_provider}}

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the welcome message is displayed
      expect(find.text('Welcome to {{module_name}}!'), findsOneWidget);
      expect(find.text('{{description}}'), findsOneWidget);
    });

    testWidgets('App should have correct app bar title', (WidgetTester tester) async {
{{#use_provider}}
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => {{module_name.pascalCase()}}Provider()),
          ],
          child: const {{module_name.pascalCase()}}App(),
        ),
      );
{{/use_provider}}
{{^use_provider}}
      await tester.pumpWidget(const {{module_name.pascalCase()}}App());
{{/use_provider}}

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('{{module_name}}'), findsOneWidget);
    });

{{#use_provider}}
    testWidgets('Counter should increment when FAB is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => {{module_name.pascalCase()}}Provider()),
          ],
          child: const {{module_name.pascalCase()}}App(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the initial counter value
      expect(find.textContaining('Counter: 0'), findsOneWidget);

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Verify counter incremented
      expect(find.textContaining('Counter: 1'), findsOneWidget);
    });

    testWidgets('Counter button should increment counter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => {{module_name.pascalCase()}}Provider()),
          ],
          child: const {{module_name.pascalCase()}}App(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the counter button
      final counterButton = find.textContaining('Counter:');
      expect(counterButton, findsOneWidget);

      await tester.tap(counterButton);
      await tester.pump();

      // Verify counter incremented
      expect(find.textContaining('Counter: 1'), findsOneWidget);
    });
{{/use_provider}}
  });

{{#use_provider}}
  group('{{module_name.pascalCase()}}Provider Tests', () {
    late {{module_name.pascalCase()}}Provider provider;

    setUp(() {
      provider = {{module_name.pascalCase()}}Provider();
    });

    test('Initial counter value should be 0', () {
      expect(provider.counter, 0);
      expect(provider.isLoading, false);
    });

    test('Increment should increase counter by 1', () {
      provider.increment();
      expect(provider.counter, 1);

      provider.increment();
      expect(provider.counter, 2);
    });

    test('Decrement should decrease counter by 1', () {
      provider.increment();
      provider.increment();
      expect(provider.counter, 2);

      provider.decrement();
      expect(provider.counter, 1);
    });

    test('Decrement should not go below 0', () {
      provider.decrement();
      expect(provider.counter, 0);
    });

    test('Reset should set counter to 0', () {
      provider.increment();
      provider.increment();
      provider.increment();
      expect(provider.counter, 3);

      provider.reset();
      expect(provider.counter, 0);
    });

    test('SetLoading should update loading state', () {
      expect(provider.isLoading, false);

      provider.setLoading(true);
      expect(provider.isLoading, true);

      provider.setLoading(false);
      expect(provider.isLoading, false);
    });

    test('PerformAsyncOperation should increment counter after delay', () async {
      expect(provider.counter, 0);
      expect(provider.isLoading, false);

      final future = provider.performAsyncOperation();
      expect(provider.isLoading, true);

      await future;
      expect(provider.counter, 1);
      expect(provider.isLoading, false);
    });
  });
{{/use_provider}}
} 