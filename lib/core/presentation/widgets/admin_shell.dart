import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({Key? key, required this.navigationShell}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121214),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_rounded), label: 'Action Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Growth'),
          BottomNavigationBarItem(icon: Icon(Icons.bubble_chart_rounded), label: 'Engagement'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Support'),
        ],
      ),
    );
  }
}
