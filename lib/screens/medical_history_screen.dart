import 'dart:collection';

import 'package:flutter/material.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final List<_Visit> _visits = _mockVisits;
  final List<_HistoryFilter> _filters = const [
    _HistoryFilter(range: HistoryRange.today, label: '오늘'),
    _HistoryFilter(range: HistoryRange.month1, label: '1개월'),
    _HistoryFilter(range: HistoryRange.month3, label: '3개월'),
    _HistoryFilter(range: HistoryRange.month6, label: '6개월'),
    _HistoryFilter(range: HistoryRange.custom, label: '직접설정'),
  ];

  HistoryRange _selectedRange = HistoryRange.month1;
  DateTimeRange? _customRange;
  final Set<String> _expandedVisitIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedVisits = _groupVisits(_filteredVisits);

    return Scaffold(
      appBar: AppBar(
        title: const Text('진료내역 조회'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryFilterBar(
              filters: _filters,
              selectedRange: _selectedRange,
              customRange: _customRange,
              onSelected: _handleFilterSelected,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: groupedVisits.isEmpty
                  ? _EmptyHistoryState(rangeLabel: _selectedRangeLabel)
                  : ListView.builder(
                      itemCount: groupedVisits.length,
                      itemBuilder: (context, index) {
                        final entry = groupedVisits.entries.elementAt(index);
                        return _DateSection(
                          dateLabel: entry.key,
                          visits: entry.value,
                          expandedVisitIds: _expandedVisitIds,
                          onToggle: _toggleExpansion,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFilterSelected(HistoryRange range) async {
    if (range == HistoryRange.custom) {
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange:
            _customRange ??
            DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedRange = range;
          _customRange = picked;
        });
      }
      return;
    }

    setState(() {
      _selectedRange = range;
      _customRange = null;
    });
  }

  void _toggleExpansion(String visitId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        _expandedVisitIds.add(visitId);
      } else {
        _expandedVisitIds.remove(visitId);
      }
    });
  }

  List<_Visit> get _filteredVisits {
    DateTime now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_selectedRange) {
      case HistoryRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case HistoryRange.month1:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.month3:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 90));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.month6:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 180));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.custom:
        if (_customRange != null) {
          start = DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
          );
          end = DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
          ).add(const Duration(days: 1));
        }
        break;
    }

    return _visits.where((visit) {
      final visitDate = visit.dateTime;
      if (start != null && visitDate.isBefore(start)) return false;
      if (end != null && visitDate.isAfter(end)) return false;
      return true;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  LinkedHashMap<String, List<_Visit>> _groupVisits(List<_Visit> visits) {
    final Map<String, List<_Visit>> grouped = {};
    for (final visit in visits) {
      final key = _formatDate(visit.dateTime);
      grouped.putIfAbsent(key, () => []).add(visit);
    }
    return LinkedHashMap.of(grouped);
  }

  String get _selectedRangeLabel {
    final filter = _filters.firstWhere((f) => f.range == _selectedRange);
    if (_selectedRange == HistoryRange.custom && _customRange != null) {
      return '${_formatShortDate(_customRange!.start)} ~ ${_formatShortDate(_customRange!.end)}';
    }
    return filter.label;
  }
}

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.filters,
    required this.selectedRange,
    required this.onSelected,
    required this.customRange,
  });

  final List<_HistoryFilter> filters;
  final HistoryRange selectedRange;
  final DateTimeRange? customRange;
  final ValueChanged<HistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter.range == selectedRange;
          final label =
              filter.range == HistoryRange.custom && customRange != null
              ? '${_formatShortDate(customRange!.start)} ~ ${_formatShortDate(customRange!.end)}'
              : filter.label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(filter.range),
              selectedColor: theme.colorScheme.primary,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF1E2432),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.dateLabel,
    required this.visits,
    required this.expandedVisitIds,
    required this.onToggle,
  });

  final String dateLabel;
  final List<_Visit> visits;
  final Set<String> expandedVisitIds;
  final void Function(String visitId, bool isExpanded) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...visits.map(
                (visit) => _VisitExpansionTile(
                  visit: visit,
                  isExpanded: expandedVisitIds.contains(visit.id),
                  onToggle: (value) => onToggle(visit.id, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitExpansionTile extends StatelessWidget {
  const _VisitExpansionTile({
    required this.visit,
    required this.isExpanded,
    required this.onToggle,
  });

  final _Visit visit;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(visit.id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onToggle,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          trailing: Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: const Color(0xFF475467),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _formatTime(visit.dateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.department,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visit.doctor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    visit.location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475467),
                    ),
                  ),
                ),
              ],
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.info_outline,
              label: '진료 상태',
              value: visit.statusLabel,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.description_outlined,
              label: '진단',
              value: visit.diagnosis,
            ),
            if (visit.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '메모',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467),
                ),
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: visit.notes
                    .map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '· $note',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '$rangeLabel 기간 내 진료내역이 없습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '다른 기간을 선택하여 확인해보세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

