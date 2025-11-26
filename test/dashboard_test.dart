import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:worker_managment_app/widgets/dashboard_summary_row.dart';

void main() {
  testWidgets('DashboardSummaryRow displays correct data', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardSummaryRow(
            totalWorkers: 10,
            loggedIn: 7,
            absent: 3,
          ),
        ),
      ),
    );

    // Verify that the text widgets display the correct values
    expect(find.text('10'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    
    // Verify that the titles are displayed
    expect(find.text('Total Workers'), findsOneWidget);
    expect(find.text('Logged In'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
  });
}