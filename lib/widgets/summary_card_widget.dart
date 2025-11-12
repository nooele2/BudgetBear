import 'package:flutter/material.dart';

class SummaryCardWidget extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final double width;
  final double height;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const SummaryCardWidget({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.width,
    required this.height,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardColor == Colors.white
            ? [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: subtextColor),
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}