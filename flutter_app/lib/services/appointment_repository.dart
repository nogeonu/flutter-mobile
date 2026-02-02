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

  /// 내 예약 목록 조회 (환자 ID로)
  /// - 먼저 my_appointments/ 시도, 실패 시 appointments/?patient_id= 로 폴백
  Future<List<Appointment>> fetchMyAppointments(String patientId) async {
    final query = {'patient_id': patientId};

    // 1) 문서 기준: patient_id별 목록은 my_appointments/ 에서 제공할 수 있음
    try {
      final data = await _client.get(
        '/api/patients/appointments/my_appointments/',
        query: query,
      );
      final list = _parseAppointmentList(data);
      if (list.isNotEmpty) return list;
    } catch (_) {
      // 404 등이면 아래 기본 엔드포인트로 폴백
    }

    // 2) 기본: /api/patients/appointments/?patient_id=XXX
    final data = await _client.get(
      '/api/patients/appointments/',
      query: query,
    );
    return _parseAppointmentList(data);
  }

  static List<Appointment> _parseAppointmentList(dynamic data) {
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
    return _parseAppointmentList(data);
  }

  /// 예약 취소
  Future<void> cancelAppointment(String appointmentId) async {
    await _client.put(
      '/api/patients/appointments/$appointmentId/',
      body: {'status': 'cancelled'},
    );
  }
}

