import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/map_config.dart';

class HospitalNavigationScreen extends StatefulWidget {
  const HospitalNavigationScreen({super.key});

  @override
  State<HospitalNavigationScreen> createState() =>
      _HospitalNavigationScreenState();
}

class _HospitalNavigationScreenState extends State<HospitalNavigationScreen> {
  KakaoMapController? _mapController;
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: 'hospital',
        latLng: LatLng(MapConfig.hospitalLatitude, MapConfig.hospitalLongitude),
        infoWindowContent: MapConfig.hospitalName,
        infoWindowRemovable: false,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('병원 길 찾기'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: KakaoMap(
                  center: LatLng(
                    MapConfig.hospitalLatitude,
                    MapConfig.hospitalLongitude,
                  ),
                  currentLevel: 4,
                  markers: _markers.toList(),
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DestinationCard(
              onRefresh: _resetCameraPosition,
              onLaunchNavigation: _openKakaoNavigation,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _resetCameraPosition() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.setCenter(
      LatLng(MapConfig.hospitalLatitude, MapConfig.hospitalLongitude),
    );
    controller.setLevel(4);
  }

  Future<void> _openKakaoNavigation() async {
    final encodedName = Uri.encodeComponent(MapConfig.hospitalName);
    final kakaoMapUri = Uri.parse(
      'kakaomap://route?ep=${MapConfig.hospitalLatitude},'
      '${MapConfig.hospitalLongitude},$encodedName&by=CAR',
    );

    if (await canLaunchUrl(kakaoMapUri)) {
      await launchUrl(kakaoMapUri);
      return;
    }

    final fallbackUri = Uri.parse(
      'https://map.kakao.com/link/to/$encodedName,'
      '${MapConfig.hospitalLatitude},${MapConfig.hospitalLongitude}',
    );
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.onRefresh,
    required this.onLaunchNavigation,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLaunchNavigation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2962FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MapConfig.hospitalName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      MapConfig.hospitalAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '지도 초기화',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLaunchNavigation,
              icon: const Icon(Icons.directions_car_filled_outlined),
              label: const Text('카카오맵으로 길 찾기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '카카오맵 또는 카카오내비 앱이 설치되어 있으면 앱으로 이동합니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
            ),
          ),
        ],
      ),
    );
  }
}
