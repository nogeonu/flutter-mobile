import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../services/appointment_repository.dart';
import '../theme/app_theme.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  List<Appointment> _appointments = const [];
  bool _isLoadingAppointments = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      // doctor_code로 해당 의사의 예약 정보 가져오기
      final doctorCode = widget.doctor.doctorId;
      if (doctorCode.isNotEmpty) {
        final appointments = await _appointmentRepository.fetchDoctorAppointments(doctorCode);
        if (mounted) {
          setState(() {
            _appointments = appointments;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _appointments = [];
          });
        }
      }
    } catch (error) {
      print('예약 정보 로드 실패: $error');
      if (mounted) {
        setState(() {
          _appointments = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctor = widget.doctor;
    final displayName = doctor.displayName.isEmpty ? '이름 미등록' : doctor.displayName;
    final department = doctor.department.isEmpty
        ? '진료과 미등록'
        : Doctor.labelForDepartment(doctor.department);

    return Scaffold(
      appBar: AppBar(
        title: const Text('의료진 상세'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 담당의사 정보 카드
            _DoctorInfoCard(doctor: doctor, displayName: displayName, department: department),
            const SizedBox(height: 20),

            // 학력/경력 섹션
            _EducationCareerSection(doctor: doctor),
            const SizedBox(height: 20),

            // 진료일정 섹션
            Text(
              '진료일정',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _AppointmentsSection(
              appointments: _appointments,
              isLoading: _isLoadingAppointments,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfoCard extends StatelessWidget {
  const _DoctorInfoCard({
    required this.doctor,
    required this.displayName,
    required this.department,
  });

  final Doctor doctor;
  final String displayName;
  final String department;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            displayName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: '의사 ID',
            value: doctor.doctorId,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.alternate_email,
            label: '이메일',
            value: doctor.email.isEmpty ? '이메일 정보 없음' : doctor.email,
          ),
        ],
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
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1E2432),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EducationCareerSection extends StatelessWidget {
  const _EducationCareerSection({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '학력/경력',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '학력 및 경력 정보는 준비 중입니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          // TODO: 학력/경력 정보를 표시하는 UI 추가
        ],
      ),
    );
  }
}

class _AppointmentsSection extends StatelessWidget {
  const _AppointmentsSection({
    required this.appointments,
    required this.isLoading,
  });

  final List<Appointment> appointments;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (appointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
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
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '예약된 진료일정이 없습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: appointments.map((appointment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AppointmentCard(appointment: appointment),
        );
      }).toList(),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                appointment.startTimeLabel,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          if (appointment.patientName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '환자: ${appointment.patientName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ],
          if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '메모: ${appointment.memo}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

