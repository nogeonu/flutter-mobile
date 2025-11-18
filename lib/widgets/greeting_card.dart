import 'package:flutter/material.dart';
import '../state/app_state.dart';

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
            greeting,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
