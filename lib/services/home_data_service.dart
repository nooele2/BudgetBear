import 'package:budget_bear/services/firestore.dart';

class HomeDataService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Get user's display name
  Future<String> getUserName() async {
    final name = await _firestoreService.getUserName();
    return name ?? "User";
  }

  /// Get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  /// Load all summary data for a specific month and year
  Future<Map<String, dynamic>> loadSummaryData(int year, int month) async {
    final summary = await _firestoreService.getSummaryData(year, month);
    final currentBudget = await _firestoreService.getMonthlyBudget(year, month);
    final monthSummary = await _firestoreService.getMonthlyExpenses(year) ?? {};

    // Extract expense categories only (positive values)
    final allCategories = Map<String, double>.from(summary['categories'] ?? {});
    final expenseCategories = Map.fromEntries(
      allCategories.entries
          .where((entry) => entry.value > 0)
          .map((e) => MapEntry(e.key, e.value)),
    );

    // Generate monthly expenses array for all 12 months
    final monthlyExpenses = List.generate(
      12,
      (i) => monthSummary[i + 1]?.abs() ?? 0.0,
    );

    return {
      'totalIncome': summary['income'] ?? 0.0,
      'totalSpending': summary['expense'] ?? 0.0,
      'categoryData': expenseCategories,
      'monthlyBudget': currentBudget,
      'monthlyExpenses': monthlyExpenses,
    };
  }

  /// Update monthly budget
  Future<void> updateBudget(int year, int month, double budget) async {
    await _firestoreService.setMonthlyBudget(year, month, budget);
  }

  /// Calculate net savings
  double calculateNetSavings({
    required double totalIncome,
    required double totalSpending,
    required double monthlyBudget,
  }) {
    return totalIncome - totalSpending;
  }
}