enum HistoryRange { today, month1, month3, month6, custom }

class _HistoryFilter {
  const _HistoryFilter({required this.range, required this.label});

  final HistoryRange range;
  final String label;
}

class _Visit {
  const _Visit({
    required this.id,
    required this.dateTime,
    required this.department,
    required this.doctor,
    required this.location,
    required this.diagnosis,
    required this.status,
    this.notes = const [],
  });

  final String id;
  final DateTime dateTime;
  final String department;
  final String doctor;
  final String location;
  final String diagnosis;
  final VisitStatus status;
  final List<String> notes;

  String get statusLabel {
    switch (status) {
      case VisitStatus.completed:
        return '진료 완료';
      case VisitStatus.upcoming:
        return '예약됨';
      case VisitStatus.cancelled:
        return '취소됨';
    }
  }

  Color get statusColor {
    switch (status) {
      case VisitStatus.completed:
        return const Color(0xFF2EAD66);
      case VisitStatus.upcoming:
        return const Color(0xFF2A6FE5);
      case VisitStatus.cancelled:
        return const Color(0xFFCC5F5F);
    }
  }
}

enum VisitStatus { completed, upcoming, cancelled }

final List<_Visit> _mockVisits = [
  _Visit(
    id: 'visit-6',
    dateTime: DateTime.now().add(const Duration(days: 3, hours: 10)),
    department: '외과',
    doctor: 'Dr. 김서연',
    location: '본관 2층 204호',
    diagnosis: '추적 진료 예정',
    status: VisitStatus.upcoming,
    notes: ['10분 전 도착 후 접수', '필요 시 추가 검사 안내 예정'],
  ),
  _Visit(
    id: 'visit-5',
    dateTime: DateTime.now().subtract(const Duration(days: 4, hours: 3)),
    department: '호흡기내과',
    doctor: 'Dr. 최동욱',
    location: '본관 1층 내과 102호',
    diagnosis: '만성 기침',
    status: VisitStatus.completed,
    notes: ['수납 완료', '항히스타민제 10일분 복용', '2주 후 전화 상담 예정'],
  ),
  _Visit(
    id: 'visit-4',
    dateTime: DateTime.now().subtract(const Duration(days: 15, hours: 5)),
    department: '영상의학과',
    doctor: 'Dr. 박지혜',
    location: '영상센터 3층 CT실',
    diagnosis: '흉부 CT 추적 검사',
    status: VisitStatus.completed,
    notes: ['수납 완료', '6개월 후 재검 권장'],
  ),
  _Visit(
    id: 'visit-3',
    dateTime: DateTime.now().subtract(const Duration(days: 34, hours: 2)),
    department: '외과',
    doctor: 'Dr. 김서연',
    location: '본관 2층 204호',
    diagnosis: '복부 통증 상담',
    status: VisitStatus.completed,
    notes: ['수납 완료', '소화제 및 진경제 7일분 처방', '복부 초음파 결과 이상 없음'],
  ),
  _Visit(
    id: 'visit-2',
    dateTime: DateTime.now().subtract(const Duration(days: 80, hours: 1)),
    department: '호흡기내과',
    doctor: 'Dr. 이민지',
    location: '본관 1층 내과 105호',
    diagnosis: '기관지염',
    status: VisitStatus.completed,
    notes: ['수납 완료', '항생제 5일분 처방', '증상 호전됨, 3개월 후 추적 권장'],
  ),
  _Visit(
    id: 'visit-1',
    dateTime: DateTime.now().subtract(const Duration(days: 140, hours: 6)),
    department: '정형외과',
    doctor: 'Dr. 박민수',
    location: '별관 3층 302호',
    diagnosis: '어깨 통증 재활 상담',
    status: VisitStatus.cancelled,
    notes: ['예약 취소', '환자 요청으로 일정 변경'],
  ),
];

String _formatDate(DateTime date) {
  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[date.weekday - 1];
  return '${date.year}-${_pad(date.month)}-${_pad(date.day)} ($weekday)';
}

String _formatShortDate(DateTime date) =>
    '${date.year}.${_pad(date.month)}.${_pad(date.day)}';

String _formatTime(DateTime date) => '${_pad(date.hour)}:${_pad(date.minute)}';

String _pad(int value) => value.toString().padLeft(2, '0');
