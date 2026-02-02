import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

class ChatRepository {
  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  final _uuid = const Uuid();

  /// 챗봇에 메시지 전송
  Future<ChatMessage> sendMessage({
    required String message,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    final requestId = _uuid.v4();
    
    final body = {
      'message': message,
      'session_id': sessionId ?? '',
      'request_id': requestId,
      'metadata': metadata ?? {},
    };

    print('[ChatRepository] 메시지 전송: $message');
    print('[ChatRepository] Session ID: $sessionId');
    print('[ChatRepository] Metadata: $metadata');

    // 챗봇 서버로 직접 요청
    final url = Uri.parse('${ApiConfig.chatbotBaseUrl}/api/chat/');
    print('[ChatRepository] 요청 URL: $url');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('[ChatRepository] 응답 상태: ${response.statusCode}');
    print('[ChatRepository] 응답 본문: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errMsg = '챗봇 서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
      try {
        final errData = jsonDecode(response.body);
        if (errData is Map && errData['error'] != null) {
          errMsg = errData['error'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty && response.body.length < 200) {
          errMsg = response.body;
        }
      }
      throw ApiException(response.statusCode, errMsg);
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw ApiException(500, '챗봇 응답 형식이 올바르지 않습니다.');
    }

    print('[ChatRepository] 챗봇 응답: $data');

    final reply = data['reply'] as String? ?? data['error'] as String?;
    if (reply == null || reply.isEmpty) {
      data = Map<String, dynamic>.from(data);
      data['reply'] = '죄송합니다. 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
    return ChatMessage.fromJson(data);
  }

  /// 예약 가능 시간 조회
  Future<Map<String, dynamic>> getAvailableTimeSlots({
    required String date,
    String? doctorId,
    String? doctorCode,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    final body = {
      'date': date,
      'session_id': sessionId ?? '',
      if (doctorId != null) 'doctor_id': doctorId,
      if (doctorCode != null) 'doctor_code': doctorCode,
      'metadata': metadata ?? {},
    };

    print('[ChatRepository] 예약 가능 시간 조회: date=$date, doctorId=$doctorId, doctorCode=$doctorCode');
    print('[ChatRepository] 요청 본문: ${jsonEncode(body)}');

    final url = Uri.parse('${ApiConfig.chatbotBaseUrl}/api/chat/available-time-slots/');
    print('[ChatRepository] 요청 URL: $url');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException(
            408,
            '예약 가능 시간 조회 시간 초과',
          );
        },
      );

      print('[ChatRepository] 응답 상태: ${response.statusCode}');
      print('[ChatRepository] 응답 본문: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode,
          '예약 가능 시간 조회 실패: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } on http.ClientException catch (e) {
      print('[ChatRepository] 클라이언트 예외: $e');
      rethrow;
    } catch (e) {
      print('[ChatRepository] 예외 발생: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
