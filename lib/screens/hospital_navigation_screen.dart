import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: 'hospital',
        latLng: LatLng(MapConfig.hospitalLatitude, MapConfig.hospitalLongitude),
        infoWindowContent: MapConfig.hospitalName,
        infoWindowRemovable: false,
        markerImageSrc: 'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png', // 빨간색 마커
      ),
    };
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (e) {
      // 위치 가져오기 실패 시 무시 (출발지 없이도 경로 안내 가능)
    }
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
    final encodedDestName = Uri.encodeComponent(MapConfig.hospitalName);
    final encodedOriginName = Uri.encodeComponent('내 위치');
    
    // 사용자 위치가 있으면 출발지 포함, 없으면 도착지만
    String kakaoMapUrl;
    if (_userPosition != null) {
      kakaoMapUrl = 'kakaomap://route?'
          'sp=${_userPosition!.latitude},${_userPosition!.longitude}&sn=$encodedOriginName&'
          'ep=${MapConfig.hospitalLatitude},${MapConfig.hospitalLongitude}&en=$encodedDestName&'
          'by=CAR';
    } else {
      kakaoMapUrl = 'kakaomap://route?'
          'ep=${MapConfig.hospitalLatitude},${MapConfig.hospitalLongitude}&en=$encodedDestName&'
          'by=CAR';
    }
    
    final kakaoMapUri = Uri.parse(kakaoMapUrl);

    if (await canLaunchUrl(kakaoMapUri)) {
      await launchUrl(kakaoMapUri);
      return;
    }

    // 웹 fallback: 도착지만 설정
    final fallbackUri = Uri.parse(
      'https://map.kakao.com/link/to/$encodedDestName,'
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
