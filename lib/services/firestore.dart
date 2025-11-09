import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current logged-in user's ID
  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  /// Fetch user's display name from Firestore
  Future<String?> getUserName() async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('name')) {
        return doc['name'];
      } else {
        return null;
      }
    } catch (e) {
      print('FirestoreService.getUserName error: $e');
      return null;
    }
  }

  /// Fetch all transactions for a specific year and month
  Future<List<Map<String, dynamic>>> getTransactions(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final nextMonth = (month < 12)
          ? DateTime(year, month + 1, 1)
          : DateTime(year + 1, 1, 1);

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(nextMonth))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['amount'] is num) {
          data['amount'] = (data['amount'] as num).toDouble();
        }
        return data;
      }).toList();
    } catch (e) {
      print('FirestoreService.getTransactions error: $e');
      return [];
    }
  }

  /// Get monthly summary data (income, expenses, and spending by category)
  Future<Map<String, dynamic>> getSummaryData(int year, int month) async {
    try {
      final transactions = await getTransactions(year, month);
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      final Map<String, double> categories = {};

      for (final tx in transactions) {
        final amount =
            (tx['amount'] is num) ? (tx['amount'] as num).toDouble() : 0.0;
        final type = (tx['type'] ?? '').toString().toLowerCase();
        final category = (tx['category'] ?? 'Other').toString();

        if (type == 'income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
          categories[category] = (categories[category] ?? 0.0) + amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'categories': categories,
      };
    } catch (e) {
      print('FirestoreService.getSummaryData error: $e');
      return {
        'income': 0.0,
        'expense': 0.0,
        'categories': <String, double>{},
      };
    }
  }

  /// Stream of recent transactions (latest 10)
  Stream<List<Map<String, dynamic>>> getRecentTransactionsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              if (data['amount'] is num) {
                data['amount'] = (data['amount'] as num).toDouble();
              }
              return data;
            }).toList());
  }

  /// Helper for adding a transaction (used in testing or record page)
  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required String type, // 'income' or 'expense'
    DateTime? date,
  }) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc();

    await ref.set({
      'title': title,
      'category': category,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  //save monthly budget
  Future<void> setMonthlyBudget(int year, int month, double amount) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc('$year-$month')
        .set({
      'year': year,
      'month': month,
      'budget': amount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  //get monthly budget
  Future<double> getMonthlyBudget(int year, int month) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0.0;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc('$year-$month')
        .get();

    if (doc.exists) {
      return (doc.data()?['budget'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  //get monthly expenses
  Future<Map<int, double>> getMonthlyExpenses(int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final startOfNextYear = DateTime(year + 1, 1, 1);

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('date', isLessThan: Timestamp.fromDate(startOfNextYear))
          .get();

      Map<int, double> monthlyTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final type = (data['type'] ?? '').toString().toLowerCase();

        // only count expenses
        if (type == 'expense') {
          final month = date.month;
          monthlyTotals[month] = (monthlyTotals[month] ?? 0.0) + amount;
        }
      }

      return monthlyTotals;
    } catch (e) {
      print('Error getting monthly expenses: $e');
      return {};
    }
  }
}
