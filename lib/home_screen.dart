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
  List<Map<String, dynamic>> groupedExpenses = [];
  double totalExpenses = 0.0;
  double totalExpensesThisMonth = 0.0;
  double predictedNextMonth = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGroupedExpenses();
    _fetchTotalExpenses();
    _fetchTotalExpensesThisMonth();
    _fetchPredictedNextMonth();
  }

  Future<void> _fetchGroupedExpenses() async {
    final data = await _dbHelper.rawQuery(
      '''
      SELECT c.name AS category, SUM(e.amount) AS total_amount
      FROM expenses e
      INNER JOIN categories c ON e.category_id = c.id
      GROUP BY e.category_id
      ORDER BY total_amount DESC
      ''',
      [],
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
      [],
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
      ],
    );
    setState(() {
      totalExpensesThisMonth = (data.first['total_amount'] ?? 0.0) as double;
    });
  }

  Future<void> _fetchPredictedNextMonth() async {
    final monthlyData = await _dbHelper.rawQuery(
      '''
      SELECT strftime('%Y-%m', date) AS month, SUM(amount) AS total_amount
      FROM expenses
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month
      ''',
      [],
    );

    if (monthlyData.isNotEmpty) {
      double sum = 0.0;
      for (final row in monthlyData) {
        sum += (row['total_amount'] ?? 0.0) as double;
      }
      setState(() {
        predictedNextMonth = sum / monthlyData.length;
      });
    } else {
      setState(() {
        predictedNextMonth = 0.0;
      });
    }
  }

  void _showExpensesForCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpensesForCategoryScreen(category: category),
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
                    Text('Total Expenses: Rs${totalExpenses.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Total Expenses This Month: Rs${totalExpensesThisMonth.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Predicted Next Month: Rs${predictedNextMonth.toStringAsFixed(2)}'),
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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('${expenseGroup['category']}'),
                    trailing: Text('Rs${expenseGroup['total_amount'].toStringAsFixed(2)}'),
                    onTap: () {
                      _showExpensesForCategory(expenseGroup['category']);
                    },
                  ),
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
              _fetchPredictedNextMonth();
            },
            child: const Icon(Icons.add),
            tooltip: 'Add Expense',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'manage_categories',
            onPressed: () async {
              await Navigator.pushNamed(context, '/manage_categories');
              _fetchGroupedExpenses();
              _fetchPredictedNextMonth();
            },
            child: const Icon(Icons.category),
            tooltip: 'Manage Categories',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'view_chart',
            onPressed: () async {
              await Navigator.pushNamed(context, '/expenses_chart');
            },
            child: const Icon(Icons.bar_chart),
            tooltip: 'View Chart',
          ),
        ],
      ),
    );
  }
}

class ExpensesForCategoryScreen extends StatefulWidget {
  final String category;

  const ExpensesForCategoryScreen({
    required this.category,
    super.key,
  });

  @override
  State<ExpensesForCategoryScreen> createState() =>
      _ExpensesForCategoryScreenState();
}

class _ExpensesForCategoryScreenState extends State<ExpensesForCategoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _expenses = [];
  DateTime? _startDate;
  DateTime? _endDate;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    String whereClause = 'WHERE c.name = ?';
    List<dynamic> args = [widget.category];
    if (_startDate != null && _endDate != null) {
      whereClause += ' AND e.date BETWEEN ? AND ?';
      args.addAll([
        _startDate!.toIso8601String(),
        _endDate!.toIso8601String(),
      ]);
    }

    final data = await _dbHelper.rawQuery(
      '''
      SELECT e.name, e.amount, e.date
      FROM expenses e
      INNER JOIN categories c ON e.category_id = c.id
      $whereClause
      ORDER BY e.date DESC
      ''',
      args,
    );

    double sum = 0.0;
    for (final row in data) {
      sum += (row['amount'] as num?)?.toDouble() ?? 0.0;
    }

    setState(() {
      _expenses = data;
      _total = sum;
    });
  }

  void _applyFilter() {
    _fetchExpenses();
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expenses for ${widget.category}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                      child: Text(
                        _startDate == null
                            ? 'Start Date'
                            : DateFormat('yyyy-MM-dd').format(_startDate!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                      child: Text(
                        _endDate == null
                            ? 'End Date'
                            : DateFormat('yyyy-MM-dd').format(_endDate!),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _applyFilter,
                      child: const Text('Apply'),
                    ),
                    TextButton(
                      onPressed: _resetFilter,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Total: Rs${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('${expense['name']}'),
                    subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(DateTime.parse(expense['date']))),
                    trailing: Text(
                        'Rs${(expense['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
