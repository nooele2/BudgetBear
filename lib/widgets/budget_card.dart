import 'package:flutter/material.dart';
import 'package:budget_bear/services/notification_service.dart';

class UnifiedBudgetCard extends StatefulWidget {
  final dynamic firestoreService;
  final VoidCallback? onBudgetUpdated;
  final int selectedYear;  // ADD THIS
  final int selectedMonth; // ADD THIS

  const UnifiedBudgetCard({
    Key? key,
    required this.firestoreService,
    this.onBudgetUpdated,
    required this.selectedYear,  // ADD THIS
    required this.selectedMonth, // ADD THIS
  }) : super(key: key);

  @override
  State<UnifiedBudgetCard> createState() => _UnifiedBudgetCardState();
}

class _UnifiedBudgetCardState extends State<UnifiedBudgetCard> {
  final NotificationService _notificationService = NotificationService();
  bool isLoading = true;
  double monthlyBudget = 0;
  double totalSpending = 0;
  BudgetStatus status = BudgetStatus.noBudget;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  @override
  void didUpdateWidget(UnifiedBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when the selected month changes
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      _loadBudgetData();
    }
  }

  Future<void> _loadBudgetData() async {
    setState(() => isLoading = true);

    // Use the selected year/month instead of current date
    final selectedYear = widget.selectedYear;
    final selectedMonth = widget.selectedMonth;

    try {
      final summary = await widget.firestoreService.getSummaryData(selectedYear, selectedMonth);
      final budget = await widget.firestoreService.getMonthlyBudget(selectedYear, selectedMonth);
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

      // Only check notifications for the CURRENT month
      final now = DateTime.now();
      if (selectedYear == now.year && selectedMonth == now.month) {
        await _notificationService.checkBudgetAndNotify(
          year: selectedYear,
          month: selectedMonth,
          spent: spending,
          budget: budget,
        );
      }
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

    // Use selected year/month for editing
    final selectedYear = widget.selectedYear;
    final selectedMonth = widget.selectedMonth;

    // Get month name for display
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthName = monthNames[selectedMonth - 1];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Edit Budget for $monthName $selectedYear",
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: "Enter budget for $monthName (฿)",
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
                  selectedYear,
                  selectedMonth,
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
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final percentage = monthlyBudget > 0 ? (totalSpending / monthlyBudget) * 100 : 0.0;

    return GestureDetector(
      onTap: () => _showBudgetEditDialog(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF47A8A5).withOpacity(0.15),
              const Color(0xFF8F60E1).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF47A8A5).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Budget",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (monthlyBudget > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF47A8A5).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF47A8A5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "฿${monthlyBudget.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Content
              if (monthlyBudget > 0) ...[
                // Status Message
                Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: isDark 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade200,
                    color: _getStatusColor(),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Spent vs Budget
                Row(
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
                            fontSize: 20,
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
                          "Remaining",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "฿${(monthlyBudget - totalSpending).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                // No Budget State
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: isDark 
                            ? Colors.white.withOpacity(0.5) 
                            : Colors.black54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getStatusMessage(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showBudgetEditDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF47A8A5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Set Budget",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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