import 'package:flutter/material.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _mockParkingStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주차장 안내'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ParkingStatusCard(status: status),
            const SizedBox(height: 16),
            _ParkingZoneStatusCard(zones: status.zones),
            const SizedBox(height: 16),
            _ParkingFeeCard(fee: status.fee),
            const SizedBox(height: 16),
            _ParkingLocationCard(location: status.location),
            const SizedBox(height: 16),
            _ParkingNoticeCard(notices: status.notices),
            const SizedBox(height: 12),
            Text(
              '데이터 기준: ${status.referenceTime}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF98A2B3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingStatusCard extends StatelessWidget {
  const _ParkingStatusCard({required this.status});

  final ParkingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occupancy = status.occupancyRate;

    return _InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_parking_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text('주차장 현황', style: theme.textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatusBadge(
                  color: const Color(0xFFE9F7EF),
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF2EAD66),
                  label: '주차 가능',
                  value: '${status.availableLots}대',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusBadge(
                  color: const Color(0xFFE8F1FF),
                  icon: Icons.directions_car,
                  iconColor: const Color(0xFF2A6FE5),
                  label: '전체 주차면',
                  value: '${status.totalLots}대',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('혼잡도', style: theme.textTheme.bodyMedium),
              Text(
                '${(occupancy * 100).round()}%',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 10,
              color: const Color(0xFFFF9F1C),
              backgroundColor: const Color(0xFFEFF1F5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat(
                icon: Icons.accessible,
                label: '장애인 주차',
                value: '${status.disabledLots}면',
              ),
              _QuickStat(
                icon: Icons.ev_station_outlined,
                label: '전기차 충전',
                value: '${status.evChargers}대',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParkingZoneStatusCard extends StatelessWidget {
  const _ParkingZoneStatusCard({required this.zones});

  final List<ParkingZone> zones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('층별 주차 현황', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Column(
            children: zones.map((zone) {
              final ratio = zone.usedLots / zone.totalLots;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            zone.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${zone.usedLots} / ${zone.totalLots}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        color: const Color(0xFFFF9F1C),
                        backgroundColor: const Color(0xFFEFF1F5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ParkingFeeCard extends StatelessWidget {
  const _ParkingFeeCard({required this.fee});

  final ParkingFee fee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('주차 요금', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          _FeeRow(label: '30분당', value: fee.per30Minutes),
          const SizedBox(height: 6),
          _FeeRow(label: '1일 최대', value: fee.maxDaily),
          const SizedBox(height: 14),
          ...fee.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· $note', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkingLocationCard extends StatelessWidget {
  const _ParkingLocationCard({required this.location});

  final ParkingLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('주차장 위치', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Text(location.level, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          ...location.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· $detail', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParkingNoticeCard extends StatelessWidget {
  const _ParkingNoticeCard({required this.notices});

  final List<String> notices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _InfoContainer(
      color: const Color(0xFFE8F1FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('안내사항', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...notices.map(
            (notice) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('· $notice', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF475467)),
        const SizedBox(height: 6),
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoContainer extends StatelessWidget {
  const _InfoContainer({required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

final ParkingStatus _mockParkingStatus = ParkingStatus(
  availableLots: 127,
  totalLots: 500,
  disabledLots: 20,
  evChargers: 8,
  zones: const [
    ParkingZone(name: 'B1층 A구역', usedLots: 45, totalLots: 150),
    ParkingZone(name: 'B1층 B구역', usedLots: 32, totalLots: 150),
    ParkingZone(name: '지상 1층', usedLots: 180, totalLots: 200),
  ],
  fee: const ParkingFee(
    per30Minutes: '2,000원',
    maxDaily: '20,000원',
    notes: ['진료 환자는 2시간 무료 (주차권 발급)', '입원 환자 보호자는 50% 할인', '장애인, 국가유공자는 무료'],
  ),
  location: const ParkingLocation(
    level: '지하 1층 / 지상 1층',
    details: ['A구역: 정문 진입 후 왼쪽', 'B구역: 정문 진입 후 오른쪽', '전기차 충전소는 지하 1층 A구역에 위치'],
  ),
  notices: const [
    '주차권은 1층 안내데스크에서 발급받으실 수 있습니다',
    '정산은 무인정산기 또는 출차 시 가능합니다',
    '혼잡 시간대(오전 9~11시)는 대중교통 이용을 권장합니다',
    '주차공간 부족 시 인근 공영주차장을 이용해주세요',
  ],
  referenceTime: '2025-11-12 11:00 기준',
);

class ParkingStatus {
  const ParkingStatus({
    required this.availableLots,
    required this.totalLots,
    required this.disabledLots,
    required this.evChargers,
    required this.zones,
    required this.fee,
    required this.location,
    required this.notices,
    required this.referenceTime,
  });

  final int availableLots;
  final int totalLots;
  final int disabledLots;
  final int evChargers;
  final List<ParkingZone> zones;
  final ParkingFee fee;
  final ParkingLocation location;
  final List<String> notices;
  final String referenceTime;

  double get occupancyRate =>
      (totalLots - availableLots) / totalLots.clamp(1, totalLots);
}

class ParkingZone {
  const ParkingZone({
    required this.name,
    required this.usedLots,
    required this.totalLots,
  });

  final String name;
  final int usedLots;
  final int totalLots;
}

class ParkingFee {
  const ParkingFee({
    required this.per30Minutes,
    required this.maxDaily,
    required this.notes,
  });

  final String per30Minutes;
  final String maxDaily;
  final List<String> notes;
}

class ParkingLocation {
  const ParkingLocation({required this.level, required this.details});

  final String level;
  final List<String> details;
}
