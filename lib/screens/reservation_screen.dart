import 'package:flutter/material.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _departments = const ['호흡기내과', '외과'];

  final _doctorsByDepartment = const {
    '호흡기내과': ['김현우 교수', '이수민 교수'],
    '외과': ['박지훈 교수', '최유진 교수'],
  };

  final _timeSlots = const [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
  ];

  String? _selectedDepartment;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final selectedDoctors = _doctorsByDepartment[_selectedDepartment] ?? [];
    final displayDate = _selectedDate == null
        ? '예약 날짜를 선택하세요'
        : '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일 (${_weekdayLabel(_selectedDate!)})';

    return Scaffold(
      appBar: AppBar(
        title: const Text('진료 예약'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '예약 정보 입력',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormCard(
                context: context,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: _inputDecoration('진료과'),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        items: _departments
                            .map(
                              (dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _selectedDoctor = null;
                          });
                        },
                        validator: (value) =>
                            value == null ? '진료과를 선택하세요' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDoctor,
                        decoration: _inputDecoration('담당 의료진'),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        items: selectedDoctors
                            .map(
                              (doctor) => DropdownMenuItem(
                                value: doctor,
                                child: Text(doctor),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDoctor = value);
                        },
                        validator: (value) =>
                            value == null ? '담당 의료진을 선택하세요' : null,
                        disabledHint: const Text('진료과를 먼저 선택하세요'),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _handleDatePick,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _inputDecoration('예약 날짜').copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                            ),
                            controller: TextEditingController(
                              text: displayDate,
                            ),
                            validator: (_) =>
                                _selectedDate == null ? '예약 날짜를 선택하세요' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('예약 시간', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((slot) {
                          final selected = _selectedTimeSlot == slot;
                          return ChoiceChip(
                            label: Text(slot),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedTimeSlot = slot);
                            },
                            selectedColor: accent,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF1E2432),
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: const Color(0xFFF1F5FB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: selected
                                    ? accent
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedTimeSlot == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '예약 시간을 선택하세요',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('예약 요약', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildFormCard(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('진료과', _selectedDepartment ?? '-'),
                    const SizedBox(height: 10),
                    _buildSummaryRow('의료진', _selectedDoctor ?? '-'),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      '예약 날짜',
                      _selectedDate == null ? '-' : displayDate,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow('예약 시간', _selectedTimeSlot ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('예약 요청하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFormCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E2432)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDatePick() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _handleSubmit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약 정보를 모두 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final summary =
        '''${_selectedDepartment ?? ''} / ${_selectedDoctor ?? ''}\n'''
        '''${_selectedDate!.year}.${_selectedDate!.month}.${_selectedDate!.day} ${_selectedTimeSlot!}''';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('예약 요청 완료'),
          content: Text(
            '아직 시스템과 연동되지 않아 실제 예약은 진행되지 않습니다.\n\n입력 정보:\n$summary',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }
}
