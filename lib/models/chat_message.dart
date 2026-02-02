class ChatMessage {
  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.table,
    this.buttons,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? buttons;
    if (json['buttons'] != null) {
      buttons = (json['buttons'] as List<dynamic>)
          .map((b) => b as Map<String, dynamic>)
          .toList();
    }
    
    // table에 reschedule_mode 포함
    Map<String, dynamic>? table = json['table'] as Map<String, dynamic>?;
    if (table != null && json['reschedule_mode'] == true) {
      table = Map<String, dynamic>.from(table);
      table['reschedule_mode'] = true;
    }
    
    return ChatMessage(
      id: json['request_id'] as String? ?? '',
      message: json['reply'] as String? ?? json['error'] as String? ?? '',
      isUser: false,
      timestamp: DateTime.now(),
      sources: json['sources'] as List<dynamic>?,
      table: table,
      buttons: buttons,
    );
  }

  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic>? sources;
  final Map<String, dynamic>? table;
  final List<Map<String, dynamic>>? buttons;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sources': sources,
      'table': table,
      'buttons': buttons,
    };
  }
}
