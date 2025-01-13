import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDate;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> expenses = [];
  int? _selectedExpenseId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchExpenses();
  }

  Future<void> _fetchCategories() async {
    final data = await _dbHelper.queryAll('categories');
    setState(() {
      categories = data;
      if (categories.isNotEmpty && _selectedCategory == null) {
        _selectedCategory = categories.first['name'];
      }
    });
  }

  Future<void> _fetchExpenses() async {
    final data = await _dbHelper.queryAll('expenses');
    setState(() {
      expenses = data;
    });
  }

  Future<void> _deleteExpense(int id) async {
    await _dbHelper.delete('expenses', 'id = ?', [id]);
    _fetchExpenses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense deleted successfully!')),
    );
  }

  void _populateForm(Map<String, dynamic> expense) {
    _selectedExpenseId = expense['id'];
    _nameController.text = expense['name'];
    _amountController.text = expense['amount'].toString();
    _selectedCategory = categories.firstWhere(
      (cat) => cat['id'] == expense['category_id'],
    )['name'];
    _selectedDate = DateTime.parse(expense['date']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add/Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Expense Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expense name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      try {
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String,
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                      }
                    },
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : 'Selected: ${_selectedDate!.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _selectedDate != null) {
                        final name = _nameController.text;
                        final amount = double.parse(_amountController.text);
                        final category = _selectedCategory!;
                        final date = _selectedDate!.toIso8601String();
                        final selectedCategory = categories.firstWhere(
                          (cat) => cat['name'] == category,
                        );
                        if (_selectedExpenseId == null) {
                          await _dbHelper.insert('expenses', {
                            'name': name,
                            'amount': amount,
                            'category_id': selectedCategory['id'],
                            'date': date,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense added successfully!')),
                          );
                        } else {
                          await _dbHelper.update(
                            'expenses',
                            {
                              'name': name,
                              'amount': amount,
                              'category_id': selectedCategory['id'],
                              'date': date,
                            },
                            'id = ?',
                            [_selectedExpenseId],
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense updated successfully!')),
                          );
                        }
                        _fetchExpenses();
                        _nameController.clear();
                        _amountController.clear();
                        setState(() {
                          _selectedCategory = null;
                          _selectedDate = null;
                          _selectedExpenseId = null;
                        });
                      } else if (_selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a date')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    title: Text('${expense['name']}'),
                    subtitle: Text('${expense['date']} - Category ID: ${expense['category_id']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _populateForm(expense);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteExpense(expense['id']);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
