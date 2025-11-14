import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_client.dart';

class ChatSource {
  const ChatSource({required this.title, required this.snippet, this.url});

  final String title;
  final String snippet;
  final String? url;

  factory ChatSource.fromMap(Map<String, dynamic> map) {
    return ChatSource(
      title: map['title'] as String? ?? '출처',
      snippet: map['snippet'] as String? ?? '',
      url: map['url'] as String?,
    );
  }
}

class ChatReply {
  const ChatReply({required this.message, this.sources = const []});

  final String message;
  final List<ChatSource> sources;
}

class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ChatReply> requestReply(
    String message, {
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    final uri = ApiConfig.buildChatUri('/api/chat/');
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        if (metadata != null) 'metadata': metadata,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['reply'];
      if (reply is String) {
        final List<dynamic>? rawSources = data['sources'] as List<dynamic>?;
        final sources = rawSources == null
            ? const <ChatSource>[]
            : rawSources
                  .whereType<Map<String, dynamic>>()
                  .map(ChatSource.fromMap)
                  .toList();
        return ChatReply(message: reply, sources: sources);
      }
      throw ApiException(500, '잘못된 응답 형식입니다.');
    }

    final text = response.body.isEmpty ? '{}' : response.body;
    final dynamic errorData = jsonDecode(text);
    final messageText = errorData is Map<String, dynamic>
        ? errorData['error'] ?? errorData['detail'] ?? '요청이 실패했습니다.'
        : '요청이 실패했습니다.';

    throw ApiException(response.statusCode, messageText.toString());
  }

  void close() => _client.close();
}
