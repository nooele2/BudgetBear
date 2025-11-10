import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();

  final List<String> months = const [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  int selectedYear = DateTime.now().year;
  int currentMonthIndex = DateTime.now().month - 1;

  double totalSpending = 0.0;
  double totalIncome = 0.0;
  Map<String, double> categoryData = {};

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
    setState(() {
      totalIncome = summary['income'] ?? 0.0;
      totalSpending = summary['expense'] ?? 0.0;
      categoryData = Map<String, double>.from(summary['categories'] ?? {});
      isLoading = false;
    });
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          icon: Icon(Icons.chevron_left, 
                            color: isDark ? Colors.white : Colors.black),
                          onPressed: () => setStateDialog(() => tempYear--),
                        ),
                        Text(
                          "$tempYear",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right,
                            color: isDark ? Colors.white : Colors.black),
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
                                    : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                months[index].substring(0, 3),
                                style: TextStyle(
                                  color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color subtitleColor = isDark ? Colors.white60 : Colors.grey;

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
                    Text(
                      "${_getGreeting()}, ${userName.isNotEmpty ? userName : 'User'}!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's your financial summary",
                      style: TextStyle(
                        fontSize: 16,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Month Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 28),
                          color: accent,
                          onPressed: _goToPreviousMonth,
                        ),
                        GestureDetector(
                          onTap: () => _showMonthYearPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
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
                              children: [
                                Text(
                                  "${months[currentMonthIndex]} $selectedYear",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 28),
                          color: accent,
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards
                    LayoutBuilder(builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 600;
                      final netSavings = totalIncome - totalSpending;

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
                                cardColor: cardColor,
                                textColor: textColor,
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
                            Expanded(child: _donutChartCard(categoryData, cardColor, textColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _barChartCard(categoryData, cardColor, textColor)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _donutChartCard(categoryData, cardColor, textColor),
                            const SizedBox(height: 16),
                            _barChartCard(categoryData, cardColor, textColor),
                          ],
                        );
                      }
                    }),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    Text(
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
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
                          return Text(
                            "No transactions yet",
                            style: TextStyle(color: subtitleColor, fontSize: 16),
                          );
                        }
                        final transactions = snapshot.data!;
                        return Column(
                          children: transactions.map<Widget>((tx) {
                            final isExpense = tx['amount'] < 0;
                            return _transactionTile(
                              tx['category'] ?? "Unknown",
                              tx['note'] ?? "",
                              "${isExpense ? '' : '+'}${tx['amount']} ฿",
                              isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              isExpense
                                  ? Colors.redAccent
                                  : Colors.green,
                              cardColor,
                              textColor,
                              subtitleColor,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordPage()),
          ).then((_) => _loadSummaryData());
        },
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
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(amount,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _donutChartCard(Map<String, double> categoryData, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor,
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

  Widget _barChartCard(Map<String, double> categoryData, Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "No data yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
    Color subtitleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          )
        ],
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                Text(subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 14)),
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