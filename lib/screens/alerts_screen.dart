import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('건강 알림', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('맞춤 알림과 공지 사항을 받아보세요.', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Center(
            child: Icon(
              Icons.event_note_outlined,
              size: 120,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
