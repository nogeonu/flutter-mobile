import 'package:flutter/material.dart';

void main() {
  runApp(const HospitalNaviApp());
}

class HospitalNaviApp extends StatelessWidget {
  const HospitalNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CDSSentials',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2253A5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2432),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2432),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5C6672),
          ),
        ),
      ),
      home: const _MainShell(),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({super.key});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _DashboardPage(),
    _PlaceholderPage(title: '나의 검사', description: '검사 결과와 진행 상황을 확인하세요.'),
    _PlaceholderPage(title: '건강 알림', description: '맞춤 알림과 공지 사항을 받아보세요.'),
    _PlaceholderPage(title: '로그인', description: '로그인 기능이 곧 제공될 예정입니다.'),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
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

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  static final List<_FeatureItem> _features = [
    _FeatureItem(
      title: '진료과 · 의료진',
      description: '전문의 정보 확인',
      icon: Icons.medical_services_outlined,
    ),
    _FeatureItem(
      title: '진료내역',
      description: '지난 진료 기록 조회',
      icon: Icons.receipt_long_outlined,
    ),
    _FeatureItem(
      title: '진료예약',
      description: '예약 화면 준비 중',
      icon: Icons.calendar_today_outlined,
    ),
    _FeatureItem(
      title: '대기순번',
      description: '현재 순번 확인',
      icon: Icons.timer_outlined,
    ),
    _FeatureItem(
      title: '약국 안내',
      description: '내원 환자 전용 약국',
      icon: Icons.local_pharmacy_outlined,
    ),
    _FeatureItem(
      title: '주차장',
      description: '실시간 주차 정보',
      icon: Icons.local_parking_outlined,
    ),
    _FeatureItem(
      title: '병원 지도',
      description: '실시간 위치 확인',
      icon: Icons.map_outlined,
    ),
    _FeatureItem(
      title: '병원 길 찾기',
      description: '내비게이션 경로 안내',
      icon: Icons.directions_walk_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('CDSSentials', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 18),
          const _GreetingCard(),
          const SizedBox(height: 24),
          Text('주요 기능', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: _features.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final feature = _features[index];
                return _FeatureCard(feature: feature);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요!',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text('병원 이용 시 편리한 서비스를 제공합니다.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _FeatureItem feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              feature.icon,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const Spacer(),
          Text(feature.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(feature.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(description, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Center(
            child: Icon(
              Icons.devices_other_outlined,
              color: theme.colorScheme.primary.withOpacity(0.2),
              size: 120,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
