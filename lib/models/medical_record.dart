import 'package:intl/intl.dart';

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.department,
    required this.status,
    required this.notes,
    required this.receptionStartTime,
    required this.treatmentEndTime,
    required this.isTreatmentCompleted,
  });

  final int id;
  final String patientId;
  final String patientName;
  final String department;
  final String status;
  final String notes;
  final DateTime receptionStartTime;
  final DateTime? treatmentEndTime;
  final bool isTreatmentCompleted;

  DateTime get visitDate => receptionStartTime;

  String get visitDateLabel =>
      DateFormat('yyyy년 M월 d일 HH:mm').format(receptionStartTime);

  String get treatmentEndTimeLabel => treatmentEndTime == null
      ? '진료 예정'
      : DateFormat('yyyy년 M월 d일 HH:mm').format(treatmentEndTime!);

  String get statusLabel => status;

  String get notesLabel => notes.trim().isEmpty ? '메모 없음' : notes.trim();

  List<String> get noteLines {
    if (notes.trim().isEmpty) return const [];
    return notes
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    DateTime? endTime;
    final endTimeValue = json['treatment_end_time'];
    if (endTimeValue is String && endTimeValue.isNotEmpty) {
      endTime = DateTime.tryParse(endTimeValue);
    }

    return MedicalRecord(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      patientId: json['patient_id'] as String? ?? '',
      patientName: json['name'] as String? ?? '',
      department: json['department'] as String? ?? '',
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      receptionStartTime: DateTime.parse(json['reception_start_time'] as String),
      treatmentEndTime: endTime,
      isTreatmentCompleted: json['is_treatment_completed'] as bool? ?? false,
    );
  }
}
