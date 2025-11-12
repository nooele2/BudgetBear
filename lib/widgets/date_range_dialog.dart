import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeDialog {
  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  /// Show date range picker dialog
  static Future<Map<String, DateTime>?> show({
    required BuildContext context,
    bool isForEmail = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? startDate;
    DateTime? endDate;

    return await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isForEmail ? 'Select Date Range for Email' : 'Select Date Range',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Date
                  _buildDateTile(
                    context: context,
                    isDark: isDark,
                    label: 'From',
                    date: startDate,
                    placeholder: 'Select start date',
                    onTap: () async {
                      final picked = await _showDatePicker(
                        context: context,
                        isDark: isDark,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // End Date
                  _buildDateTile(
                    context: context,
                    isDark: isDark,
                    label: 'To',
                    date: endDate,
                    placeholder: 'Select end date',
                    onTap: () async {
                      final picked = await _showDatePicker(
                        context: context,
                        isDark: isDark,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: startDate != null && endDate != null
                      ? () {
                          Navigator.pop(context, {
                            'start': startDate!,
                            'end': endDate!,
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isForEmail ? 'Send Email' : 'Download'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build individual date tile
  static Widget _buildDateTile({
    required BuildContext context,
    required bool isDark,
    required String label,
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
      subtitle: Text(
        date != null ? DateFormat('MMM dd, yyyy').format(date) : placeholder,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.calendar_today, color: accent),
      onTap: onTap,
    );
  }

  /// Show date picker with theme
  static Future<DateTime?> _showDatePicker({
    required BuildContext context,
    required bool isDark,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: accent,
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(primary: accent),
          ),
          child: child!,
        );
      },
    );
  }
}