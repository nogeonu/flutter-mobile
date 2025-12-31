import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/medical_record.dart';
import '../services/patient_repository.dart';
import '../state/app_state.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final PatientRepository _repository = PatientRepository();
  final List<_HistoryFilter> _filters = const [
    _HistoryFilter(range: HistoryRange.today, label: '오늘'),
    _HistoryFilter(range: HistoryRange.month1, label: '1개월'),
    _HistoryFilter(range: HistoryRange.month3, label: '3개월'),
    _HistoryFilter(range: HistoryRange.month6, label: '6개월'),
    _HistoryFilter(range: HistoryRange.custom, label: '직접설정'),
  ];

  List<MedicalRecord> _records = const [];
  bool _isLoading = false;
  String? _errorMessage;
  HistoryRange _selectedRange = HistoryRange.month1;
  DateTimeRange? _customRange;
  final Set<int> _expandedRecordIds = {};

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_handleAppStateChanged);
    _loadRecords();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final session = AppState.instance.session;
    if (session == null) {
      setState(() {
        _records = const [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _repository.fetchMedicalRecords(
        session.patientId,
        patientPk: session.patientPk,
      );
      records.sort((a, b) => b.receptionStartTime.compareTo(a.receptionStartTime));
      setState(() {
        _records = records;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _toggleExpansion(int recordId, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedRecordIds.add(recordId);
      } else {
        _expandedRecordIds.remove(recordId);
      }
    });
  }

  List<MedicalRecord> get _filteredRecords {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (_selectedRange) {
      case HistoryRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case HistoryRange.month1:
        start = now.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.month3:
        start = now.subtract(const Duration(days: 90));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.month6:
        start = now.subtract(const Duration(days: 180));
        end = now.add(const Duration(days: 1));
        break;
      case HistoryRange.custom:
        if (_customRange != null) {
          start = DateTime(
            _customRange!.start.year,
            _customRange!.start.month,
            _customRange!.start.day,
          );
          end = _customRange!.end.add(const Duration(days: 1));
        }
        break;
    }

    return _records.where((record) {
      final visitDate = record.receptionStartTime;
      if (start != null && visitDate.isBefore(start)) return false;
      if (end != null && visitDate.isAfter(end)) return false;
      return true;
    }).toList();
  }

  LinkedHashMap<String, List<MedicalRecord>> _groupRecords(
    List<MedicalRecord> records,
  ) {
    final grouped = <String, List<MedicalRecord>>{};
    for (final record in records) {
      final key = DateFormat(
        'yyyy년 M월 d일 (E)',
        'ko_KR',
      ).format(record.receptionStartTime);
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return LinkedHashMap.of(grouped);
  }

  String get _selectedRangeLabel {
    final filter = _filters.firstWhere((f) => f.range == _selectedRange);
    if (_selectedRange == HistoryRange.custom && _customRange != null) {
      final start = DateFormat('M월 d일').format(_customRange!.start);
      final end = DateFormat('M월 d일').format(_customRange!.end);
      return '$start ~ $end';
    }
    return filter.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AppState.instance.session;
    final groupedRecords = _groupRecords(_filteredRecords);

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
            if (session == null)
              Expanded(
                child: _EmptyHistoryState(
                  rangeLabel: _selectedRangeLabel,
                  description: '로그인 후 진료내역을 확인하실 수 있습니다.',
                ),
              )
            else if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadRecords,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (groupedRecords.isEmpty)
              Expanded(
                child: _EmptyHistoryState(rangeLabel: _selectedRangeLabel),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: groupedRecords.length,
                  itemBuilder: (context, index) {
                    final entry = groupedRecords.entries.elementAt(index);
                    return _DateSection(
                      dateLabel: entry.key,
                      records: entry.value,
                      expandedRecordIds: _expandedRecordIds,
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

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.dateLabel,
    required this.records,
    required this.expandedRecordIds,
    required this.onToggle,
  });

  final String dateLabel;
  final List<MedicalRecord> records;
  final Set<int> expandedRecordIds;
  final void Function(int recordId, bool isExpanded) onToggle;

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
              ...records.map(
                (record) => _RecordExpansionTile(
                  record: record,
                  isExpanded: expandedRecordIds.contains(record.id),
                  onToggle: (value) => onToggle(record.id, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordExpansionTile extends StatelessWidget {
  const _RecordExpansionTile({
    required this.record,
    required this.isExpanded,
    required this.onToggle,
  });

  final MedicalRecord record;
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
          key: PageStorageKey(record.id),
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
                  _formatTime(record.receptionStartTime),
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
                      record.patientName.isEmpty
                          ? '환자 정보 없음'
                          : record.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.department} · ${record.statusLabel}',
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
                    '접수 시간: ${record.visitDateLabel}',
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
              icon: Icons.local_hospital_outlined,
              label: '진료과',
              value: record.department.isEmpty ? '진료과 정보 없음' : record.department,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.info_outline,
              label: '진료 상태',
              value: record.statusLabel.isEmpty ? '상태 정보 없음' : record.statusLabel,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time,
              label: '접수 시간',
              value: record.visitDateLabel,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.flag_circle_outlined,
              label: '진료 종료',
              value: record.treatmentEndTimeLabel,
            ),
            const SizedBox(height: 12),
            Text(
              '메모',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 6),
            if (record.noteLines.isEmpty)
              Text(
                '메모가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: record.noteLines
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
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.rangeLabel, this.description});

  final String rangeLabel;
  final String? description;

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
            description ?? '다른 기간을 선택하여 확인해보세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
            textAlign: TextAlign.center,
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

String _formatShortDate(DateTime date) =>
    '${date.year}.${_pad(date.month)}.${_pad(date.day)}';

String _formatTime(DateTime date) => '${_pad(date.hour)}:${_pad(date.minute)}';

String _pad(int value) => value.toString().padLeft(2, '0');
