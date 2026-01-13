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
      throw ApiException(
        response.statusCode,
        '챗봇 서버 오류: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    print('[ChatRepository] 챗봇 응답: $data');

    if (data is Map<String, dynamic>) {
      return ChatMessage.fromJson(data);
    }

    throw ApiException(500, '챗봇 응답 형식이 올바르지 않습니다.');
  }

  void dispose() {
    _client.close();
  }
}
