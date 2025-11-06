import 'package:flutter/material.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/more_page.dart';
import 'package:budget_bear/pages/ai_page.dart';
import 'package:budget_bear/pages/notification_page.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const HomePage();
        break;
      case 1:
        nextPage = const AIPage();
        break;
      case 2:
        nextPage = const RecordPage();
        break;
      case 3:
        nextPage = const NotificationPage();
        break;
      case 4:
        nextPage = const MorePage();
        break;
      default:
        return;
    }

    //no animation route
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color.fromRGBO(71, 168, 165, 1);//accent color code

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      selectedItemColor: accent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Record'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}