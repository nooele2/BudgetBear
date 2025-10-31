import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:budget_bear/services/firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:budget_bear/pages/record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final List<String> months = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  int currentMonthIndex = DateTime.now().month - 1;
  OverlayEntry? _overlayEntry;

  // Create dropdown popup near month selector
  void _showMonthPopup(BuildContext context, Offset position) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + 40,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: months.asMap().entries.map((entry) {
                  final index = entry.key;
                  final month = entry.value;
                  final bool selected = index == currentMonthIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentMonthIndex = index;
                      });
                      _removeMonthPopup();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color.fromRGBO(71, 168, 165, 1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeMonthPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMonthPopup(BuildContext context, GlobalKey key) {
    if (_overlayEntry != null) {
      _removeMonthPopup();
      return;
    }
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    _showMonthPopup(context, position);
  }

  void _goToPreviousMonth() {
    setState(() {
      currentMonthIndex =
          (currentMonthIndex - 1 + months.length) % months.length;
    });
  }

  void _goToNextMonth() {
    setState(() {
      currentMonthIndex = (currentMonthIndex + 1) % months.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);

    final GlobalKey monthKey = GlobalKey();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              const Text(
                "Hello, Alex!",
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
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Month Selector (with popup)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: accent,
                    onPressed: _goToPreviousMonth,
                  ),
                  GestureDetector(
                    key: monthKey,
                    onTap: () => _toggleMonthPopup(context, monthKey),
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
                            months[currentMonthIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
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

              // ✅ Responsive Summary Cards Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    // --- 3 columns (Web/Desktop) ---
                    return Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            title: "Total Spending",
                            amount: "\$1,250.75",
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
                            amount: "\$3,500.00",
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
                            amount: "\$2,249.25",
                            icon: Icons.account_balance_wallet,
                            color: accent,
                            width: double.infinity,
                            height: 130,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // --- 3 rows (Mobile) ---
                    return Column(
                      children: [
                        _summaryCard(
                          title: "Total Spending",
                          amount: "\$1,250.75",
                          icon: Icons.arrow_downward,
                          color: Colors.redAccent,
                          width: double.infinity,
                          height: 130,
                        ),
                        const SizedBox(height: 12),
                        _summaryCard(
                          title: "Total Income",
                          amount: "\$3,500.00",
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                          width: double.infinity,
                          height: 130,
                        ),
                        const SizedBox(height: 12),
                        _summaryCard(
                          title: "Net Savings",
                          amount: "\$2,249.25",
                          icon: Icons.account_balance_wallet,
                          color: accent,
                          width: double.infinity,
                          height: 130,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // ✅ Responsive Charts Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    // --- 2 Columns (Web/Desktop) ---
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _donutChartCard(accent)),
                        const SizedBox(width: 16),
                        Expanded(child: _barChartCard(accent)),
                      ],
                    );
                  } else {
                    // --- 2 Rows (Mobile) ---
                    return Column(
                      children: [
                        _donutChartCard(accent),
                        const SizedBox(height: 16),
                        _barChartCard(accent),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Spending Alert
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You're close to exceeding your weekly food budget!",
                        style: TextStyle(color: accent, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              const Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              _transactionTile(
                "Groceries",
                "Walmart",
                "-\$120.00",
                Icons.shopping_cart,
                Colors.redAccent,
              ),
              _transactionTile(
                "Salary",
                "Company XYZ",
                "+\$3,500.00",
                Icons.attach_money,
                Colors.green,
              ),
              _transactionTile(
                "Utilities",
                "Electric Bill",
                "-\$85.50",
                Icons.flash_on,
                Colors.orangeAccent,
              ),
              _transactionTile(
                "Restaurant",
                "Pizza Place",
                "-\$45.00",
                Icons.restaurant,
                accent,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecordPage()),
          );
        },
        backgroundColor: accent,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // --- Helper Widgets ---
  Widget _buildTab(String label, bool selected, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? accent : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 5)]
            : [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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
          Text(
            amount,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _donutChartCard(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Breakdown",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      color: accent, value: 40, title: 'Food', radius: 40),
                  PieChartSectionData(
                      color: Colors.orange, value: 25, title: 'Bills', radius: 40),
                  PieChartSectionData(
                      color: Colors.blueAccent,
                      value: 20,
                      title: 'Shopping',
                      radius: 40),
                  PieChartSectionData(
                      color: Colors.purpleAccent,
                      value: 15,
                      title: 'Other',
                      radius: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChartCard(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spending Trend",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: [
                  _barGroup(0, 8),
                  _barGroup(1, 5),
                  _barGroup(2, 9),
                  _barGroup(3, 6),
                  _barGroup(4, 10),
                  _barGroup(5, 7),
                  _barGroup(6, 4),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[v.toInt()]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color.fromRGBO(71, 168, 165, 1),
          width: 14,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _transactionTile(
    String title,
    String subtitle,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
