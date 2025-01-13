import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'add_edit_expense_screen.dart';
import 'manage_categories_screen.dart';

void main() => runApp(const ExpenseTrackerApp());

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add_edit_expense': (context) => const AddEditExpenseScreen(),
        '/manage_categories': (context) => const ManageCategoriesScreen(),
      },
    );
  }
}
