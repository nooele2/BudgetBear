import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/detail_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';

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

    //..
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
    int tempYear = selectedYear;
    int tempMonth = currentMonthIndex;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setStateDialog(() => tempYear--),
                        ),
                        Text(
                          "$tempYear",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
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
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                months[index].substring(0, 3),
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
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
  final TextEditingController controller =
      TextEditingController(text: monthlyBudget > 0 ? monthlyBudget.toString() : '');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Monthly Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter new budget (฿)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
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
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);

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
    //starts here 
    //greeting
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${_getGreeting()}, ${userName.isNotEmpty ? userName : 'User'}!",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
    
    //month slector
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

      // Budget Section
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF47A8A5), Color.fromARGB(255, 143, 96, 225)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x407C3AED),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Budget",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  monthlyBudget > 0
                      ? "฿${monthlyBudget.toStringAsFixed(0)}"
                      : "฿0",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBudgetEditDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              monthlyBudget > 0
                  ? "Let’s make every baht count!"
                  : "Set your monthly budget",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            if (monthlyBudget > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Remaining",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "฿${(monthlyBudget - totalSpending).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        color: (monthlyBudget - totalSpending) >= 0
                            ? Colors.white
                            : Colors.red.shade200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Summary Cards
      LayoutBuilder(builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;
        final netSavings = (monthlyBudget > 0)
          ? (monthlyBudget - totalSpending)
          : (totalIncome - totalSpending);
        final spendingText =
            "฿${totalSpending.toStringAsFixed(2)}";
        final incomeText = "฿${totalIncome.toStringAsFixed(2)}";
        final savingsText =
            "฿${netSavings.toStringAsFixed(2)}";

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
              ),
              const SizedBox(height: 12),
              _summaryCard(
                title: "Total Income",
                amount: incomeText,
                icon: Icons.arrow_upward,
                color: Colors.green,
                width: double.infinity,
                height: 130,
              ),
              const SizedBox(height: 12),
              _summaryCard(
                title: "Net Savings",
                amount: savingsText,
                icon: Icons.account_balance_wallet,
                color: accent,
                width: double.infinity,
                height: 130,
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
                      Expanded(child: _donutChartCard(categoryData)),
                      const SizedBox(width: 16),
                      Expanded(child: _barChartCard(monthlyExpenses)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _donutChartCard(categoryData),
                      const SizedBox(height: 16),
                      _barChartCard(monthlyExpenses),
                    ],
                  );
                }
              }),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to detail page
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text(
                      "No transactions yet",
                      style:
                          TextStyle(color: Colors.grey, fontSize: 16),
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
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      //navbar 
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
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(amount,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _donutChartCard(Map<String, double> categoryData) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, // same as summary cards
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Spending Breakdown",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: categoryData.isEmpty
              ? const Center(
                  child: Text(
                    "No data yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
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

  //barchart card
  Widget _barChartCard(List<double> monthlyExpenses) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Trend",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: monthlyExpenses.every((amount) => amount == 0)
                ? const Center(
                    child: Text(
                      "No data yet",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
                                  style: const TextStyle(fontSize: 10),
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


  Widget _transactionTile(String title, String subtitle, String amount,
      IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                color:
                    amount.startsWith('-') ? Colors.redAccent : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
        ],
      ),
    );
  }
}