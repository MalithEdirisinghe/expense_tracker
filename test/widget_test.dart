// Flutter widget test for ExpenseTrackerApp.
// Verifies that the home screen title is displayed.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('Home screen shows app title', (WidgetTester tester) async {
    // Initialize FFI for sqflite so database calls succeed in tests.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('Expense Tracker'), findsOneWidget);
  });
}
