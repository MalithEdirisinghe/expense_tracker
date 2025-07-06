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
  DateTime? _startDate;
  DateTime? _endDate;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDailyExpenses();
  }

  Future<void> _fetchDailyExpenses({DateTime? start, DateTime? end}) async {
    final data = await _dbHelper.queryExpensesByDate(
      startDate: start,
      endDate: end,
    );
    double sum = 0.0;
    for (final row in data) {
      sum += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    setState(() {
      _dailyExpenses = data;
      _total = sum;
    });
  }

  void _applyFilter() {
    _fetchDailyExpenses(start: _startDate, end: _endDate);
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchDailyExpenses();
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
            Expanded(
              child: _dailyExpenses.isEmpty
                  ? const Center(child: Text('No data'))
                  : BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text(
                                    NumberFormat.compact().format(value),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
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
          ],
        ),
      ),
    );
  }
}
