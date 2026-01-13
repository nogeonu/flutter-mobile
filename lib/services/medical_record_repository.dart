import '../models/medical_record.dart';
import 'api_client.dart';

class MedicalRecordRepository {
  MedicalRecordRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<MedicalRecord>> fetchWaitingRecords() async {
    final data = await _client.get(
      '/api/lung_cancer/medical-records/waiting_patients/',
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MedicalRecord.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'] ?? data['medical_records'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(MedicalRecord.fromJson)
            .toList();
      }
    }

    return const [];
  }
}


