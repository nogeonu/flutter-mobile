import 'package:intl/intl.dart';

class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.status,
    this.memo,
    this.patientId,
    this.patientName,
    this.patientGender,
    this.patientAge,
    required this.doctorId,
    required this.doctorUsername,
    this.doctorName,
    this.doctorDepartment,
    this.doctorDisplay,
    this.patientDisplay,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final String? memo;
  final String? patientId;
  final String? patientName;
  final String? patientGender;
  final int? patientAge;
  final int doctorId;
  final String doctorUsername;
  final String? doctorName;
  final String? doctorDepartment;
  final String? doctorDisplay;
  final String? patientDisplay;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get startTimeLabel => DateFormat('yyyy년 M월 d일 HH:mm').format(startTime);
  
  String get endTimeLabel => endTime == null
      ? ''
      : DateFormat('yyyy년 M월 d일 HH:mm').format(endTime!);

  String get statusLabel {
    switch (status) {
      case 'scheduled':
        return '예약됨';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return status;
    }
  }

  String get typeLabel {
    switch (type) {
      case '예약':
        return '일반 예약';
      case '검진':
        return '검진';
      case '회의':
        return '회의';
      case '내근':
        return '내근';
      case '외근':
        return '외근';
      default:
        return type;
    }
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawId = json['id'];
    final id = rawId == null
        ? ''
        : (rawId is int ? rawId.toString() : rawId as String);
    final rawStatus = json['status'] as String? ?? 'scheduled';
    final status = rawStatus.toLowerCase();

    return Appointment(
      id: id,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '예약',
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: parseDateTime(json['end_time']),
      status: status.isEmpty ? 'scheduled' : status,
      memo: json['memo'] as String?,
      patientId: json['patient_id'] as String?,
      patientName: json['patient_name'] as String?,
      patientGender: json['patient_gender'] as String?,
      patientAge: json['patient_age'] as int?,
      doctorId: (json['doctor'] is int)
          ? json['doctor'] as int
          : int.tryParse(json['doctor'].toString()) ?? 0,
      doctorUsername: json['doctor_username'] as String? ?? '',
      doctorName: json['doctor_name'] as String?,
      doctorDepartment: json['doctor_department'] as String?,
      doctorDisplay: json['doctor_display'] as String?,
      patientDisplay: json['patient_display'] as String?,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'type': type,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'status': status,
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
      if (patientId != null) 'patient_id': patientId, // Changed from patient_identifier to patient_id
      if (patientName != null) 'patient_name': patientName,
      if (patientGender != null) 'patient_gender': patientGender,
      if (patientAge != null) 'patient_age': patientAge,
      'doctor': doctorId,
    };
  }
}

