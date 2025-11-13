import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/map_config.dart';
import '../services/kakao_local_service.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Position? _userPosition;
  KakaoPlace? _nearestPharmacy;
  KakaoMapController? _mapController;
  List<Marker> _markers = const [];
  LatLng? _mapCenter;

  @override
  void initState() {
    super.initState();
    _loadNearestPharmacy();
  }

  Future<void> _loadNearestPharmacy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _determinePosition();
      final places = await KakaoLocalService.fetchNearbyPharmacies(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final nearest = places.isNotEmpty ? places.first : null;

      setState(() {
        _userPosition = position;
        _nearestPharmacy = nearest;

        if (nearest != null) {
          final userMarker = Marker(
            markerId: 'user',
            latLng: LatLng(position.latitude, position.longitude),
            infoWindowContent: '현재 위치',
            infoWindowRemovable: false,
          );
          final pharmacyMarker = Marker(
            markerId: 'pharmacy',
            latLng: LatLng(nearest.latitude, nearest.longitude),
            infoWindowContent: nearest.name,
            infoWindowRemovable: false,
          );

          _markers = [userMarker, pharmacyMarker];
          _mapCenter = LatLng(nearest.latitude, nearest.longitude);
        } else {
          _markers = const [];
          _mapCenter = null;
        }
      });

      _syncMap();
    } catch (error) {
      setState(() {
        _errorMessage = error is PermissionDeniedException
            ? '위치 권한이 거부되었습니다. 설정에서 허용 후 다시 시도해주세요.'
            : error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _syncMap() {
    final controller = _mapController;
    if (controller == null || _markers.isEmpty || _mapCenter == null) {
      return;
    }

    controller.clearMarker(markerIds: const []);
    controller.addMarker(markers: _markers);
    controller.setCenter(_mapCenter!);
    controller.setLevel(4);
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 비활성화되어 있습니다. GPS를 켜주세요.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionDeniedException('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('위치 권한이 영구적으로 거부되었습니다.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('약국 안내'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _loadNearestPharmacy);
    }

    if (_userPosition == null) {
      return const _ErrorView(message: '현재 위치를 확인할 수 없습니다.');
    }

    if (_nearestPharmacy == null) {
      return const _ErrorView(message: '주변 약국 정보를 찾지 못했습니다. 조금 후 다시 시도해주세요.');
    }

    final pharmacy = _nearestPharmacy!;
    final center = _mapCenter ?? LatLng(pharmacy.latitude, pharmacy.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: KakaoMap(
              key: ValueKey(
                'pharmacy_${pharmacy.latitude}_${pharmacy.longitude}',
              ),
              center: center,
              currentLevel: 5,
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _syncMap();
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PharmacyDetailCard(
          pharmacy: pharmacy,
          distanceMeters: pharmacy.distanceMeters,
          onRefresh: _loadNearestPharmacy,
          onNavigate: () => _openRouteInKakaoMap(
            originLat: _userPosition!.latitude,
            originLng: _userPosition!.longitude,
            destination: pharmacy,
          ),
        ),
      ],
    );
  }

  Future<void> _openRouteInKakaoMap({
    required double originLat,
    required double originLng,
    required KakaoPlace destination,
  }) async {
    final encodedName = Uri.encodeComponent(destination.name);
    final kakaoUri = Uri.parse(
      'kakaomap://route?sp=$originLat,$originLng&ep=${destination.latitude},'
      '${destination.longitude},$encodedName&by=CAR',
    );

    if (await canLaunchUrl(kakaoUri)) {
      await launchUrl(kakaoUri);
      return;
    }

    final fallbackUri = Uri.parse(
      'https://map.kakao.com/link/to/$encodedName,${destination.latitude},'
      '${destination.longitude}',
    );
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }
}

class _PharmacyDetailCard extends StatelessWidget {
  const _PharmacyDetailCard({
    required this.pharmacy,
    required this.distanceMeters,
    required this.onRefresh,
    required this.onNavigate,
  });

  final KakaoPlace pharmacy;
  final double distanceMeters;
  final VoidCallback onRefresh;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceText = distanceMeters >= 1000
        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${distanceMeters.toStringAsFixed(0)} m';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pharmacy.address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '거리: $distanceText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    if (pharmacy.phone != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '전화번호: ${pharmacy.phone}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '다시 검색',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.local_pharmacy_outlined),
              label: const Text('카카오맵으로 경로 안내'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          if (pharmacy.placeUrl != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(pharmacy.placeUrl!);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('카카오맵 상세 정보 보기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
