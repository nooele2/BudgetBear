import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:budget_bear/firebase_options.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/services/firestore.dart';

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
  String _transactionType = 'income';

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
    const Color accent = Color.fromRGBO(71, 168, 165, 1);

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
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
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }


  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(color: textColor),
        title: const Text(
          'Record Transaction',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //toggle for income/expense
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: ToggleButtons(
                    isSelected: [
                      _transactionType == 'expense',
                      _transactionType == 'income',
                    ],
                    onPressed: (index) {
                      setState(() {
                        _transactionType = index == 0 ? 'expense' : 'income';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: accent,
                    color: Colors.grey[700],
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 170),
                    children: const [
                      Text('Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //date section
              const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: const TextStyle(fontSize: 16, color: textColor),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //catagory section
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category['label']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withOpacity(0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? accent : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'], color: isSelected ? accent : Colors.grey[600], size: 26),
                          const SizedBox(height: 6),
                          Text(
                            category['label'],
                            style: TextStyle(
                              color: isSelected ? accent : textColor,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              //add amount section
              const Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('0.00', prefixIcon: const Icon(Icons.attach_money)),
                onChanged: (value) => setState(() => _spentAmount = int.tryParse(value)),
              ),
              const SizedBox(height: 24),

              //add note section
              const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
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

      //add record button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_selectedDate == null || _selectedCategory == null || _spentAmount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              try {
                final firestoreService = FirestoreService();
                await firestoreService.addTransaction(
                  title: _notes ?? '',
                  category: _selectedCategory!,
                  amount: _spentAmount!.toDouble(),
                  type: _transactionType,
                  date: _selectedDate!,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_transactionType == 'expense' ? 'Expense' : 'Income'} added!')),
                );

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding transaction: $e')),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text(
              _transactionType == 'expense' ? 'Add Expense' : 'Add Income',//dynamic
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}