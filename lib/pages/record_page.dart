import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:budget_bear/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:budget_bear/firebase_options.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final List<Map<String, dynamic>> _records = [
    // placeholder data
    {'title': 'Salary', 'amount': 5000, 'type': 'Income', 'note': 'Monthly salary'},
    {'title': 'Groceries', 'amount': 150, 'type': 'Expense', 'note': 'Weekly groceries'},
  ];

  void _addRecord() {
    // placeholder function
    setState(() {
      _records.add({'title': '', 'amount': 0, 'type': '', 'note': ''});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Expense'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return ListTile(
            leading: Icon(
              record['type'] == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
              color: record['type'] == 'Income' ? Colors.green : Colors.red,
            ),
            title: Text(record['title']),
            subtitle: Text(record['type']),
            trailing: Text(
              '${record['amount']}฿',
              style: TextStyle(
                color: record['type'] == 'Income' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }
}