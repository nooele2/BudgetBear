import 'package:flutter/material.dart';

class UnifiedBudgetCard extends StatefulWidget {
  final dynamic firestoreService;
  final VoidCallback? onBudgetUpdated;

  const UnifiedBudgetCard({
    Key? key,
    required this.firestoreService,
    this.onBudgetUpdated,
  }) : super(key: key);

  @override
  State<UnifiedBudgetCard> createState() => _UnifiedBudgetCardState();
}

class _UnifiedBudgetCardState extends State<UnifiedBudgetCard> {
  bool isLoading = true;
  double monthlyBudget = 0;
  double totalSpending = 0;
  BudgetStatus status = BudgetStatus.noBudget;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    try {
      final summary = await widget.firestoreService.getSummaryData(currentYear, currentMonth);
      final budget = await widget.firestoreService.getMonthlyBudget(currentYear, currentMonth);
      final spending = summary['expense'] ?? 0.0;

      setState(() {
        monthlyBudget = budget;
        totalSpending = spending;
        
        if (budget > 0) {
          final percentage = (spending / budget) * 100;
          if (percentage >= 100) {
            status = BudgetStatus.overBudget;
          } else if (percentage >= 90) {
            status = BudgetStatus.warning;
          } else if (percentage >= 75) {
            status = BudgetStatus.caution;
          } else {
            status = BudgetStatus.onTrack;
          }
        } else {
          status = BudgetStatus.noBudget;
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        monthlyBudget = 0;
        totalSpending = 0;
        status = BudgetStatus.noBudget;
        isLoading = false;
      });
    }
  }

  Future<void> _showBudgetEditDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final TextEditingController controller =
        TextEditingController(text: monthlyBudget > 0 ? monthlyBudget.toString() : '');

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Edit Monthly Budget",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: "Enter new budget (฿)",
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromRGBO(71, 168, 165, 1)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBudget = double.tryParse(controller.text) ?? 0.0;
                
                await widget.firestoreService.setMonthlyBudget(
                  currentYear,
                  currentMonth,
                  newBudget,
                );
                
                await _loadBudgetData();
                
                if (widget.onBudgetUpdated != null) {
                  widget.onBudgetUpdated!();
                }
                
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(71, 168, 165, 1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case BudgetStatus.overBudget:
        return Colors.red;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.caution:
        return Colors.amber;
      case BudgetStatus.onTrack:
        return Colors.green;
      case BudgetStatus.noBudget:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case BudgetStatus.overBudget:
        return Icons.error;
      case BudgetStatus.warning:
        return Icons.warning;
      case BudgetStatus.caution:
        return Icons.info;
      case BudgetStatus.onTrack:
        return Icons.check_circle;
      case BudgetStatus.noBudget:
        return Icons.savings_outlined;
    }
  }

  String _getStatusMessage() {
    if (monthlyBudget <= 0) {
      return "Set your monthly budget to start tracking";
    }
    
    final percentage = (totalSpending / monthlyBudget) * 100;
    
    switch (status) {
      case BudgetStatus.overBudget:
        return "Budget exceeded! You've spent ฿${totalSpending.toStringAsFixed(2)}";
      case BudgetStatus.warning:
        return "Warning: ${percentage.toStringAsFixed(0)}% of budget used";
      case BudgetStatus.caution:
        return "Alert: ${percentage.toStringAsFixed(0)}% of budget used";
      case BudgetStatus.onTrack:
        return "Great! Only ${percentage.toStringAsFixed(0)}% used";
      case BudgetStatus.noBudget:
        return "Set your monthly budget to start tracking";
    }
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    final percentage = monthlyBudget > 0 ? (totalSpending / monthlyBudget) * 100 : 0.0;
    final remaining = monthlyBudget - totalSpending;

    return GestureDetector(
      onTap: () => _showBudgetEditDialog(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF47A8A5).withOpacity(0.3),
              const Color(0xFF8F60E1).withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF47A8A5).withOpacity(0.7),
                const Color(0xFF8F60E1).withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Header section with gradient background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Budget",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (monthlyBudget > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "฿${monthlyBudget.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // White background section
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    if (monthlyBudget > 0) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusMessage(),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (percentage / 100).clamp(0.0, 1.0),
                                backgroundColor: isDark 
                                    ? Colors.grey.shade800 
                                    : Colors.grey.shade200,
                                color: _getStatusColor(),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Spent and Budget row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Spent",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "฿${totalSpending.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Budget",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "฿${monthlyBudget.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              _getStatusMessage(),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _showBudgetEditDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(71, 168, 165, 1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Set Budget"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum BudgetStatus {
  noBudget,
  onTrack,
  caution,
  warning,
  overBudget,
}