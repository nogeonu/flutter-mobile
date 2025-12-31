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
      title: map['title'] as String? ?? '\uCD9C\uCC98',
      snippet: map['snippet'] as String? ?? '',
      url: map['url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'snippet': snippet,
      if (url != null) 'url': url,
    };
  }
}

class ChatTable {
  const ChatTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  factory ChatTable.fromMap(Map<String, dynamic> map) {
    final rawHeaders = map['headers'];
    final headers = rawHeaders is List
        ? rawHeaders.map((item) => item.toString()).toList()
        : const <String>[];
    final rows = <List<String>>[];
    final rawRows = map['rows'];
    if (rawRows is List) {
      for (final row in rawRows) {
        if (row is List) {
          rows.add(row.map((item) => item.toString()).toList());
        }
      }
    }
    return ChatTable(headers: headers, rows: rows);
  }

  Map<String, dynamic> toMap() {
    return {
      'headers': headers,
      'rows': rows,
    };
  }
}

class ChatReply {
  const ChatReply({required this.message, this.sources = const [], this.table});

  final String message;
  final List<ChatSource> sources;
  final ChatTable? table;
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

    final bodyMap = {
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
      if (metadata != null) 'metadata': metadata,
    };

    print('[ChatService] Request URL: $uri');
    print('[ChatService] Request body: ${jsonEncode(bodyMap)}');

    try {
      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      print('[ChatService] Status: ${response.statusCode}');
      print('[ChatService] Body: ${response.body}');

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
          ChatTable? table;
          final rawTable = data['table'];
          if (rawTable is Map<String, dynamic>) {
            table = ChatTable.fromMap(rawTable);
          }
          return ChatReply(message: reply, sources: sources, table: table);
        }
        throw ApiException(500, '\uC751\uB2F5 \uD615\uC2DD\uC774 \uC62C\uBC14\uB974\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4.');
      }

      final text = response.body.isEmpty ? '{}' : response.body;
      final dynamic errorData = jsonDecode(text);
      final messageText = errorData is Map<String, dynamic>
          ? errorData['error'] ??
              errorData['detail'] ??
              '\uC694\uCCAD\uC774 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4.'
          : '\uC694\uCCAD\uC774 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4.';

      throw ApiException(response.statusCode, messageText.toString());
    } catch (e, st) {
      print('[ChatService] EXCEPTION: $e');
      print('[ChatService] STACK: $st');
      rethrow;
    }
  }

  void close() => _client.close();
}
