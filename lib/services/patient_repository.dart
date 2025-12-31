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

  Future<List<MedicalRecord>> fetchMedicalRecords(
    String patientId, {
    int? patientPk,
  }) async {
    if (patientId.trim().isEmpty && patientPk == null) {
      return const [];
    }

    final query = <String, dynamic>{'patient_id': patientId};
    if (patientPk != null) {
      query['patient'] = patientPk;
      query['patient_pk'] = patientPk;
    }

    final data = await _client.get(
      '/api/lung_cancer/medical-records/',
      query: query,
    );

    String? normalizePatientValue(Object? raw) {
      if (raw == null) return null;
      if (raw is Map) {
        final nested = raw['patient_id'] ?? raw['patientId'] ?? raw['id'] ?? raw['pk'];
        return nested?.toString();
      }
      return raw.toString();
    }

    bool matchesPatient(Map<String, dynamic> item) {
      final raw = item['patient_id'] ??
          item['patient_identifier'] ??
          item['patientId'] ??
          item['patient_pk'] ??
          item['patient'];
      final normalized = normalizePatientValue(raw);
      if (normalized == null) return false;
      if (normalized == patientId) return true;
      if (patientPk != null && normalized == patientPk.toString()) return true;
      return false;
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'] ?? data['medical_records'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .where(matchesPatient)
            .map(MedicalRecord.fromJson)
            .toList();
      }
    } else if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .where(matchesPatient)
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

  /// 회원가입
  Future<Map<String, dynamic>> signup({
    required String accountId,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/patients/signup/',
      body: {
        'account_id': accountId,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException(500, '회원가입에 실패했습니다.');
  }
}
