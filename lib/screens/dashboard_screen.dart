import 'package:flutter/material.dart';

import '../data/feature_item.dart';
import '../widgets/feature_card.dart';
import '../widgets/greeting_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
          const GreetingCard(),
          const SizedBox(height: 24),
          Text('주요 기능', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: featureItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final feature = featureItems[index];
                return FeatureCard(feature: feature);
              },
            ),
          ),
        ],
      ),
    );
  }
}
