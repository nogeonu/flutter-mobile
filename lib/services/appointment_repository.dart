import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import 'api_client.dart';

class AppointmentRepository {
  AppointmentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// 의사 목록 조회
  Future<List<Doctor>> fetchDoctors() async {
    final data = await _client.get('/api/auth/doctors/');
    
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Doctor.fromJson)
          .toList();
    }
    
    if (data is Map<String, dynamic>) {
      // Django API는 'doctors' 또는 'results' 키로 응답
      final doctors = data['doctors'] ?? data['results'];
      if (doctors is List) {
        return doctors
            .whereType<Map<String, dynamic>>()
            .map(Doctor.fromJson)
            .toList();
      }
    }
    
    return const [];
  }

  /// 예약 생성
  Future<Appointment> createAppointment({
    required String title,
    required String type,
    required DateTime startTime,
    DateTime? endTime,
    String? memo,
    String? patientId,
    String? patientName,
    String? patientGender,
    int? patientAge,
    required int doctorId,
  }) async {
    final appointment = Appointment(
      id: '', // 서버에서 생성됨
      title: title,
      type: type,
      startTime: startTime,
      endTime: endTime,
      status: 'scheduled',
      memo: memo,
      patientId: patientId,
      patientName: patientName,
      patientGender: patientGender,
      patientAge: patientAge,
      doctorId: doctorId,
      doctorUsername: '',
    );

    final json = appointment.toCreateJson();
    print('[AppointmentRepository] 예약 생성 요청: $json');

    final data = await _client.post(
      '/api/patients/appointments/',
      body: json,
    );

    print('[AppointmentRepository] 예약 생성 응답: $data');

    if (data is Map<String, dynamic>) {
      return Appointment.fromJson(data);
    }
    
    throw ApiException(500, '예약 생성에 실패했습니다.');
  }

  /// 내 예약 목록 조회 (환자 ID로). 챗봇 서버(병원 DB)에서 조회하여 마이페이지 "다가오는 일정"에 표시.
  Future<List<Appointment>> fetchMyAppointments(String patientId) async {
    final patientIdTrim = patientId.trim();
    if (patientIdTrim.isEmpty) return const [];

    // 챗봇 서버(8001)의 예약 API 사용 (병원 DB patients_appointment와 동기화된 데이터)
    final url = Uri.parse(
      '${ApiConfig.chatbotBaseUrl}/api/chat/appointments/?patient_id=$patientIdTrim',
    );
    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        return _fetchMyAppointmentsFromMainApi(patientId);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => Appointment.fromJson(e))
            .toList();
      }
      return const [];
    } catch (_) {
      return _fetchMyAppointmentsFromMainApi(patientId);
    }
  }

  /// 메인 백엔드(기본 baseUrl)에서 예약 목록 조회 (챗봇 API 실패 시 폴백)
  Future<List<Appointment>> _fetchMyAppointmentsFromMainApi(String patientId) async {
    final data = await _client.get(
      '/api/patients/appointments/',
      query: {'patient_id': patientId},
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Appointment.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(Appointment.fromJson)
            .toList();
      }
    }
    return const [];
  }

  /// 의사별 예약 목록 조회 (doctor_code로)
  Future<List<Appointment>> fetchDoctorAppointments(String doctorCode) async {
    final data = await _client.get(
      '/api/patients/appointments/',
      query: {'doctor_code': doctorCode},
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Appointment.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(Appointment.fromJson)
            .toList();
      }
    }

    return const [];
  }

  /// 예약 취소
  Future<void> cancelAppointment(String appointmentId) async {
    await _client.put(
      '/api/patients/appointments/$appointmentId/',
      body: {'status': 'cancelled'},
    );
  }
}

