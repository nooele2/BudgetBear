import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartWidgets {
  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  /// Build donut chart card for category breakdown
  static Widget buildDonutChartCard({
    required Map<String, double> categoryData,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
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
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey,
                        fontSize: 16,
                      ),
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

  /// Build bar chart card for monthly spending trend
  static Widget buildBarChartCard({
    required List<double> monthlyExpenses,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
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
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey,
                        fontSize: 16,
                      ),
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
                              const months = [
                                'J', 'F', 'M', 'A', 'M', 'J',
                                'J', 'A', 'S', 'O', 'N', 'D'
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
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
                              color: accent,
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
}