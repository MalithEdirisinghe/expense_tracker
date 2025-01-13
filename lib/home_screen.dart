import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> expenses = [];
  double totalExpensesForRange = 0.0;

  double get totalExpenses => expenses.fold(0.0, (sum, item) => sum + (item['amount'] as double));

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _fetchTotalExpensesForRange();
  }

  Future<void> _fetchExpenses() async {
    final data = await _dbHelper.queryAll('expenses');
    setState(() {
      expenses = data;
    });
  }

  Future<void> _fetchTotalExpensesForRange() async {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    final data = await _dbHelper.rawQuery(
      '''
      SELECT SUM(amount) as total_amount
      FROM expenses
      WHERE date BETWEEN ? AND ?
      ''',
      [DateFormat('yyyy-MM-dd').format(startOfMonth), DateFormat('yyyy-MM-dd').format(now)],
    );
    setState(() {
      totalExpensesForRange = (data.first['total_amount'] ?? 0.0) as double;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.pushNamed(context, '/manage_categories');
            },
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses: \$${totalExpenses.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Total Expenses This Month: \$${totalExpensesForRange.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    ...expenses.map((expense) {
                      return Text('${expense['category']}: \$${expense['amount']}');
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text('${expense['name']}'),
                  subtitle: Text(expense['date']),
                  trailing: Text('\$${expense['amount']}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_expense',
            onPressed: () async {
              await Navigator.pushNamed(context, '/add_edit_expense');
              _fetchExpenses();
              _fetchTotalExpensesForRange();
            },
            child: const Icon(Icons.add),
            tooltip: 'Add Expense',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'manage_categories',
            onPressed: () {
              Navigator.pushNamed(context, '/manage_categories');
            },
            child: const Icon(Icons.category),
            tooltip: 'Manage Categories',
          ),
        ],
      ),
    );
  }
}
