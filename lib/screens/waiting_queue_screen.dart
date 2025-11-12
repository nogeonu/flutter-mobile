import 'package:flutter/material.dart';

import '../data/waiting_ticket.dart';

class WaitingQueueScreen extends StatelessWidget {
  const WaitingQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = mockWaitingPatients;

    if (patients.isEmpty) {
      return const _EmptyState();
    }

    WaitingPatient? myPatient;
    for (final patient in patients) {
      if (patient.isMine) {
        myPatient = patient;
        break;
      }
    }
    final aheadCount = myPatient != null ? patients.indexOf(myPatient) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('내 대기 순번'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          if (myPatient != null)
            _WaitingSummary(
              theme: theme,
              myPatient: myPatient,
              aheadCount: aheadCount!,
            )
          else
            _NoWaitingSummary(theme: theme),
          const SizedBox(height: 20),
          _WaitingList(
            theme: theme,
            patients: patients,
            myPatientId: myPatient?.patientId,
          ),
        ],
      ),
    );
  }
}

class _WaitingSummary extends StatelessWidget {
  const _WaitingSummary({
    required this.theme,
    required this.myPatient,
    required this.aheadCount,
  });

  final ThemeData theme;
  final WaitingPatient myPatient;
  final int aheadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 현재 순번',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${myPatient.queueNumber} 번째',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (myPatient.name.isNotEmpty)
            Text(
              '환자명: ${_maskName(myPatient.name)}',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 4),
          Text(
            '내 앞에는 $aheadCount명 대기 중입니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _instructionMessage(myPatient.queueNumber),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingList extends StatelessWidget {
  const _WaitingList({
    required this.theme,
    required this.patients,
    required this.myPatientId,
  });

  final ThemeData theme;
  final List<WaitingPatient> patients;
  final String? myPatientId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text('대기 중인 환자 목록', style: theme.textTheme.titleMedium),
          ),
          const Divider(height: 1),
          for (var i = 0; i < patients.length; i++)
            _WaitingListTile(
              patient: patients[i],
              isMine:
                  myPatientId != null && patients[i].patientId == myPatientId,
              isLast: i == patients.length - 1,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _WaitingListTile extends StatelessWidget {
  const _WaitingListTile({
    required this.patient,
    required this.isMine,
    required this.isLast,
    required this.theme,
  });

  final WaitingPatient patient;
  final bool isMine;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isMine
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.primary.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _QueueBadge(
            number: patient.queueNumber,
            isMine: isMine,
            theme: theme,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _maskName(patient.name),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.patientId} · ${patient.department}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Text(
            patient.formattedTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({
    required this.number,
    required this.isMine,
    required this.theme,
  });

  final int number;
  final bool isMine;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.primary;
    final color = isMine ? baseColor : baseColor.withOpacity(0.4);

    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: Text(
        number.toString(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoWaitingSummary extends StatelessWidget {
  const _NoWaitingSummary({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 대기 중인 순번이 없습니다.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '접수 후 순번이 표시되며, 목록에서 내 정보를 확인할 수 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 대기 순번'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.35),
              ),
              const SizedBox(height: 20),
              Text(
                '현재 대기 중인 환자가 없습니다.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '진료 접수 후 순번이 표시될 예정입니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _maskName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return name;
  if (trimmed.length == 1) return trimmed;
  if (trimmed.length == 2) {
    return '${trimmed[0]}*';
  }
  final start = trimmed[0];
  final end = trimmed[trimmed.length - 1];
  final middle = List.filled(trimmed.length - 2, '*').join();
  return '$start$middle$end';
}

String _instructionMessage(int queueNumber) {
  if (queueNumber <= 1) {
    return '지금 바로 진료실로 입장해주세요.';
  }
  if (queueNumber == 2 || queueNumber == 3) {
    return '진료실 근처에서 대기해주세요.';
  }
  return '잠시만 기다려 주세요.';
}
