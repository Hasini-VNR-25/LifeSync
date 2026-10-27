import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/app.dart';

void main() {
  testWidgets('Home Dashboard renders Life Twin intelligence overview', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LifeSyncApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify LIFESYNC App Title & Branding
    expect(find.text('LIFESYNC'), findsOneWidget);

    // Verify Capacity Meter renders
    expect(find.text('Daily Capacity Balance'), findsOneWidget);

    // Verify Active Tasks Section renders
    expect(find.text('Active Tasks'), findsOneWidget);

    // Verify Navigation Bar items
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
