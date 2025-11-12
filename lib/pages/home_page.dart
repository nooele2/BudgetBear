import 'package:flutter/material.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:budget_bear/services/home_data_service.dart';
import 'package:budget_bear/pages/detail_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/widgets/budget_card.dart';
import 'package:budget_bear/widgets/month_year_picker.dart';
import 'package:budget_bear/widgets/budget_edit_dialog.dart';
import 'package:budget_bear/widgets/chart_widgets.dart';
import 'package:budget_bear/widgets/summary_card_widget.dart';
import 'package:budget_bear/widgets/transaction_tile_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final HomeDataService _homeDataService = HomeDataService();

  int selectedYear = DateTime.now().year;
  int currentMonthIndex = DateTime.now().month - 1;

  double totalSpending = 0.0;
  double totalIncome = 0.0;
  double monthlyBudget = 0.0;
  Map<String, double> categoryData = {};
  List<double> monthlyExpenses = List.filled(12, 0.0);

  bool isLoading = true;
  String userName = '';

  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadSummaryData();
  }

  Future<void> _loadUserName() async {
    final name = await _homeDataService.getUserName();
    setState(() {
      userName = name;
    });
  }

  Future<void> _loadSummaryData() async {
    setState(() => isLoading = true);

    final data = await _homeDataService.loadSummaryData(
      selectedYear,
      currentMonthIndex + 1,
    );

    setState(() {
      totalIncome = data['totalIncome'];
      totalSpending = data['totalSpending'];
      categoryData = data['categoryData'];
      monthlyBudget = data['monthlyBudget'];
      monthlyExpenses = data['monthlyExpenses'];
      isLoading = false;
    });
  }

  Future<void> _showMonthYearPicker() async {
    final result = await MonthYearPicker.show(
      context: context,
      currentYear: selectedYear,
      currentMonth: currentMonthIndex,
    );

    if (result != null) {
      setState(() {
        selectedYear = result['year']!;
        currentMonthIndex = result['month']!;
      });
      _loadSummaryData();
    }
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

  Future<void> _showBudgetEditDialog() async {
    final newBudget = await BudgetEditDialog.show(
      context: context,
      currentBudget: monthlyBudget,
    );

    if (newBudget != null) {
      await _homeDataService.updateBudget(
        selectedYear,
        currentMonthIndex + 1,
        newBudget,
      );
      setState(() {
        monthlyBudget = newBudget;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    // Header with greeting and month selector
                    _buildHeader(textColor),
                    const SizedBox(height: 24),

                    // Budget Card
                    UnifiedBudgetCard(
                      firestoreService: _firestoreService,
                      onBudgetUpdated: _loadSummaryData,
                    ),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 24),

                    // Charts Section
                    _buildChartsSection(
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    _buildRecentTransactionsSection(
                      textColor: textColor,
                      subtextColor: subtextColor,
                      cardColor: cardColor,
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_homeDataService.getGreeting()}, ${userName.isNotEmpty ? userName : 'User'}!",
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
              onTap: _showMonthYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
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
                      "${MonthYearPicker.months[currentMonthIndex].substring(0, 3)} $selectedYear",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    ),
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
    );
  }

  Widget _buildSummaryCards({
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;
        final netSavings = _homeDataService.calculateNetSavings(
          totalIncome: totalIncome,
          totalSpending: totalSpending,
          monthlyBudget: monthlyBudget,
        );

        final cards = [
          SummaryCardWidget(
            title: "Total Spending",
            amount: "฿${totalSpending.toStringAsFixed(2)}",
            icon: Icons.arrow_downward,
            color: Colors.redAccent,
            width: double.infinity,
            height: 130,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          SummaryCardWidget(
            title: "Total Income",
            amount: "฿${totalIncome.toStringAsFixed(2)}",
            icon: Icons.arrow_upward,
            color: Colors.green,
            width: double.infinity,
            height: 130,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          SummaryCardWidget(
            title: "Net Savings",
            amount: "฿${netSavings.toStringAsFixed(2)}",
            icon: Icons.account_balance_wallet,
            color: accent,
            width: double.infinity,
            height: 130,
            cardColor: cardColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          );
        } else {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              const SizedBox(height: 12),
              cards[2],
            ],
          );
        }
      },
    );
  }

  Widget _buildChartsSection({
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;

        final donutChart = ChartWidgets.buildDonutChartCard(
          categoryData: categoryData,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
        );

        final barChart = ChartWidgets.buildBarChartCard(
          monthlyExpenses: monthlyExpenses,
          cardColor: cardColor,
          textColor: textColor,
          isDark: isDark,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: donutChart),
              const SizedBox(width: 16),
              Expanded(child: barChart),
            ],
          );
        } else {
          return Column(
            children: [
              donutChart,
              const SizedBox(height: 16),
              barChart,
            ],
          );
        }
      },
    );
  }

  Widget _buildRecentTransactionsSection({
    required Color textColor,
    required Color subtextColor,
    required Color cardColor,
  }) {
    return Column(
      children: [
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
          stream: _firestoreService.getRecentTransactionsStream(),
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

                return TransactionTile(
                  title: tx['category'] ?? "Unknown",
                  subtitle: tx['title'] ?? tx['note'] ?? "",
                  amount: "${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} ฿",
                  icon: isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  iconColor: isExpense ? Colors.redAccent : Colors.green,
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}