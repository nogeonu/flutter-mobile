import '../models/doctor.dart';
import 'api_client.dart';

class DoctorRepository {
  DoctorRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Doctor>> fetchDoctors({String? department}) async {
    final data = await _client.get(
      '/api/auth/doctors/',
      query: department == null || department.isEmpty
          ? null
          : {'department': department},
    );

    if (data is Map<String, dynamic> && data['doctors'] is List) {
      final list = data['doctors'] as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Doctor.fromJson)
          .toList();
    }
    return const [];
  }
}
