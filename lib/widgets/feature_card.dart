import 'package:flutter/material.dart';

import '../data/feature_item.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.feature});

  final FeatureItem feature;

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
              color: theme.colorScheme.primary.withOpacity(0.08),
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
