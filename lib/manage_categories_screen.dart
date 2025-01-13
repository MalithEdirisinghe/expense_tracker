import 'package:flutter/material.dart';
import 'database_helper.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final data = await _dbHelper.queryAll('categories');
    setState(() {
      categories = data;
    });
  }

  Future<void> _addOrUpdateCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;
    if (_selectedCategoryId == null) {
      try {
        await _dbHelper.insert('categories', {'name': name});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$name" already exists!')),
        );
      }
    } else {
      await _dbHelper.update(
        'categories',
        {'name': name},
        'id = ?',
        [_selectedCategoryId],
      );
    }
    _fetchCategories();
    _categoryController.clear();
    setState(() {
      _selectedCategoryId = null;
    });
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await _dbHelper.delete('categories', 'id = ?', [id]);
      _fetchCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete category with associated expenses!')),
      );
    }
  }

  void _populateForEdit(Map<String, dynamic> category) {
    _categoryController.text = category['name'];
    setState(() {
      _selectedCategoryId = category['id'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: _selectedCategoryId == null ? 'Category Name' : 'Edit Category Name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _addOrUpdateCategory,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _populateForEdit(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCategory(category['id']),
                      ),
                    ],
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
