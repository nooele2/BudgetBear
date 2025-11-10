import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:budget_bear/firebase_options.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/pages/more_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
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
  String _transactionType = 'expense';

  final List<Map<String, dynamic>> _expenseCategories = [
    {'icon': Icons.restaurant, 'label': 'Food'},
    {'icon': Icons.directions_car, 'label': 'Transport'},
    {'icon': Icons.lightbulb, 'label': 'Utilities'},
    {'icon': Icons.movie, 'label': 'Entertainment'},
    {'icon': Icons.shopping_cart, 'label': 'Shopping'},
    {'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'icon': Icons.work, 'label': 'Salary'},
    {'icon': Icons.card_giftcard, 'label': 'Gift'},
    {'icon': Icons.attach_money, 'label': 'Investment'},
    {'icon': Icons.savings, 'label': 'Savings'},
    {'icon': Icons.account_balance, 'label': 'Interest'},
    {'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  List<Map<String, dynamic>> get _currentCategories {
    return _transactionType == 'expense' ? _expenseCategories : _incomeCategories;
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color.fromRGBO(71, 168, 165, 1),
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(
                    primary: Color.fromRGBO(71, 168, 165, 1),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  InputDecoration _inputDecoration(String hintText, {Widget? prefixIcon, required bool isDark}) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    final Color fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final Color hintColor = isDark ? Colors.grey.shade500 : Colors.grey;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text(
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

              //toggle for Income/Expense
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
                        _selectedCategory = null; // clear selection if switched
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.white,
                    fillColor: accent,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    borderColor: borderColor,
                    selectedBorderColor: accent,
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
              Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                      Icon(Icons.calendar_today, color: isDark ? Colors.grey[400] : Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //category section
              const Text(
              'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final category = _currentCategories[index];
                  final isSelected = _selectedCategory == category['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category['label']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withOpacity(0.15) : cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? accent : borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected
                                ? accent
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            size: 26,
                          ),
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
              Text('Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  '0.00',
                  prefixIcon: Icon(Icons.attach_money, color: isDark ? Colors.grey[400] : Colors.grey),
                  isDark: isDark,
                ),
                onChanged: (value) => setState(() => _spentAmount = int.tryParse(value)),
              ),
              const SizedBox(height: 24),

              //add note section
              Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Add notes (optional)', isDark: isDark),
                onChanged: (value) => setState(() => _notes = value),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      //bottom --> button and nav bar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_selectedDate == null ||
                      _selectedCategory == null ||
                      _spentAmount == null) {
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
                      SnackBar(
                        content: Text(
                          '${_transactionType == 'expense' ? 'Expense' : 'Income'} added!',
                        ),
                      ),
                    );

                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding transaction: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: Text(
                  _transactionType == 'expense'
                      ? 'Add Expense'
                      : 'Add Income',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const BottomNavBar(currentIndex: 2),
        ],
      ),
      //end of button and nav bar
    );
  }
}