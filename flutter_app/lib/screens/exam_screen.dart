import 'package:flutter/material.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나의 검사', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('검사 결과와 진행 상황을 확인하세요.', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Center(
            child: Icon(
              Icons.assignment_ind_outlined,
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
