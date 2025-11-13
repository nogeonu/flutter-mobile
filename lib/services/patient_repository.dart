import '../models/medical_record.dart';
import '../models/patient_profile.dart';
import '../models/patient_session.dart';
import 'api_client.dart';

class PatientRepository {
  PatientRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PatientSession> login({required String accountId, required String password}) async {
    final response = await _client.post(
      '/api/patients/login/',
      body: {
        'account_id': accountId,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final patientId = response['patient_id'] as String?;
    if (patientId == null) {
      throw ApiException(500, '환자 ID를 찾을 수 없습니다.');
    }

    int? patientPk;
    try {
      patientPk = await _fetchPatientPk(patientId);
    } catch (_) {
      patientPk = null;
    }

    return PatientSession(
      accountId: response['account_id'] as String? ?? accountId,
      patientId: patientId,
      name: response['name'] as String? ?? '',
      email: response['email'] as String? ?? '',
      phone: response['phone'] as String? ?? '',
      patientPk: patientPk,
    );
  }

  Future<int?> _fetchPatientPk(String patientId) async {
    final data = await _client.get('/api/patients/patients/', query: {'search': patientId});
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List && results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        final pk = first['id'];
        if (pk is int) {
          return pk;
        }
      }
    }
    return null;
  }

  Future<List<MedicalRecord>> fetchMedicalRecords(String patientId) async {
    final data = await _client.get(
      '/api/lung_cancer/patients/$patientId/medical_records/',
    );

    if (data is Map<String, dynamic> && data['medical_records'] is List) {
      final items = data['medical_records'] as List<dynamic>;
      return items
          .whereType<Map<String, dynamic>>()
          .map(MedicalRecord.fromJson)
          .toList();
    } else if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MedicalRecord.fromJson)
          .toList();
    }
    return const [];
  }

  Future<PatientProfile> fetchProfile(String accountId) async {
    final data = await _client.get('/api/patients/profile/$accountId/');
    if (data is Map<String, dynamic>) {
      return PatientProfile.fromJson(data);
    }
    throw ApiException(500, '환자 정보를 불러오지 못했습니다.');
  }

  Future<PatientProfile> updateProfile({
    required String accountId,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _client.put(
      '/api/patients/profile/$accountId/',
      body: payload,
    );

    if (data is Map<String, dynamic>) {
      return PatientProfile.fromJson(data);
    }
    throw ApiException(500, '환자 정보 수정에 실패했습니다.');
  }
}
