import 'package:flutter/material.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/more_page.dart';
import 'package:budget_bear/pages/notification_page.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';

class AIPage extends StatefulWidget {
  const AIPage({Key? key}) : super(key: key);

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  @override
  Widget build(BuildContext context) {

    const Color accent = Color.fromRGBO(71, 168, 165, 1);
    const Color bgColor = Color(0xFFF5F7FA);
    const Color textColor = Color(0xFF333333);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: const Center(
        child: Text('This is the AI Page'),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}