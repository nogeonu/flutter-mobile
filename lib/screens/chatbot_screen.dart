import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../services/chat_repository.dart';
import '../services/api_client.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _chatRepository = ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  late final String _sessionId;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionId = _uuid.v4();
    
    // 환영 메시지
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        message: '안녕하세요! 건양대학교병원 챗봇입니다.\n무엇을 도와드릴까요?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatRepository.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      message: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // 로그인 상태 확인 및 메타데이터 구성
      final appState = AppState.instance;
      final metadata = <String, dynamic>{};
      
      if (appState.isLoggedIn && appState.session != null) {
        metadata['patient_id'] = appState.session!.patientId;
        metadata['patient_identifier'] = appState.session!.patientId;
        metadata['account_id'] = appState.session!.accountId;
        if (appState.session!.patientPk != null) {
          metadata['patient_pk'] = appState.session!.patientPk;
        }
      }

      final botMessage = await _chatRepository.sendMessage(
        message: text,
        sessionId: _sessionId,
        metadata: metadata,
      );

      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            message: '죄송합니다. 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('챗봇 상담'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  message: message,
                  theme: theme,
                  onDoctorSelect: (doctorName) {
                    // 의료진 선택 시 확장 가능한 카드로 표시 (서버로 메시지 전송하지 않음)
                    // 날짜/시간 선택 후 완료 버튼을 누르면 예약 요청
                  },
                  onReservationComplete: (doctorName, date, time) async {
                    // 예약 완료/변경 요청
                    // doctorName에 "의료진 예약을 XXX에서 YYY으로 변경" 형식이 이미 포함되어 있으면 그대로 사용
                    String reservationMessage;
                    if (doctorName.contains('에서') && doctorName.contains('으로 변경')) {
                      // 이미 완전한 변경 메시지 형식
                      reservationMessage = doctorName;
                    } else {
                      // 일반 예약 메시지
                      final dateTimeText = '${DateFormat('M월 d일', 'ko_KR').format(date)} ${time.hour}시 ${time.minute}분';
                      reservationMessage = '$doctorName $dateTimeText 예약';
                    }
                    
                    final userMessage = ChatMessage(
                      id: _uuid.v4(),
                      message: reservationMessage,
                      isUser: true,
                      timestamp: DateTime.now(),
                    );

                    setState(() {
                      _messages.add(userMessage);
                      _isLoading = true;
                    });

                    _scrollToBottom();

                    try {
                      final appState = AppState.instance;
                      final metadata = <String, dynamic>{};

                      if (appState.isLoggedIn && appState.session != null) {
                        metadata['patient_id'] = appState.session!.patientId;
                        metadata['patient_identifier'] = appState.session!.patientId;
                        metadata['account_id'] = appState.session!.accountId;
                        if (appState.session!.patientPk != null) {
                          metadata['patient_pk'] = appState.session!.patientPk;
                        }
                      }

                      final botMessage = await _chatRepository.sendMessage(
                        message: reservationMessage,
                        sessionId: _sessionId,
                        metadata: metadata,
                      );

                      setState(() {
                        _messages.add(botMessage);
                        _isLoading = false;
                      });

                      _scrollToBottom();
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                        final errMsg = e is ApiException
                            ? e.message
                            : '죄송합니다. 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
                        _messages.add(
                          ChatMessage(
                            id: _uuid.v4(),
                            message: errMsg,
                            isUser: false,
                            timestamp: DateTime.now(),
                          ),
                        );
                      });
                      _scrollToBottom();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('오류: ${e is ApiException ? e.message : e}')),
                        );
                      }
                    }
                  },
                  onButtonTap: (action) async {
                    // 버튼 클릭 시 메시지 전송
                    final userMessage = ChatMessage(
                      id: _uuid.v4(),
                      message: action,
                      isUser: true,
                      timestamp: DateTime.now(),
                    );

                    setState(() {
                      _messages.add(userMessage);
                      _isLoading = true;
                    });

                    _scrollToBottom();

                    try {
                      final appState = AppState.instance;
                      final metadata = <String, dynamic>{};

                      if (appState.isLoggedIn && appState.session != null) {
                        metadata['patient_id'] = appState.session!.patientId;
                        metadata['patient_identifier'] = appState.session!.patientId;
                        metadata['account_id'] = appState.session!.accountId;
                        if (appState.session!.patientPk != null) {
                          metadata['patient_pk'] = appState.session!.patientPk;
                        }
                      }

                      final botMessage = await _chatRepository.sendMessage(
                        message: action,
                        sessionId: _sessionId,
                        metadata: metadata,
                      );

                      setState(() {
                        _messages.add(botMessage);
                        _isLoading = false;
                      });

                      _scrollToBottom();
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                        _messages.add(
                          ChatMessage(
                            id: _uuid.v4(),
                            message: '죄송합니다. 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
                            isUser: false,
                            timestamp: DateTime.now(),
                          ),
                        );
                      });
                      _scrollToBottom();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('오류: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '답변 생성 중...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.theme,
    required this.onDoctorSelect,
    required this.onButtonTap,
    this.onReservationComplete,
  });

  final ChatMessage message;
  final ThemeData theme;
  final Function(String) onDoctorSelect;
  final Function(String) onButtonTap;
  final Function(String, DateTime, TimeOfDay)? onReservationComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: message.isUser
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: message.isUser ? null : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: message.isUser
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (message.table != null && !message.isUser)
                  _buildTableCards(
                    table: message.table!,
                    theme: theme,
                    onDoctorSelect: onDoctorSelect,
                    onReservationComplete: onReservationComplete,
                  ),
                if (message.buttons != null && message.buttons!.isNotEmpty && !message.isUser)
                  _buildActionButtons(
                    buttons: message.buttons!,
                    theme: theme,
                    onButtonTap: onButtonTap,
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildTableCards({
  required Map<String, dynamic> table,
  required ThemeData theme,
  required Function(String) onDoctorSelect,
  Function(String, DateTime, TimeOfDay)? onReservationComplete,
}) {
  final headers = table['headers'] as List<dynamic>?;
  final rows = table['rows'] as List<dynamic>?;
  final isRescheduleMode = table['reschedule_mode'] == true;
  
  if (rows == null || rows.isEmpty) {
    return const SizedBox.shrink();
  }

  // 의료진 목록인지 예약 내역인지 확인
  final isDoctorList = headers != null && 
      headers.length >= 2 && 
      headers[0].toString().contains('이름');

  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        final rowData = row as List<dynamic>;
        
        if (isDoctorList) {
          // 의료진 목록 카드 - 확장 가능한 카드로 변경
          if (rowData.isEmpty) return const SizedBox.shrink();
          
          final name = rowData[0] as String? ?? '';
          final title = rowData.length > 1 ? (rowData[1] as String? ?? '') : '';
          final phone = rowData.length > 2 ? (rowData[2] as String? ?? '') : '';
          
          // 의료진 메타데이터에서 doctor_code/doctor_id 추출
          final doctorMetadata = table['doctor_metadata'] as List<dynamic>?;
          String? doctorCode;
          String? doctorId;
          if (doctorMetadata != null && rows != null) {
            final rowIndex = rows.toList().indexOf(row);
            if (rowIndex >= 0 && rowIndex < doctorMetadata.length) {
              final metadata = doctorMetadata[rowIndex] as Map<String, dynamic>?;
              doctorCode = metadata?['doctor_code']?.toString();
              doctorId = metadata?['doctor_id']?.toString();
            }
          }
          
          // 이름에서 괄호 안의 코드 추출 (예: "김우선 (D2025010)")
          if (doctorCode == null && name.contains('(') && name.contains(')')) {
            final match = RegExp(r'\(([^)]+)\)').firstMatch(name);
            if (match != null) {
              doctorCode = match.group(1);
            }
          }

          return _ExpandableDoctorCard(
            doctorName: name,
            title: title,
            phone: phone,
            doctorCode: doctorCode,
            doctorId: doctorId,
            theme: theme,
            onReservationComplete: onReservationComplete,
          );
        } else {
          // 예약 내역 카드
          if (rowData.length < 4) return const SizedBox.shrink();

          final date = rowData[0] as String? ?? '';
          final time = rowData[1] as String? ?? '';
          final department = rowData[2] as String? ?? '';
          final doctor = rowData[3] as String? ?? '';

          // 예약 변경 모드일 때 확장 가능한 카드로 표시
          if (isRescheduleMode) {
            return _ExpandableReservationCard(
              date: date,
              time: time,
              department: department,
              doctor: doctor,
              theme: theme,
              onRescheduleComplete: (newDate, newTime) async {
                      // 예약 변경 완료 시 서버에 변경 요청
                      // 원래 예약 정보(date, time, doctor)와 새 예약 정보를 함께 전달
                      if (onReservationComplete != null) {
                        final originalDateTime = '$date $time';
                        final newDateTime = '${DateFormat('yyyy-MM-dd').format(newDate)} ${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
                        final rescheduleMessage = '$doctor 의료진 예약을 $originalDateTime에서 $newDateTime으로 변경';
                        onReservationComplete(rescheduleMessage, newDate, newTime);
                      }
                    },
            );
          }

          final dateTimeText = time.isNotEmpty ? '$date $time' : date;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateTimeText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              department,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doctor,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }
      }).toList(),
    ),
  );
}

