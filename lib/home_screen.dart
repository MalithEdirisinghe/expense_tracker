import 'package:flutter/material.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> groupedExpenses = [];
  double totalExpenses = 0.0;
  double totalExpensesThisMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupedExpenses();
    _fetchTotalExpenses();
    _fetchTotalExpensesThisMonth();
  }

  Future<void> _fetchGroupedExpenses() async {
    final data = await _dbHelper.rawQuery(
      '''
      SELECT c.name AS category, SUM(e.amount) AS total_amount
      FROM expenses e
      INNER JOIN categories c ON e.category_id = c.id
      GROUP BY e.category_id
      ORDER BY c.name
      ''',
      []
    );
    setState(() {
      groupedExpenses = data;
    });
  }

  Future<void> _fetchTotalExpenses() async {
    final data = await _dbHelper.rawQuery(
      '''
      SELECT SUM(amount) AS total_amount
      FROM expenses
      ''',
      []
    );
    setState(() {
      totalExpenses = (data.first['total_amount'] ?? 0.0) as double;
    });
  }

  Future<void> _fetchTotalExpensesThisMonth() async {
    final DateTime now = DateTime.now();
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);
    final data = await _dbHelper.rawQuery(
      '''
      SELECT SUM(amount) AS total_amount
      FROM expenses
      WHERE date BETWEEN ? AND ?
      ''',
      [
        startOfMonth.toIso8601String(),
        now.toIso8601String()
      ]
    );
    setState(() {
      totalExpensesThisMonth = (data.first['total_amount'] ?? 0.0) as double;
    });
  }

  void _showExpensesForCategory(String category) async {
    final expensesForCategory = await _dbHelper.rawQuery(
      '''
      SELECT e.name, e.amount, e.date
      FROM expenses e
      INNER JOIN categories c ON e.category_id = c.id
      WHERE c.name = ?
      ''',
      [category]
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesForCategoryScreen(
          category: category,
          expenses: expensesForCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
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
                    Text('Total Expenses This Month: \$${totalExpensesThisMonth.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groupedExpenses.length,
              itemBuilder: (context, index) {
                final expenseGroup = groupedExpenses[index];
                return ListTile(
                  title: Text('${expenseGroup['category']}'),
                  trailing: Text('\$${expenseGroup['total_amount'].toStringAsFixed(2)}'),
                  onTap: () {
                    _showExpensesForCategory(expenseGroup['category']);
                  },
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
              _fetchGroupedExpenses();
              _fetchTotalExpenses();
              _fetchTotalExpensesThisMonth();
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

class ExpensesForCategoryScreen extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> expenses;

  const ExpensesForCategoryScreen({
    required this.category,
    required this.expenses,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expenses for $category')),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            title: Text('${expense['name']}'),
            subtitle: Text('${expense['date']}'),
            trailing: Text('\$${expense['amount']}'),
          );
        },
      ),
    );
  }
}
