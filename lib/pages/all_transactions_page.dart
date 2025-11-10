import 'package:flutter/material.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/more_page.dart';
import 'package:budget_bear/pages/notification_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:budget_bear/services/firestore.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  @override
  Widget build(BuildContext context) {

    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(color: textColor),
        title: const Text(
          'All Transactions',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('This is the transaction Page'),
      ),
    );
  }
}