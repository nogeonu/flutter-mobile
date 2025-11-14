import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/api_client.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser, this.sources});

  final String text;
  final bool isUser;
  final List<ChatSource>? sources;
}

class ChatModal extends StatefulWidget {
  const ChatModal({super.key});

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final _messages = <ChatMessage>[
    const ChatMessage(text: '안녕하세요! 무엇을 도와드릴까요?', isUser: false),
  ];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isSending = false;

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
                      'AI 상담',
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
                              message.text,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                            if (!message.isUser &&
                                message.sources != null &&
                                message.sources!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                '참고 자료',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: message.isUser
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...message.sources!.map(
                                (source) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ${source.title}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (source.snippet.isNotEmpty)
                                        Text(
                                          source.snippet,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: textColor.withOpacity(
                                                  0.9,
                                                ),
                                              ),
                                        ),
                                      if (source.url != null)
                                        Text(
                                          source.url!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: message.isUser
                                                    ? Colors.white
                                                    : theme.colorScheme.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
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
                          hintText: '궁금한 점을 입력하세요',
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

  void _handleSend() {
    if (_isSending) return;
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _inputController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    try {
      final reply = await _chatService.requestReply(
        text,
        sessionId: 'flutter-${DateTime.now().millisecondsSinceEpoch}',
        metadata: {'platform': 'flutter-app', 'version': '1.0.0'},
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: reply.message,
            isUser: false,
            sources: reply.sources,
          ),
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: '오류가 발생했습니다: ${e.message}', isUser: false),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: '일시적인 오류가 발생했습니다. 다시 시도해주세요.', isUser: false),
        );
      });
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
