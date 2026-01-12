import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../state/app_state.dart';

class ChatModal extends StatefulWidget {
  const ChatModal({super.key});

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final List<ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  late final String _chatSessionKey;
  late final String _chatSessionId;
  final Set<String> _expandedRowKeys = {};
  String? _pendingReservationDepartment;
  String? _selectedDoctorKey;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final session = AppState.instance.session;
    final chatKey = _buildChatSessionKey(session?.accountId, session?.patientId);
    if (session == null) {
      AppState.instance.clearChatHistory(chatKey);
    }
    _chatSessionKey = chatKey;
    _chatSessionId = AppState.instance.getOrCreateChatSessionId(_chatSessionKey);
    final cachedMessages = AppState.instance.getChatHistory(_chatSessionKey);
    _messages.addAll(cachedMessages);
    final hadMemoryCache = _messages.isNotEmpty;
    if (!hadMemoryCache) {
      _messages.add(
        const ChatMessage(
          text:
              '\uC548\uB155\uD558\uC138\uC694! \uAC74\uC591\uB300\uD559\uAD50\uBCD1\uC6D0 \uCC57\uBD07\uC785\uB2C8\uB2E4. \uBB34\uC5C7\uC744 \uB3C4\uC640\uB4DC\uB9B4\uAE4C\uC694?',
          isUser: false,
        ),
      );
    }
    _loadPersistedMessages(hadMemoryCache);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _chatService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'AI \uC0C1\uB2F4',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final alignment = message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final bubbleColor = message.isUser
                        ? theme.colorScheme.primary
                        : const Color(0xFFF4F6FA);
                    final textColor = message.isUser
                        ? Colors.white
                        : Colors.black87;
                    final borderRadius = BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: message.isUser
                          ? const Radius.circular(22)
                          : const Radius.circular(6),
                      bottomRight: message.isUser
                          ? const Radius.circular(6)
                          : const Radius.circular(22),
                    );

                    final parsedTable =
                        message.table ?? _extractTableFromText(message.text);
                    final enableDoctorSelection = !message.isUser &&
                        parsedTable != null &&
                        _isDoctorSelectionPrompt(message.text);
                    final displayText = parsedTable == null
                        ? message.text
                        : _summarizeMessage(message.text);
                    return Align(
                      alignment: alignment,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: borderRadius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayText,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                            if (parsedTable != null) ...[
                              const SizedBox(height: 8),
                              _buildTableCards(
                                parsedTable,
                                theme,
                                enableDoctorSelection: enableDoctorSelection,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: const InputDecoration(
                          hintText:
                              '\uAD81\uAE08\uD55C \uC810\uC744 \uC785\uB825\uD558\uC138\uC694.',
                          filled: true,
                          fillColor: Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _handleSend,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: _isSending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: theme.colorScheme.onPrimary,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summarizeMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    final lines = trimmed
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (final line in lines) {
      if (!line.contains('|')) {
        return line;
      }
    }
    return '\uB0B4\uC5ED\uC744 \uC815\uB9AC\uD574 \uB4DC\uB9B4\uAC8C\uC694.';
  }

  ChatTable? _extractTableFromText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;

    const headerKeywords = [
      '\uB0A0\uC9DC',
      '\uC2DC\uAC04',
      '\uACFC',
      '\uC0C1\uD0DC',
    ];

    int headerIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.contains('|')) continue;
      if (headerKeywords.any(line.contains)) {
        headerIndex = i;
        break;
      }
    }
    if (headerIndex == -1) return null;

    List<String> splitRow(String line) {
      return line
          .split('|')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
    }

    final headers = splitRow(lines[headerIndex]);
    if (headers.length < 2) return null;

    final rows = <List<String>>[];
    for (var i = headerIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      if (!line.contains('|')) continue;
      final row = splitRow(line);
      if (row.length >= 2) {
        rows.add(row);
      }
    }

    if (rows.isEmpty) return null;
    return ChatTable(headers: headers, rows: rows);
  }

  Widget _buildTableCards(
    ChatTable table,
    ThemeData theme, {
    bool enableDoctorSelection = false,
  }) {
    if (table.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isDoctorTable(table)) {
      return _buildDoctorCards(table, theme, enableSelection: enableDoctorSelection);
    }

    final headerMap = <String, int>{};
    for (var i = 0; i < table.headers.length; i++) {
      headerMap[table.headers[i].trim()] = i;
    }
    int pickIndex(List<String> candidates, int fallback) {
      for (final key in candidates) {
        final index = headerMap[key];
        if (index != null) return index;
      }
      return fallback;
    }

    const dateKey = '\uB0A0\uC9DC';
    const timeKey = '\uC2DC\uAC04';
    const deptKey = '\uACFC';
    const deptAltKey = '\uC9C4\uB8CC\uACFC';
    const doctorKey = '\uC758\uB8CC\uC9C4';
    const doctorAltKey = '\uC758\uC0AC';
    const doctorAltKey2 = '\uB2F4\uB2F9\uC758';
    const statusKey = '\uC0C1\uD0DC';
    final dateIndex = pickIndex([dateKey], 0);
    final timeIndex = pickIndex([timeKey], 1);
    final deptIndex = pickIndex([deptKey, deptAltKey], 2);
    final doctorIndex = pickIndex([doctorKey, doctorAltKey, doctorAltKey2], -1);
    final hasStatusKey = headerMap.containsKey(statusKey);
    final statusIndex = hasStatusKey ? pickIndex([statusKey], 3) : -1;
    final memoIndex = _findMemoIndex(table);

    String readCell(List<String> row, int index) {
      if (index < 0 || index >= row.length) return '-';
      final value = row[index].trim();
      return value.isEmpty ? '-' : value;
    }

    final cards = <Widget>[];
    for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
      final row = table.rows[rowIndex];
      final date = readCell(row, dateIndex);
      final time = readCell(row, timeIndex);
      final department = readCell(row, deptIndex);
      final doctor = doctorIndex >= 0 ? readCell(row, doctorIndex) : '';
      final status = hasStatusKey ? readCell(row, statusIndex) : '';
      final showStatus = hasStatusKey && status.trim().isNotEmpty && status != '-';
      final showDoctor =
          doctorIndex >= 0 && doctor.trim().isNotEmpty && doctor != '-';
      final memo = memoIndex >= 0 ? readCell(row, memoIndex) : '';
      final memoText = memo == '-' ? '' : memo;
      final canExpand = memoIndex >= 0;
      final rowKey = _buildRowKey(date, time, department, rowIndex);
      final isExpanded = _expandedRowKeys.contains(rowKey);

      cards.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canExpand ? () => _toggleRowExpansion(rowKey) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$date \u00B7 $time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          department,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (showStatus) _buildStatusChip(status, theme),
                      if (canExpand) ...[
                        const SizedBox(width: 6),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ],
                  ),
                  if (showDoctor) ...[
                    const SizedBox(height: 4),
                    Text(
                      doctor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (canExpand)
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 8),
                            Text(
                              '\uC99D\uC0C1/\uBA54\uBAA8',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              memoText.isNotEmpty
                                  ? memoText
                                  : '등록된 내용이 없습니다.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  bool _isDoctorTable(ChatTable table) {
    final headers =
        table.headers.map((header) => header.trim()).toList(growable: false);
    final isReservationLike =
        headers.contains('날짜') && headers.contains('시간');
    if (isReservationLike) return false;
    return headers.contains('이름') ||
        headers.contains('직책') ||
        headers.contains('연락처');
  }

  bool _isDoctorSelectionPrompt(String text) {
    final compact = text.replaceAll(' ', '');
    return compact.contains('의료진을선택') ||
        compact.contains('의사를선택') ||
        compact.contains('의료진선택');
  }

  String? _extractDepartmentFromPrompt(String text) {
    final match = RegExp(r'([가-힣]{2,10})\s*의료진').firstMatch(text);
    return match?.group(1);
  }

  Map<String, String?> _splitDoctorDisplay(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(.+?)\s*\(([^)]+)\)$').firstMatch(trimmed);
    if (match != null) {
      final base = match.group(1)?.trim() ?? trimmed;
      final suffix = match.group(2)?.trim() ?? '';
      final code = (suffix.isEmpty ||
              suffix == '의료진' ||
              RegExp(r'^\\d+$').hasMatch(suffix))
          ? null
          : suffix;
      return {'name': base.isEmpty ? trimmed : base, 'code': code};
    }
    return {'name': trimmed, 'code': null};
  }

  void _handleDoctorSelection(String name) {
    final department = _pendingReservationDepartment;
    final parsed = _splitDoctorDisplay(name);
    final baseName = parsed['name'] ?? name;
    final doctorCode = parsed['code'];
    final metadata = <String, dynamic>{
      'doctor_name': baseName,
      if (doctorCode != null) 'doctor_code': doctorCode,
      if (department != null && department.trim().isNotEmpty)
        'department': department,
    };
    _pendingReservationDepartment = null;
    setState(() {
      _selectedDoctorKey = name;
    });
    _sendQuickMessage('$baseName 의사로 예약할게요', extraMetadata: metadata);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$baseName 의료진을 선택했습니다.'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Widget _buildDoctorCards(
    ChatTable table,
    ThemeData theme, {
    bool enableSelection = false,
  }) {
    final headerMap = <String, int>{};
    for (var i = 0; i < table.headers.length; i++) {
      headerMap[table.headers[i].trim()] = i;
    }

    int pickIndex(List<String> candidates, int fallback) {
      for (final key in candidates) {
        final index = headerMap[key];
        if (index != null) return index;
      }
      return fallback;
    }

    final nameIndex = pickIndex(['이름', '의료진', '의사'], 0);
    final titleIndex = pickIndex(['직책', '직위', '직급'], -1);
    final phoneIndex = pickIndex(['연락처', '전화', '전화번호'], -1);

    String readCell(List<String> row, int index) {
      if (index < 0 || index >= row.length) return '-';
      final value = row[index].trim();
      return value.isEmpty ? '-' : value;
    }

    final cards = <Widget>[];
    for (var rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
      final row = table.rows[rowIndex];
      final name = readCell(row, nameIndex);
      final title = titleIndex >= 0 ? readCell(row, titleIndex) : '-';
      final phone = phoneIndex >= 0 ? readCell(row, phoneIndex) : '-';
      final isSelected = enableSelection && name == _selectedDoctorKey;

      final card = Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enableSelection
                ? (isSelected ? Colors.blue.shade400 : Colors.blue.shade100)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '선택됨',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (title != '-' || phone != '-') ...[
              const SizedBox(height: 6),
              if (title != '-')
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              if (phone != '-')
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ],
        ),
      );
      if (enableSelection) {
        cards.add(
          InkWell(
            onTap: () => _handleDoctorSelection(name),
            borderRadius: BorderRadius.circular(12),
            child: card,
          ),
        );
      } else {
        cards.add(card);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }

  void _toggleRowExpansion(String key) {
    setState(() {
      if (_expandedRowKeys.contains(key)) {
        _expandedRowKeys.remove(key);
      } else {
        _expandedRowKeys.add(key);
      }
    });
  }

  int _findMemoIndex(ChatTable table) {
    for (var i = 0; i < table.headers.length; i++) {
      if (_isMemoLabel(table.headers[i])) {
        return i;
      }
    }
    return -1;
  }

  String _buildRowKey(String date, String time, String department, int index) {
    return '$date|$time|$department|$index';
  }

  bool _isMemoLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized.contains('\uBA54\uBAA8') ||
        normalized.contains('\uC99D\uC0C1') ||
        normalized.contains('memo') ||
        normalized.contains('note');
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    final trimmed = status.trim();
    Color background;
    Color foreground;
    if (trimmed.contains('\uCDE8\uC18C')) {
      background = Colors.red.shade50;
      foreground = Colors.red.shade700;
    } else if (trimmed.contains('\uC644\uB8CC')) {
      background = Colors.green.shade50;
      foreground = Colors.green.shade700;
    } else if (trimmed.contains('\uC811\uC218') ||
        trimmed.contains('\uC608\uC815')) {
      background = Colors.blue.shade50;
      foreground = Colors.blue.shade700;
    } else {
      background = Colors.grey.shade200;
      foreground = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        trimmed.isEmpty ? '-' : trimmed,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
    return 'anonymous';
  }

  void _persistMessages() {
    AppState.instance.setChatHistory(_chatSessionKey, _messages);
  }

  Future<void> _loadPersistedMessages(bool hadMemoryCache) async {
    final persisted = await AppState.instance.loadChatHistory(_chatSessionKey);
    if (!mounted) return;
    if (persisted.isNotEmpty) {
      setState(() {
        _messages
          ..clear()
          ..addAll(persisted);
      });
      return;
    }
    if (!hadMemoryCache) {
      _persistMessages();
    }
  }

  void _handleSend() {
    if (_isSending) return;
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    _sendQuickMessage(text);
  }

  void _sendQuickMessage(String text, {Map<String, dynamic>? extraMetadata}) {
    if (_isSending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: trimmed, isUser: true));
      _isSending = true;
    });
    _persistMessages();
    _scrollToBottom();
    _sendMessage(trimmed, extraMetadata: extraMetadata);
  }

  Future<void> _sendMessage(
    String text, {
    Map<String, dynamic>? extraMetadata,
  }) async {
    try {
      final session = AppState.instance.session;
      final metadata = <String, dynamic>{
        'platform': 'flutter-app',
        'version': '1.0.0',
        if (session != null) 'patient_id': session.patientId,
        if (session != null) 'patient_identifier': session.patientId,
        if (session != null && session.name.isNotEmpty) 'patient_name': session.name,
        if (session != null) 'patient_phone': session.phone,
        if (session != null) 'account_id': session.accountId,
        if (session != null && session.patientPk != null)
          'patient_pk': session.patientPk,
      };
      if (extraMetadata != null && extraMetadata.isNotEmpty) {
        metadata.addAll(extraMetadata);
      }
      final reply = await _chatService.requestReply(
        text,
        sessionId: _chatSessionId,
        metadata: metadata,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: reply.message,
            isUser: false,
            sources: reply.sources,
            table: reply.table,
          ),
        );
        if (_isDoctorSelectionPrompt(reply.message)) {
          _pendingReservationDepartment = _extractDepartmentFromPrompt(reply.message);
        }
      });
      _persistMessages();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                '\uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4: ${e.message}',
            isUser: false,
          ),
        );
      });
      _persistMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                '\uC77C\uC2DC\uC801\uC778 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4. '
                '\uC7A0\uC2DC \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.',
            isUser: false,
          ),
        );
      });
      _persistMessages();
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}
