import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:budget_bear/firebase_options.dart';
import 'package:budget_bear/pages/home_page.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime? _selectedDate;
  String? _selectedCategory;
  int? _spentAmount;
  String? _notes;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.restaurant, 'label': 'Food'},
    {'icon': Icons.directions_car, 'label': 'Transport'},
    {'icon': Icons.lightbulb, 'label': 'Utilities'},
    {'icon': Icons.movie, 'label': 'Entertainment'},
    {'icon': Icons.savings, 'label': 'Savings'},
    {'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  InputDecoration _inputDecoration(String hintText, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Record Expense'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //date section
              const Text('Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('dd MMM yyyy')
                                .format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //category section
              const Text('Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['label'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = category['label']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'],
                              color:
                                  isSelected ? Colors.blue : Colors.grey[600],
                              size: 26),
                          const SizedBox(height: 6),
                          Text(
                            category['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[800],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              //amount section
              const Text('Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('0.00',
                    prefixIcon: const Icon(Icons.attach_money)),
                onChanged: (value) =>
                    setState(() => _spentAmount = int.tryParse(value)),
              ),
              const SizedBox(height: 24),

              //notes section
              const Text('Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: _inputDecoration('Add notes (optional)'),
                onChanged: (value) => setState(() => _notes = value),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      //add button section
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            //add logic
            onPressed: () {
              if (_selectedDate == null || _selectedCategory == null || _spentAmount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              /*
              //a map of the expense info
              final expenseData = {
                'date': DateFormat('dd MMM yyyy').format(_selectedDate!),
                'category': _selectedCategory!,
                'amount': _spentAmount!,
                'notes': _notes ?? '',
              };

              //navigate to home page and pass data....看homepage改
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(expenseData: expenseData),
                ),
              );
            */
            
            },
            icon: const Icon(Icons.check),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}