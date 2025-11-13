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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final unselectedColor = isDark ? Colors.grey[400] : Colors.grey;

    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: widget.currentIndex,
            selectedItemColor: accent,
            unselectedItemColor: unselectedColor,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            elevation: 0,
            backgroundColor: backgroundColor,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            iconSize: 26,
            items: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.smart_toy,
                label: 'AI',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.add_circle,
                label: 'Record',
                index: 2,
                isCenter: true,
              ),
              _buildNavItemWithBadge(
                icon: Icons.notifications,
                label: 'Notifications',
                index: 3,
                unreadCount: unreadCount,
              ),
              _buildNavItem(
                icon: Icons.more_horiz,
                label: 'More',
                index: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final isSelected = widget.currentIndex == index;
    const accent = Color.fromRGBO(71, 168, 165, 1);

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: isCenter ? 28 : 24,
        ),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildNavItemWithBadge({
    required IconData icon,
    required String label,
    required int index,
    required int unreadCount,
  }) {
    final isSelected = widget.currentIndex == index;
    const accent = Color.fromRGBO(71, 168, 165, 1);

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 24),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
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
      ),
      label: label,
    );
  }
}