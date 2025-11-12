import 'package:flutter/material.dart';

class WaitingQueueScreen extends StatelessWidget {
  const WaitingQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final patients = mockWaitingPatients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('대기 순번'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QueueSummary(accent: accent, patients: patients),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final isNext = index == 0;
                    return _QueueCard(
                      patient: patient,
                      accent: accent,
                      isNext: isNext,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.accent, required this.patients});

  final Color accent;
  final List<WaitingPatient> patients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waitingCount = patients.length;
    final currentPatient = patients.isNotEmpty ? patients.first : null;
    final remaining = waitingCount > 0 ? waitingCount - 1 : 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: currentPatient == null
          ? Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.people_alt_outlined,
                    color: accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 대기 환자 없음',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '잠시 후 다시 확인해주세요.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '1',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 나의 순서',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            currentPatient.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE5E0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '방문 예정',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFCC5F5F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '대기 번호 ${currentPatient.queueNumber.toString().padLeft(3, '0')}번',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '전체 ${waitingCount}명 중 현재 1번째 · 다음까지 ${remaining}명 대기 중',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('새로고침'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.patient,
    required this.accent,
    required this.isNext,
  });

  final WaitingPatient patient;
  final Color accent;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isNext ? accent.withOpacity(0.4) : Colors.transparent,
          width: 1.4,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${patient.queueNumber}번',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient.patientId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '접수 ${_formatTime(patient.receptionTime)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475467),
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: const Text('진료 대기중'),
                      backgroundColor: accent.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 20,
                color: accent.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  patient.department,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2432),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class WaitingPatient {
  const WaitingPatient({
    required this.queueNumber,
    required this.patientId,
    required this.name,
    required this.department,
    required this.receptionTime,
  });

  final int queueNumber;
  final String patientId;
  final String name;
  final String department;
  final TimeOfDay receptionTime;
}

const mockWaitingPatients = <WaitingPatient>[
  WaitingPatient(
    queueNumber: 1,
    patientId: 'P2025002',
    name: '김우선',
    department: '호흡기내과',
    receptionTime: TimeOfDay(hour: 20, minute: 19),
  ),
  WaitingPatient(
    queueNumber: 2,
    patientId: 'P2025009',
    name: '심자윤',
    department: '호흡기내과',
    receptionTime: TimeOfDay(hour: 12, minute: 29),
  ),
  WaitingPatient(
    queueNumber: 3,
    patientId: 'P2025010',
    name: '양의지',
    department: '외과',
    receptionTime: TimeOfDay(hour: 12, minute: 45),
  ),
];
