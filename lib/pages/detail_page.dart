import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_bear/services/firestore.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({Key? key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FirestoreService firestoreService = FirestoreService();
  
  DateTime selectedDate = DateTime.now();
  String? selectedCategory;
  String? selectedType; //expense and or income
  
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);
    
    final transactions = await firestoreService.getTransactions(
      selectedDate.year,
      selectedDate.month,
    );
    
    setState(() {
      allTransactions = transactions;
      _applyFilters();
      isLoading = false;
    });
  }

  void _applyFilters() {
    filteredTransactions = allTransactions.where((tx) {
      final txDate = (tx['date'] as dynamic).toDate() as DateTime;
      final isSameDay = txDate.year == selectedDate.year &&
          txDate.month == selectedDate.month &&
          txDate.day == selectedDate.day;
      
      if (!isSameDay) return false;
      
      //by category
      if (selectedCategory != null && tx['category'] != selectedCategory) {
        return false;
      }
      
      //by type
      if (selectedType != null && tx['type'] != selectedType) {
        return false;
      }
      
      return true;
    }).toList();
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _applyFilters();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempCategory = selectedCategory;
        String? tempType = selectedType;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Filter Transactions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Type',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempType == null,
                        onSelected: (selected) {
                          setDialogState(() => tempType = null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Expense'),
                        selected: tempType == 'expense',
                        onSelected: (selected) {
                          setDialogState(() => tempType = selected ? 'expense' : null);
                        },
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: tempType == 'income',
                        onSelected: (selected) {
                          setDialogState(() => tempType = selected ? 'income' : null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempCategory == null,
                        onSelected: (selected) {
                          setDialogState(() => tempCategory = null);
                        },
                      ),
                      ...['Food', 'Transport', 'Utilities', 'Entertainment', 'Shopping', 'Salary', 'Gift', 'Investment', 'Other']
                          .map((cat) => FilterChip(
                                label: Text(cat),
                                selected: tempCategory == cat,
                                onSelected: (selected) {
                                  setDialogState(() => tempCategory = selected ? cat : null);
                                },
                              )),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = tempCategory;
                      selectedType = tempType;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(71, 168, 165, 1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);

    final dayTotal = filteredTransactions.fold<double>(
      0.0,
      (sum, tx) {
        final type = (tx['type'] ?? '').toString().toLowerCase();
        final amount = (tx['amount'] ?? 0.0).toDouble();
        return type == 'expense' ? sum - amount : sum + amount;
      },
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(color: textColor),
        title: const Text(
          'Transaction Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: textColor),
                if (selectedCategory != null || selectedType != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          //date selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: accent,
                  onPressed: () => _changeDate(-1),
                ),
                ...List.generate(5, (index) {
                  final date = selectedDate.add(Duration(days: index - 2));
                  final isSelected = index == 2;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                        _applyFilters();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: accent,
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          //filter
          if (selectedCategory != null || selectedType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Filters: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (selectedType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(selectedType!),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedType = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: accent.withOpacity(0.2),
                      ),
                    ),
                  if (selectedCategory != null)
                    Chip(
                      label: Text(selectedCategory!),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          selectedCategory = null;
                          _applyFilters();
                        });
                      },
                      backgroundColor: accent.withOpacity(0.2),
                    ),
                ],
              ),
            ),

          //day summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredTransactions.length} transaction${filteredTransactions.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Day Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${dayTotal >= 0 ? '+' : ''}${dayTotal.toStringAsFixed(2)} ฿',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dayTotal >= 0 ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          //transaction list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions for this day',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = filteredTransactions[index];
                          final type = (tx['type'] ?? '').toString().toLowerCase();
                          final isExpense = type == 'expense';
                          final amount = (tx['amount'] ?? 0.0).toDouble();
                          final category = tx['category'] ?? 'Unknown';
                          final title = tx['title'] ?? tx['note'] ?? '';
                          final time = DateFormat('h:mm a').format(
                            (tx['date'] as dynamic).toDate(),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isExpense
                                      ? Colors.redAccent.withOpacity(0.15)
                                      : Colors.green.withOpacity(0.15),
                                  child: Icon(
                                    isExpense
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isExpense
                                        ? Colors.redAccent
                                        : Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (title.isNotEmpty)
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} ฿',
                                  style: TextStyle(
                                    color: isExpense
                                        ? Colors.redAccent
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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