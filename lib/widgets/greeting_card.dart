import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.instance;
    final session = appState.session;
    final isLoggedIn = session != null;

    // 로그인 상태에 따라 인사말 변경
    final greeting = isLoggedIn 
        ? '${session.name}님 안녕하세요!' 
        : '안녕하세요!';
    
    final message = isLoggedIn
        ? '병원 이용 시 편리한 서비스를 제공합니다.'
        : '로그인 후 이용 시 편리한 서비스를 제공합니다.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
