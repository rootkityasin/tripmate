//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tripmate/main.dart';

void main() {
  testWidgets('TripMate app loads correctly', (WidgetTester tester) async {
    // Build our app directly (bypassing main() to avoid Hive initialization)
    await tester.pumpWidget(const MyApp());

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that our app title appears on the home tab.
    expect(find.text('TripMate'), findsOneWidget);
    expect(find.text('Welcome to TripMate!'), findsOneWidget);
    expect(find.text('Your smart offline travel companion'), findsOneWidget);

    // Verify that the navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Navigation between tabs works', (WidgetTester tester) async {
    // Build our app directly
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap on Journal tab
    await tester.tap(find.text('Journal'));
    await tester.pump();

    // Verify Journal page loaded by checking for unique content
    expect(find.text('Document your travel memories'), findsOneWidget);

    // Tap on Checklist tab
    await tester.tap(find.text('Checklist'));
    await tester.pump();

    // Verify Checklist page loaded by checking for unique content
    expect(find.text('Never forget important items'), findsOneWidget);

    // Go back to Home tab
    await tester.tap(find.text('Home'));
    await tester.pump();

    // Verify we're back on home by checking unique home content
    expect(find.text('Welcome to TripMate!'), findsOneWidget);
  });
}
