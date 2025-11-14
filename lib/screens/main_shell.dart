import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'alerts_screen.dart';
import 'customer_center_screen.dart';
import 'dashboard_screen.dart';
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
    const AlertsScreen(),
    const CustomerCenterScreen(),
    const LoginScreen(),
  ];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_handleAppStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (mounted) {
      setState(() {}); // Rebuild to update nav bar label
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AppState.instance.session != null;
    
    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: '메인화면',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event_note_outlined),
        label: '건강알림',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.help_outline),
        label: '고객센터',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        label: isLoggedIn ? 'MY' : '로그인',
      ),
    ];

    return Scaffold(
      body: SafeArea(bottom: false, child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: navItems,
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
