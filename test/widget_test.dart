// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expance/main.dart'; // Import AppRoot
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

// Helper to mock Firebase.initializeApp for testing environments
// This avoids needing a full Firebase setup for basic widget tests.
typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Directly use the known channel name for Firebase Core.
  const MethodChannel(
    'plugins.flutter.io/firebase_core',
  ).setMockMethodCallHandler((MethodCall call) async {
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': 'mock_apiKey',
            'appId': 'mock_appId',
            'messagingSenderId': 'mock_messagingSenderId',
            'projectId': 'mock_projectId',
          },
          'pluginConstants': {},
        },
      ];
    }
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    if (customHandlers != null) {
      customHandlers(call);
    }
    return null;
  });
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('App loads and shows LoginScreen elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppRoot());

    // Allow time for StreamBuilder in AppRoot to process initial auth state
    await tester.pumpAndSettle();

    // Verify that the LoginScreen's AppBar title is present.
    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
    // Verify that the Login button is present.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
