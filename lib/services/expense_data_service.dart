import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpenseDataService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch expense data for a given date range
  Future<Map<String, dynamic>> fetchExpenseData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    Map<String, double> categories = {};
    List<Map<String, dynamic>> dailyTransactions = [];

    final user = _auth.currentUser;
    if (user == null) {
      return {
        'totalIncome': 0.0,
        'totalExpenses': 0.0,
        'netSavings': 0.0,
        'categories': {},
        'dailyTransactions': [],
      };
    }

    try {
      final querySnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('date', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final type = data['type'] ?? 'expense';
        final category = data['category'] ?? 'Unknown';
        final note = data['note'] ?? '';
        final date = (data['date'] as Timestamp).toDate();

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpenses += amount;
          categories[category] = (categories[category] ?? 0.0) + amount;
        }

        dailyTransactions.add({
          'date': DateFormat('dd MMM yyyy').format(date),
          'category': category,
          'note': note,
          'type': type,
          'amount': amount,
        });
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netSavings': totalIncome - totalExpenses,
        'categories': categories,
        'dailyTransactions': dailyTransactions,
      };
    } catch (e) {
      print('Error fetching expense data: $e');
      return {
        'totalIncome': 0.0,
        'totalExpenses': 0.0,
        'netSavings': 0.0,
        'categories': {},
        'dailyTransactions': [],
      };
    }
  }

  /// Get summary statistics for current month
  Future<Map<String, double>> getCurrentMonthSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final data = await fetchExpenseData(startOfMonth, endOfMonth);

    return {
      'totalIncome': data['totalIncome'],
      'totalExpenses': data['totalExpenses'],
      'netSavings': data['netSavings'],
    };
  }

  /// Get category breakdown for a date range
  Future<Map<String, double>> getCategoryBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await fetchExpenseData(startDate, endDate);
    return data['categories'] as Map<String, double>;
  }
}