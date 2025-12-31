import '../services/chat_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.sources,
    this.table,
  });

  final String text;
  final bool isUser;
  final List<ChatSource>? sources;
  final ChatTable? table;

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'is_user': isUser,
      if (sources != null)
        'sources': sources!.map((source) => source.toMap()).toList(),
      if (table != null) 'table': table!.toMap(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final sourcesRaw = map['sources'];
    List<ChatSource>? sources;
    if (sourcesRaw is List) {
      sources = sourcesRaw
          .whereType<Map<String, dynamic>>()
          .map(ChatSource.fromMap)
          .toList();
    }
    ChatTable? table;
    final tableRaw = map['table'];
    if (tableRaw is Map<String, dynamic>) {
      table = ChatTable.fromMap(tableRaw);
    }
    return ChatMessage(
      text: map['text'] as String? ?? '',
      isUser: map['is_user'] as bool? ?? false,
      sources: sources,
      table: table,
    );
  }
}
