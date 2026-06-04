// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enercore_app/main.dart';

void main() {
  testWidgets('Initial screen renders CircularProgressIndicator on Splash', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EnercoreApp()));

    // Verify that our Splash Screen renders the CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Settle the delayed navigation timer of 2 seconds in the splash screen
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
