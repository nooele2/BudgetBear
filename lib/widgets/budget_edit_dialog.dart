import 'package:flutter/material.dart';

class BudgetEditDialog {
  static const Color accent = Color.fromRGBO(71, 168, 165, 1);

  /// Show budget edit dialog
  static Future<double?> show({
    required BuildContext context,
    required double currentBudget,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final TextEditingController controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toString() : '',
    );

    return await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Monthly Budget",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "Enter new budget (฿)",
              labelStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newBudget = double.tryParse(controller.text) ?? 0.0;
                Navigator.pop(context, newBudget);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
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
}