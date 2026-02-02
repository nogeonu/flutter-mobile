import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/patient_profile.dart';
import '../models/patient_session.dart';
import '../services/appointment_repository.dart';
import '../services/patient_repository.dart';
import '../state/app_state.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key, this.session});

  final PatientSession? session;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AppointmentRepository();
  final _patientRepository = PatientRepository();

  final _timeSlots = const [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
  ];

  List<Doctor> _allDoctors = [];
  List<String> _departments = [];
  String? _selectedDepartment;
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  PatientSession? _session;
  PatientProfile? _patientProfile;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? AppState.instance.session;
    _loadDoctors();
    if (_session != null) {
      _loadPatientProfile();
    }
  }

  Future<void> _loadPatientProfile() async {
    if (_session == null) return;
    
    try {
      print('[예약] 환자 프로필 로딩: ${_session!.accountId}');
      final profile = await _patientRepository.fetchProfile(_session!.accountId);
      if (mounted) {
        setState(() {
          _patientProfile = profile;
        });
        print('[예약] 환자 프로필 로드 완료: ${profile.name}, 성별: ${profile.gender}, 나이: ${profile.age}');
      }
    } catch (e) {
      print('[예약] 환자 프로필 로드 실패: $e');
      // 프로필 로드 실패해도 예약은 가능하도록 계속 진행
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      print('[예약] 의사 목록 로딩 시작...');
      final doctors = await _repository.fetchDoctors();
      print('[예약] 의사 ${doctors.length}명 로드됨');
      
      if (doctors.isEmpty) {
        print('[예약] 경고: 의사 데이터가 없습니다');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('등록된 의료진이 없습니다. 관리자에게 문의하세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      // 진료 예약에서 선택 가능한 진료과: 외과, 호흡기내과만 표시 (검사실, admin 등 제외)
      const allowedDepartments = {'외과', '호흡기내과'};
      final depts = doctors
          .map((d) => d.department)
          .where((d) => d.isNotEmpty && allowedDepartments.contains(d))
          .toSet()
          .toList();
      depts.sort();
      print('[예약] 진료과 ${depts.length}개: $depts');
      
      setState(() {
        _allDoctors = doctors;
        _departments = depts;
      });
    } catch (e, stackTrace) {
      print('[예약] 오류 발생: $e');
      print('[예약] 스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('의료진 정보를 불러오지 못했습니다: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Doctor> get _filteredDoctors {
    if (_selectedDepartment == null) return [];
    return _allDoctors
        .where((d) => d.department == _selectedDepartment)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final displayDate = _selectedDate == null
        ? '예약 날짜를 선택하세요'
        : '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일 (${_weekdayLabel(_selectedDate!)})';

    // 로그인하지 않은 경우 로그인 유도 화면 표시
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('진료 예약'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.textTheme.headlineMedium?.color,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: accent.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  '로그인이 필요합니다',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '진료 예약은 로그인 후 이용 가능합니다.\n\n회원가입 후 로그인하시면\n편리하게 진료 예약을 하실 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 로그인 페이지로 이동 (MainShell의 3번째 탭으로)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      '로그인하러 가기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('뒤로 가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('진료 예약'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.textTheme.headlineMedium?.color,
          elevation: 0,
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                      DropdownButtonFormField<Doctor>(
                        value: _selectedDoctor,
                        decoration: _inputDecoration('담당 의료진'),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        items: _filteredDoctors
                            .map(
                              (doctor) => DropdownMenuItem(
                                value: doctor,
                                child: Text(doctor.displayName),
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
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.6,
                        children: _timeSlots.map((slot) {
                          final selected = _selectedTimeSlot == slot;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedTimeSlot = slot);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: selected ? accent : const Color(0xFFF1F5FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? accent
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                slot,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1E2432),
                                  fontWeight: FontWeight.w600,
                                ),
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
                    _buildSummaryRow('의료진', _selectedDoctor?.displayName ?? '-'),
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

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedTimeSlot == null || _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약 정보를 모두 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 로그인 세션 확인
    String? patientId;
    String? patientName;
    
    if (_session != null && _session!.patientId.isNotEmpty) {
      // 로그인한 경우 환자 정보 사용
      patientId = _session!.patientId;
      patientName = _session!.name;
      print('[예약] 로그인한 사용자: $patientName ($patientId)');
    } else {
      print('[예약] 로그인하지 않은 사용자');
    }

    setState(() => _isLoading = true);

    try {
      // 시간 조합
      final timeParts = _selectedTimeSlot!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      final endTime = startTime.add(const Duration(minutes: 30));

      // 환자 정보 (프로필에서 가져오기)
      String? patientGender;
      int? patientAge;
      if (_patientProfile != null) {
        patientGender = _patientProfile!.gender;
        patientAge = _patientProfile!.age;
        print('[예약 생성] 환자 프로필 정보: 성별=$patientGender, 나이=$patientAge');
      }

      print('[예약 생성] patientId: $patientId, patientName: $patientName, doctor: ${_selectedDoctor!.id}');

      // 예약 생성
      await _repository.createAppointment(
        title: '${_selectedDepartment ?? ''} 진료 예약',
        type: '예약',
        startTime: startTime,
        endTime: endTime,
        memo: '',
        patientId: patientId,
        patientName: patientName,
        patientGender: patientGender,
        patientAge: patientAge,
        doctorId: _selectedDoctor!.id,
      );

      if (!mounted) return;

      // 성공 다이얼로그
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('예약 완료'),
          content: Text(
            '예약이 성공적으로 등록되었습니다.\n\n'
            '진료과: ${_selectedDepartment ?? ''}\n'
            '의료진: ${_selectedDoctor?.displayName ?? ''}\n'
            '일시: ${_selectedDate!.year}.${_selectedDate!.month}.${_selectedDate!.day} ${_selectedTimeSlot!}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (mounted) {
        // 예약 화면 닫고 대시보드로 복귀
        // AppState를 업데이트해서 LoginScreen이 자동으로 새로고침되도록 함
        if (_session != null) {
          AppState.instance.updateSession(_session);
        }
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('예약 중 오류가 발생했습니다: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[date.weekday - 1];
  }
}
