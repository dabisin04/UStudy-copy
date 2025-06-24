import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<String> tabs;

  const TopNavbar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.tabs = const ['Home', 'Resources', 'Homework', 'Profile'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(tabs.length, (index) {
          final isActive = currentIndex == index;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive ? Colors.black : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isActive)
                    Container(height: 2, width: 20, color: Colors.black),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
