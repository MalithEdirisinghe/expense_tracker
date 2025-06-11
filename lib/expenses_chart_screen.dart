import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class ExpensesChartScreen extends StatefulWidget {
  const ExpensesChartScreen({super.key});

  @override
  State<ExpensesChartScreen> createState() => _ExpensesChartScreenState();
}

class _ExpensesChartScreenState extends State<ExpensesChartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _dailyExpenses = [];

  @override
  void initState() {
    super.initState();
    _fetchDailyExpenses();
  }

  Future<void> _fetchDailyExpenses() async {
    final data = await _dbHelper.queryExpensesByDate();
    setState(() {
      _dailyExpenses = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];
    final labels = <int, String>{};
    for (var i = 0; i < _dailyExpenses.length; i++) {
      final row = _dailyExpenses[i];
      final amount = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      barGroups.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: amount, color: Colors.indigo, width: 12),
        ]),
      );
      labels[i] = DateFormat('MM/dd').format(DateTime.parse(row['date'] as String));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses Over Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _dailyExpenses.isEmpty
            ? const Center(child: Text('No data'))
            : BarChart(
                BarChartData(
                  barGroups: barGroups,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final label = labels[value.toInt()] ?? '';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
