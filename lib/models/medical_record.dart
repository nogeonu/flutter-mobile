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
    String? readNestedValue(Object? raw, List<String> keys) {
      if (raw is! Map) return null;
      for (final key in keys) {
        final value = raw[key];
        if (value != null) return value.toString();
      }
      return null;
    }

    final patientRaw = json['patient'];
    final patientId = (json['patient_id'] ??
            json['patient_identifier'] ??
            json['patientId'] ??
            json['patient_pk'] ??
            readNestedValue(patientRaw, ['patient_id', 'patientId', 'id', 'pk']))
        ?.toString() ??
        '';
    final patientName = (json['name'] ??
            json['patient_name'] ??
            readNestedValue(patientRaw, ['name', 'patient_name']))
        ?.toString() ??
        '';

    return MedicalRecord(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      patientId: patientId,
      patientName: patientName,
      department: json['department'] as String? ?? '',
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      receptionStartTime: DateTime.parse(json['reception_start_time'] as String),
      treatmentEndTime: endTime,
      isTreatmentCompleted: json['is_treatment_completed'] as bool? ?? false,
    );
  }
}
