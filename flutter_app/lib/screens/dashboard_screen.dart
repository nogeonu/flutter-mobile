import 'package:flutter/material.dart';

import '../data/feature_item.dart';
import '../state/app_state.dart';
import '../widgets/feature_card.dart';
import '../widgets/greeting_card.dart';
import 'doctor_search_screen.dart';
import 'hospital_map_screen.dart';
import 'medical_history_screen.dart';
import 'parking_screen.dart';
import 'pharmacy_screen.dart';
import 'reservation_screen.dart';
import 'waiting_queue_screen.dart';
import 'hospital_navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
          Text('CDSSentials', style: theme.textTheme.headlineMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.15),
                      theme.colorScheme.primary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '병원 안내',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                return FeatureCard(
                  feature: feature,
                  onTap: () => _handleFeatureTap(context, feature),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleFeatureTap(BuildContext context, FeatureItem feature) {
    switch (feature.id) {
      case 'department_staff':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DoctorSearchScreen()));
        break;
      case 'hospital_map':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HospitalMapScreen()));
        break;
      case 'hospital_navigation':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HospitalNavigationScreen()),
        );
        break;
      case 'reservation':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReservationScreen()));
        break;
      case 'parking':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ParkingScreen()));
        break;
      case 'pharmacy':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PharmacyScreen()),
        );
        break;
      case 'exam_history':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MedicalHistoryScreen()));
        break;
      case 'waiting_queue':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WaitingQueueScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${feature.title} 기능은 준비 중입니다.',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
