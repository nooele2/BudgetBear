import 'package:flutter/material.dart';

class MonthYearPicker {
  static const List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  /// Show month and year picker dialog
  static Future<Map<String, int>?> show({
    required BuildContext context,
    required int currentYear,
    required int currentMonth,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int tempYear = currentYear;
    int tempMonth = currentMonth;

    return await showDialog<Map<String, int>>(
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
                    // Year selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
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
                          icon: Icon(
                            Icons.chevron_right,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => setStateDialog(() => tempYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Month grid
                    Expanded(
                      child: GridView.builder(
                        itemCount: months.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.3,
                        ),
                        itemBuilder: (context, index) {
                          final bool selected = index == tempMonth && tempYear == currentYear;
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, {
                                'year': tempYear,
                                'month': index,
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent
                                    : isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                months[index].substring(0, 3),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : isDark
                                          ? Colors.white
                                          : Colors.black87,
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
}