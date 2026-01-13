import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppState.instance.session;
    final isLoggedIn = session != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Text(
                '건강 알림',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLoggedIn
                    ? '${session.name}님의 건강 정보를 확인하세요.'
                    : '로그인 후 맞춤 알림을 받아보세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              if (!isLoggedIn)
                _EmptyStateCard(
                  icon: Icons.notifications_none,
                  title: '로그인이 필요합니다',
                  subtitle: '로그인 후 건강 알림을 받아보세요.',
                  theme: theme,
                )
              else ...[
                // 예약 알림
                _SectionTitle(title: '예약 알림', theme: theme),
                const SizedBox(height: 12),
                _AlertCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: theme.colorScheme.primary,
                  title: '다가오는 진료 예약',
                  subtitle: '2025년 11월 22일 10:00\n호흡기내과 - 호 흡과',
                  time: '1일 전',
                  onTap: () {
                    // 예약 상세로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('예약 상세 화면으로 이동')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 검사 결과 알림
                _SectionTitle(title: '검사 결과', theme: theme),
                const SizedBox(height: 12),
                _AlertCard(
                  icon: Icons.assignment_outlined,
                  iconColor: theme.colorScheme.primary,
                  title: '새로운 검사 결과',
                  subtitle: '폐기능 검사 결과가 도착했습니다.',
                  time: '2시간 전',
                  isNew: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('검사 결과 확인')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 복약 알림
                _SectionTitle(title: '복약 알림', theme: theme),
                const SizedBox(height: 12),
                _AlertCard(
                  icon: Icons.medication_outlined,
                  iconColor: theme.colorScheme.primary,
                  title: '약 복용 시간',
                  subtitle: '오전 복용약 (해열제, 소염제)',
                  time: '30분 전',
                  isNew: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('복약 정보 확인')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 병원 공지사항
                _SectionTitle(title: '병원 공지', theme: theme),
                const SizedBox(height: 12),
                _AlertCard(
                  icon: Icons.campaign_outlined,
                  iconColor: theme.colorScheme.primary,
                  title: '독감 예방접종 안내',
                  subtitle: '2025년 독감 예방접종을 시작합니다.',
                  time: '1일 전',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공지사항 상세')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _AlertCard(
                  icon: Icons.info_outline,
                  iconColor: theme.colorScheme.primary,
                  title: '병원 운영 시간 변경 안내',
                  subtitle: '토요일 진료 시간이 변경되었습니다.',
                  time: '3일 전',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공지사항 상세')),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.theme,
  });

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isNew = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 화살표
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
