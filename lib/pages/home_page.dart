import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/detail_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/widgets/budget_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController _budgetController = TextEditingController();

  final List<String> months = const [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  int selectedYear = DateTime.now().year;
  int currentMonthIndex = DateTime.now().month - 1;

  double totalSpending = 0.0;
  double totalIncome = 0.0;
  double monthlyBudget = 0.0;
  Map<String, double> categoryData = {};
  List<double> monthlyExpenses = List.filled(12, 0.0);

  bool isLoading = true;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSummaryData();
  }

  Future<void> _loadUserName() async {
    final name = await firestoreService.getUserName();
    setState(() {
      userName = name ?? "User";
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Future<void> _loadSummaryData() async {
    setState(() => isLoading = true);

    final summary = await firestoreService.getSummaryData(
      selectedYear,
      currentMonthIndex + 1,
    );

    final currentBudget = await firestoreService.getMonthlyBudget(
      selectedYear,
      currentMonthIndex + 1,
    );

    _budgetController.text = currentBudget > 0 ? currentBudget.toString() : '';

    final allCategories = Map<String, double>.from(summary['categories'] ?? {});

    final expenseCategories = Map.fromEntries(
      allCategories.entries
          .where((entry) => entry.value > 0)
          .map((e) => MapEntry(e.key, e.value)),
    );

    final monthSummary = await firestoreService.getMonthlyExpenses(selectedYear) ?? {};

    monthlyExpenses = List.generate(
      12,
      (i) => monthSummary[i + 1]?.abs() ?? 0.0,
    );

    _budgetController.text = currentBudget > 0 ? currentBudget.toString() : '';

    setState(() {
      totalIncome = summary['income'] ?? 0.0;
      totalSpending = summary['expense'] ?? 0.0;
      categoryData = expenseCategories;
      monthlyBudget = currentBudget;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    int tempYear = selectedYear;
    int tempMonth = currentMonthIndex;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => setStateDialog(() => tempYear--),
                        ),
                        Text(
                          "$tempYear",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => setStateDialog(() => tempYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        itemCount: months.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.3,
                        ),
                        itemBuilder: (context, index) {
                          final bool selected =
                              index == tempMonth && tempYear == selectedYear;
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                currentMonthIndex = index;
                                selectedYear = tempYear;
                              });
                              _loadSummaryData();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color.fromRGBO(71, 168, 165, 1)
                                    : isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                months[index].substring(0, 3),
                                style: TextStyle(
                                  color: selected 
                                      ? Colors.white 
                                      : isDark ? Colors.white : Colors.black87,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      if (currentMonthIndex == 0) {
        currentMonthIndex = 11;
        selectedYear--;
      } else {
        currentMonthIndex--;
      }
    });
    _loadSummaryData();
  }

  void _goToNextMonth() {
    setState(() {
      if (currentMonthIndex == 11) {
        currentMonthIndex = 0;
        selectedYear++;
      } else {
        currentMonthIndex++;
      }
    });
    _loadSummaryData();
  }


  Future<void> _showBudgetEditDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final TextEditingController controller =
        TextEditingController(text: monthlyBudget > 0 ? monthlyBudget.toString() : '');

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
                await firestoreService.setMonthlyBudget(
                  selectedYear,
                  currentMonthIndex + 1,
                  newBudget,
                );
                setState(() {
                  monthlyBudget = newBudget;
                });
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

  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subtextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_getGreeting()}, ${userName.isNotEmpty ? userName : 'User'}!",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 18),
                              color: accent,
                              onPressed: _goToPreviousMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            GestureDetector(
                              onTap: () => _showMonthYearPicker(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.3),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${months[currentMonthIndex].substring(0, 3)} $selectedYear",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 24),
                              color: accent,
                              onPressed: _goToNextMonth,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Budget Card
                    UnifiedBudgetCard(
                    firestoreService: firestoreService,
                    onBudgetUpdated: () {
                      // Optionally reload other data if needed
                      _loadSummaryData();
                    },
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards  
                    LayoutBuilder(builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 600;
                      final netSavings = (monthlyBudget > 0)
                          ? (monthlyBudget - totalSpending)
                          : (totalIncome - totalSpending);
                      final spendingText = "฿${totalSpending.toStringAsFixed(2)}";
                      final incomeText = "฿${totalIncome.toStringAsFixed(2)}";
                      final savingsText = "฿${netSavings.toStringAsFixed(2)}";

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                title: "Total Spending",
                                amount: spendingText,
                                icon: Icons.arrow_downward,
                                color: Colors.redAccent,
                                width: double.infinity,
                                height: 130,
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                title: "Total Income",
                                amount: incomeText,
                                icon: Icons.arrow_upward,
                                color: Colors.green,
                                width: double.infinity,
                                height: 130,
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                title: "Net Savings",
                                amount: savingsText,
                                icon: Icons.account_balance_wallet,
                                color: accent,
                                width: double.infinity,
                                height: 130,
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _summaryCard(
                              title: "Total Spending",
                              amount: spendingText,
                              icon: Icons.arrow_downward,
                              color: Colors.redAccent,
                              width: double.infinity,
                              height: 130,
                              cardColor: cardColor,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            const SizedBox(height: 12),
                            _summaryCard(
                              title: "Total Income",
                              amount: incomeText,
                              icon: Icons.arrow_upward,
                              color: Colors.green,
                              width: double.infinity,
                              height: 130,
                              cardColor: cardColor,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            const SizedBox(height: 12),
                            _summaryCard(
                              title: "Net Savings",
                              amount: savingsText,
                              icon: Icons.account_balance_wallet,
                              color: accent,
                              width: double.infinity,
                              height: 130,
                              cardColor: cardColor,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                          ],
                        );
                      }
                    }),
                    const SizedBox(height: 24),

                    // Charts Section
                    LayoutBuilder(builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _donutChartCard(categoryData, cardColor, textColor, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _barChartCard(monthlyExpenses, cardColor, textColor, isDark)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _donutChartCard(categoryData, cardColor, textColor, isDark),
                            const SizedBox(height: 16),
                            _barChartCard(monthlyExpenses, cardColor, textColor, isDark),
                          ],
                        );
                      }
                    }),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Transactions",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DetailPage()),
                            );
                          },
                          child: const Text(
                            "See More",
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder(
                      stream: firestoreService.getRecentTransactionsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(
                            "No transactions yet",
                            style: TextStyle(color: subtextColor, fontSize: 16),
                          );
                        }
                        final transactions = snapshot.data!;
                        return Column(
                          children: transactions.map<Widget>((tx) {
                            final type = (tx['type'] ?? '').toString().toLowerCase();
                            final isExpense = type == 'expense';
                            final amount = (tx['amount'] ?? 0.0).toDouble();

                            return _transactionTile(
                              tx['category'] ?? "Unknown",
                              tx['title'] ?? tx['note'] ?? "",
                              "${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} ฿",
                              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                              isExpense ? Colors.redAccent : Colors.green,
                              cardColor,
                              textColor,
                              subtextColor,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  // Widgets

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required double width,
    required double height,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardColor == Colors.white
            ? [
                const BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: subtextColor)),
          const Spacer(),
          Text(amount,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _donutChartCard(Map<String, double> categoryData, Color cardColor, Color textColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardColor == Colors.white
            ? [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spending Breakdown",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: categoryData.isEmpty
                ? Center(
                    child: Text(
                      "No data yet",
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 16),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                      sections: categoryData.entries.map((entry) {
                        return PieChartSectionData(
                          color: Colors.primaries[
                              categoryData.keys.toList().indexOf(entry.key) %
                                  Colors.primaries.length],
                          value: entry.value,
                          title: entry.key,
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          radius: 40,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _barChartCard(List<double> monthlyExpenses, Color cardColor, Color textColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardColor == Colors.white
            ? [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spending Trend",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: monthlyExpenses.every((amount) => amount == 0)
                ? Center(
                    child: Text(
                      "No data yet",
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 16),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: monthlyExpenses.reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                              if (value.toInt() >= 0 && value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(12, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyExpenses[index],
                              color: const Color.fromRGBO(71, 168, 165, 1),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(
    String title,
    String subtitle,
    String amount,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardColor == Colors.white
            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
            : [],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: subtextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amount.startsWith('-') ? Colors.redAccent : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}