Widget _buildActionButtons({
  required List<Map<String, dynamic>> buttons,
  required ThemeData theme,
  required Function(String) onButtonTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buttons.map((button) {
        final text = button['text'] as String? ?? '';
        final action = button['action'] as String? ?? text;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onButtonTap(action),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

// 확장 가능한 의료진 카드 위젯
class _ExpandableDoctorCard extends StatefulWidget {
  final String doctorName;
  final String title;
  final String phone;
  final String? doctorCode;
  final String? doctorId;
  final ThemeData theme;
  final Function(String, DateTime, TimeOfDay)? onReservationComplete;

  const _ExpandableDoctorCard({
    required this.doctorName,
    required this.title,
    required this.phone,
    this.doctorCode,
    this.doctorId,
    required this.theme,
    this.onReservationComplete,
  });

  @override
  State<_ExpandableDoctorCard> createState() => _ExpandableDoctorCardState();
}

class _ExpandableDoctorCardState extends State<_ExpandableDoctorCard> {
  bool _isExpanded = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Set<String> _bookedTimeSlots = {}; // 예약된 시간대 (예: "09:00", "10:30")
  bool _isLoadingAvailableTimes = false;

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = DateTime(now.year, now.month + 3, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: widget.theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // 날짜 변경 시 시간 초기화
        _bookedTimeSlots = {}; // 예약된 시간대 초기화
      });
      
      // 예약 가능 시간 조회
      _loadAvailableTimeSlots(picked);
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingAvailableTimes = true;
    });

    try {
      final chatRepository = ChatRepository();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      print('[ChatbotScreen] 예약 가능 시간 조회 시작: date=$dateStr, doctorId=${widget.doctorId}, doctorCode=${widget.doctorCode}');
      
      final result = await chatRepository.getAvailableTimeSlots(
        date: dateStr,
        doctorId: widget.doctorId,
        doctorCode: widget.doctorCode,
        sessionId: null, // sessionId는 선택적
      );

      print('[ChatbotScreen] 예약 가능 시간 조회 결과: $result');

      if (result['status'] == 'ok') {
        final bookedTimes = (result['booked_times'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ?? {};
        
        print('[ChatbotScreen] 예약된 시간대: $bookedTimes');
        
        setState(() {
          _bookedTimeSlots = bookedTimes;
        });
      } else {
        print('[ChatbotScreen] 예약 가능 시간 조회 실패: status=${result['status']}, message=${result['message']}');
        setState(() {
          _bookedTimeSlots = {};
        });
      }
    } catch (e, stackTrace) {
      print('[ChatbotScreen] 예약 가능 시간 조회 예외 발생: $e');
      print('[ChatbotScreen] 스택 트레이스: $stackTrace');
      // 에러 발생 시에도 계속 진행 (예약된 시간대를 빈 집합으로 처리)
      setState(() {
        _bookedTimeSlots = {};
      });
    } finally {
      setState(() {
        _isLoadingAvailableTimes = false;
      });
    }
  }

  void _selectTimeSlot(TimeOfDay time) {
    setState(() {
      _selectedTime = time;
    });
  }

  // 시간 슬롯 생성 (9:00 ~ 18:00, 30분 단위)
  List<TimeOfDay> _generateTimeSlots() {
    final List<TimeOfDay> slots = [];
    for (int hour = 9; hour <= 18; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 18) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  void _completeReservation() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('날짜와 시간을 모두 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.onReservationComplete != null) {
      widget.onReservationComplete!(
        widget.doctorName,
        _selectedDate!,
        _selectedTime!,
      );
      
      // 예약 완료 후 상태 초기화
      setState(() {
        _isExpanded = false;
        _selectedDate = null;
        _selectedTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded
              ? widget.theme.colorScheme.primary
              : widget.theme.colorScheme.primary.withOpacity(0.2),
          width: _isExpanded ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.theme.colorScheme.primary.withOpacity(
              _isExpanded ? 0.15 : 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 의료진 정보 헤더
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.theme.colorScheme.primary.withOpacity(0.1),
                          widget.theme.colorScheme.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: widget.theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: widget.theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.title.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.title,
                            style: widget.theme.textTheme.bodyMedium?.copyWith(
                              color: widget.theme.colorScheme.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: widget.theme.colorScheme.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // 확장된 날짜/시간 선택 섹션
          if (_isExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: widget.theme.colorScheme.outline.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예약 날짜/시간 선택',
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 날짜 선택
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: widget.theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat('yyyy년 M월 d일 (E)', 'ko_KR')
                                      .format(_selectedDate!)
                                  : '날짜 선택',
                              style: widget.theme.textTheme.bodyMedium?.copyWith(
                                color: _selectedDate != null
                                    ? widget.theme.textTheme.bodyMedium?.color
                                    : widget.theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: widget.theme.colorScheme.secondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 시간 선택
                  Text(
                    '시간 선택 *',
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.theme.textTheme.titleSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 시간 슬롯 그리드
                  Builder(
                    builder: (context) {
                      final itemCount = _generateTimeSlots().length;
                      final crossAxisCount = 4;
                      final rows = (itemCount / crossAxisCount).ceil();
                      // 고정 높이 계산: 각 행의 높이 (약 40px) + 간격 (8px)
                      // 19개 슬롯 / 4열 = 5행, 각 행 높이 40px + 간격 8px
                      final totalHeight = rows * 40.0 + (rows - 1) * 8.0;
                      
                      return SizedBox(
                        height: totalHeight,
                        child: GridView.builder(
                          shrinkWrap: false,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                      final timeSlot = _generateTimeSlots()[index];
                      final isSelected = _selectedTime != null &&
                          _selectedTime!.hour == timeSlot.hour &&
                          _selectedTime!.minute == timeSlot.minute;
                      
                      // 시간 슬롯 문자열 생성 (예: "09:00", "10:30")
                      final timeSlotStr = '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';
                      
                      // 현재 시간 이전 슬롯은 비활성화 (선택한 날짜가 오늘이면)
                      final now = DateTime.now();
                      final isToday = _selectedDate != null &&
                          _selectedDate!.year == now.year &&
                          _selectedDate!.month == now.month &&
                          _selectedDate!.day == now.day;
                      final isPast = isToday &&
                          (timeSlot.hour < now.hour ||
                              (timeSlot.hour == now.hour && timeSlot.minute < now.minute));
                      
                      // 예약된 시간대인지 확인
                      final isBooked = _bookedTimeSlots.contains(timeSlotStr);
                      
                      // 비활성화 조건: 과거 시간이거나 예약된 시간대
                      final isDisabled = isPast || isBooked;
                      
                      return InkWell(
                        onTap: isDisabled ? null : () => _selectTimeSlot(timeSlot),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.grey[300] // 예약된 시간대는 회색
                                : isSelected
                                    ? widget.theme.colorScheme.primary
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDisabled
                                  ? Colors.grey[400] ?? widget.theme.colorScheme.outline.withOpacity(0.3)
                                  : isSelected
                                      ? widget.theme.colorScheme.primary
                                      : widget.theme.colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: isDisabled
                                    ? Colors.grey[600] ?? widget.theme.colorScheme.outline.withOpacity(0.5)
                                    : isSelected
                                        ? Colors.white
                                        : widget.theme.textTheme.bodySmall?.color,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // 완료 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        '예약 완료',
                        style: widget.theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 확장 가능한 예약 변경 카드 위젯
class _ExpandableReservationCard extends StatefulWidget {
  final String date;
  final String time;
  final String department;
  final String doctor;
  final ThemeData theme;
  final Function(DateTime, TimeOfDay)? onRescheduleComplete;

  const _ExpandableReservationCard({
    required this.date,
    required this.time,
    required this.department,
    required this.doctor,
    required this.theme,
    this.onRescheduleComplete,
  });

  @override
  State<_ExpandableReservationCard> createState() => _ExpandableReservationCardState();
}

class _ExpandableReservationCardState extends State<_ExpandableReservationCard> {
  bool _isExpanded = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Set<String> _bookedTimeSlots = {};
  bool _isLoadingAvailableTimes = false;

  @override
  void initState() {
    super.initState();
    _parseExistingReservation();
  }

  void _parseExistingReservation() {
    try {
      if (widget.date.isNotEmpty) {
        final dateParts = widget.date.split('-');
        if (dateParts.length >= 3) {
          _selectedDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      }
      
      if (widget.time.isNotEmpty) {
        final timeParts = widget.time.split(':');
        if (timeParts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      }
    } catch (e) {
      print('[ChatbotScreen] 기존 예약 파싱 실패: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = DateTime(now.year, now.month + 3, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: widget.theme.textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _bookedTimeSlots = {};
      });
      
      _loadAvailableTimeSlots(picked);
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingAvailableTimes = true;
    });

    try {
      final chatRepository = ChatRepository();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      String? doctorCode;
      if (widget.doctor.contains('(') && widget.doctor.contains(')')) {
        final match = RegExp(r'\(([^)]+)\)').firstMatch(widget.doctor);
        if (match != null) {
          doctorCode = match.group(1);
        }
      }
      
      final result = await chatRepository.getAvailableTimeSlots(
        date: dateStr,
        doctorCode: doctorCode,
        sessionId: null,
      );

      if (result['status'] == 'ok') {
        final bookedTimes = (result['booked_times'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ?? {};
        
        setState(() {
          _bookedTimeSlots = bookedTimes;
        });
      }
    } catch (e) {
      print('[ChatbotScreen] 예약 가능 시간 조회 실패: $e');
      setState(() {
        _bookedTimeSlots = {};
      });
    } finally {
      setState(() {
        _isLoadingAvailableTimes = false;
      });
    }
  }

  void _selectTimeSlot(TimeOfDay time) {
    setState(() {
      _selectedTime = time;
    });
  }

  List<TimeOfDay> _generateTimeSlots() {
    final List<TimeOfDay> slots = [];
    for (int hour = 9; hour <= 18; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 18) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  void _completeReschedule() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('변경할 날짜와 시간을 모두 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.onRescheduleComplete != null) {
      widget.onRescheduleComplete!(_selectedDate!, _selectedTime!);
      
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeText = widget.time.isNotEmpty 
        ? '${widget.date} ${widget.time}' 
        : widget.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateTimeText,
                          style: widget.theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 18,
                              color: widget.theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.department,
                              style: widget.theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: widget.theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.doctor,
                                style: widget.theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: widget.theme.colorScheme.secondary.withOpacity(0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '예약 날짜/시간 변경',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: widget.theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDate!)
                                  : '날짜 선택',
                              style: widget.theme.textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: widget.theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '시간 선택 *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingAvailableTimes)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final itemCount = _generateTimeSlots().length;
                        final crossAxisCount = 4;
                        final rows = (itemCount / crossAxisCount).ceil();
                        final totalHeight = rows * 40.0 + (rows - 1) * 8.0;
                        
                        return SizedBox(
                          height: totalHeight,
                          child: GridView.builder(
                            shrinkWrap: false,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              final timeSlot = _generateTimeSlots()[index];
                              final isSelected = _selectedTime != null &&
                                  _selectedTime!.hour == timeSlot.hour &&
                                  _selectedTime!.minute == timeSlot.minute;
                              
                              final timeSlotStr = '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';
                              
                              final now = DateTime.now();
                              final isToday = _selectedDate != null &&
                                  _selectedDate!.year == now.year &&
                                  _selectedDate!.month == now.month &&
                                  _selectedDate!.day == now.day;
                              final isPast = isToday &&
                                  (timeSlot.hour < now.hour ||
                                      (timeSlot.hour == now.hour && timeSlot.minute < now.minute));
                              
                              final isBooked = _bookedTimeSlots.contains(timeSlotStr);
                              final isDisabled = isPast || isBooked;
                              
                              return InkWell(
                                onTap: isDisabled ? null : () => _selectTimeSlot(timeSlot),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? Colors.grey[300]
                                        : isSelected
                                            ? widget.theme.colorScheme.primary
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDisabled
                                          ? Colors.grey[400]!
                                          : isSelected
                                              ? widget.theme.colorScheme.primary
                                              : widget.theme.colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      timeSlotStr,
                                      style: TextStyle(
                                        color: isDisabled
                                            ? widget.theme.colorScheme.outline.withOpacity(0.5)
                                            : isSelected
                                                ? Colors.white
                                                : widget.theme.textTheme.bodyMedium?.color,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        '예약 변경 완료',
                        style: widget.theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
