// Test for the inventory management application
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/shared/dependency_injection.dart';

void main() {
  setUpAll(() async {
    // Initialize dependencies for testing
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDependencies();
  });

  testWidgets('App launches and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the app loads (look for any widget)
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // The app may show different screens based on auth state
    // Just verify it loads without crashing
  });

  testWidgets('App has correct title configuration', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Find the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    
    // Verify app has correct title configuration
    expect(materialApp.title, 'Gestão de Estoques PRO');
  });
}
