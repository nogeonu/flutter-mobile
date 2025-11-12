import 'package:flutter/material.dart';

class WaitingPatient {
  const WaitingPatient({
    required this.queueNumber,
    required this.patientId,
    required this.name,
    required this.department,
    required this.receptionTime,
    this.isMine = false,
  });

  final int queueNumber;
  final String patientId;
  final String name;
  final String department;
  final TimeOfDay receptionTime;
  final bool isMine;

  String get formattedTime =>
      '${receptionTime.hour.toString().padLeft(2, '0')}:${receptionTime.minute.toString().padLeft(2, '0')}';
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
