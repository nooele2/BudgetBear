import 'package:flutter/material.dart';
import 'package:budget_bear/pages/home_page.dart';
import 'package:budget_bear/pages/record_page.dart';
import 'package:budget_bear/pages/more_page.dart';
import 'package:budget_bear/pages/ai_page.dart';
import 'package:budget_bear/pages/notification_page.dart';
import 'package:budget_bear/services/notification_service.dart';

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

    // no animation route
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
    const Color accent = Color.fromRGBO(71, 168, 165, 1);

    return StreamBuilder<int>(
      // listen for unread notification count
      stream: NotificationService().getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return BottomNavigationBar(
          currentIndex: widget.currentIndex,
          selectedItemColor: accent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Record',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        );
      },
    );
  }
}
