import 'package:flutter/material.dart';

import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'exam_screen.dart';
import 'login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static final _pages = [
    const DashboardScreen(),
    const ExamScreen(),
    const AlertsScreen(),
    const LoginScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '메인화면'),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_ind_outlined),
      label: '나의검사',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event_note_outlined),
      label: '건강알림',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '로그인'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: const Color(0xFF9AA4B2),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
      ),
    );
  }
}
