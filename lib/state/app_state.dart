import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/patient_session.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  static const String _chatHistoryKeyPrefix = 'chat_history:';
  static const String _anonymousChatKey = 'anonymous';

  PatientSession? _session;
  final Map<String, List<ChatMessage>> _chatHistory = {};
  final Map<String, String> _chatSessionIds = {};

  PatientSession? get session => _session;

  bool get isLoggedIn => _session != null;

  void updateSession(PatientSession? session) {
    final previous = _session;
    _session = session;
    if (previous != null) {
      final sameUser = session != null && _isSameSession(previous, session);
      if (!sameUser) {
        clearChatHistory(
          _buildChatSessionKey(previous.accountId, previous.patientId),
        );
      }
    }
    notifyListeners();
  }

  String getOrCreateChatSessionId(String key) {
    final existing = _chatSessionIds[key];
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
    _chatSessionIds[key] = created;
    return created;
  }

  List<ChatMessage> getChatHistory(String key) {
    if (_isAnonymousKey(key)) {
      return const [];
    }
    return List<ChatMessage>.from(_chatHistory[key] ?? const []);
  }

  Future<List<ChatMessage>> loadChatHistory(String key) async {
    if (_isAnonymousKey(key)) {
      _chatHistory.remove(key);
      _chatSessionIds.remove(key);
      await _removeChatHistory(key);
      return const [];
    }
    final cached = _chatHistory[key];
    if (cached != null && cached.isNotEmpty) {
      return List<ChatMessage>.from(cached);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_chatHistoryKeyPrefix$key');
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final messages = decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromMap)
          .toList();
      if (messages.isNotEmpty) {
        _chatHistory[key] = List<ChatMessage>.from(messages);
      }
      return messages;
    } catch (_) {
      return const [];
    }
  }

  void setChatHistory(String key, List<ChatMessage> messages) {
    if (_isAnonymousKey(key)) {
      return;
    }
    _chatHistory[key] = List<ChatMessage>.from(messages);
    unawaited(_persistChatHistory(key));
  }

  void clearChatHistory(String key) {
    _chatHistory.remove(key);
    _chatSessionIds.remove(key);
    unawaited(_removeChatHistory(key));
  }

  Future<void> _persistChatHistory(String key) async {
    if (_isAnonymousKey(key)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final messages = _chatHistory[key] ?? const [];
    final encoded = jsonEncode(messages.map((message) => message.toMap()).toList());
    await prefs.setString('$_chatHistoryKeyPrefix$key', encoded);
  }

  Future<void> _removeChatHistory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatHistoryKeyPrefix$key');
  }

  bool _isAnonymousKey(String key) => key == _anonymousChatKey;

  bool _isSameSession(PatientSession first, PatientSession second) {
    return first.accountId == second.accountId &&
        first.patientId == second.patientId;
  }

  String _buildChatSessionKey(String? accountId, String? patientId) {
    final account = (accountId ?? '').trim();
    if (account.isNotEmpty) {
      return 'account:$account';
    }
    final patient = (patientId ?? '').trim();
    if (patient.isNotEmpty) {
      return 'patient:$patient';
    }
    return _anonymousChatKey;
  }
}
