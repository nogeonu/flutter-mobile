import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/medical_record.dart';
import '../services/medical_record_repository.dart';
import '../state/app_state.dart';

class WaitingQueueScreen extends StatefulWidget {
  const WaitingQueueScreen({super.key});

  @override
  State<WaitingQueueScreen> createState() => _WaitingQueueScreenState();
}

class _WaitingQueueScreenState extends State<WaitingQueueScreen> {
  final MedicalRecordRepository _repository = MedicalRecordRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<WaitingTicket> _tickets = const [];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_handleAppStateChanged);
    _loadWaitingQueue();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    _loadWaitingQueue();
  }

  Future<void> _loadWaitingQueue() async {
    final session = AppState.instance.session;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _repository.fetchWaitingRecords();
      records.sort(
        (a, b) => a.receptionStartTime.compareTo(b.receptionStartTime),
      );

      final tickets = <WaitingTicket>[];
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        final isCurrentUser = session != null && record.patientId == session.patientId;
        tickets.add(
          WaitingTicket(
            queueNumber: i + 1,
            record: record,
            isCurrentUser: isCurrentUser,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _tickets = tickets;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  WaitingTicket? _findMyTicket() {
    for (final ticket in _tickets) {
      if (ticket.isCurrentUser) return ticket;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final session = AppState.instance.session;

    final myTicket = _findMyTicket();
    final displayTicket = myTicket ?? (_tickets.isNotEmpty ? _tickets.first : null);
    final bool showMissingNotice = session != null && myTicket == null && _tickets.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('대기 순번'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _isLoading ? null : _loadWaitingQueue,
            icon: Icon(Icons.refresh_rounded, color: accent),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _buildBody(
            accent: accent,
            displayTicket: displayTicket,
            showMissingNotice: showMissingNotice,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required Color accent,
    required WaitingTicket? displayTicket,
    required bool showMissingNotice,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadWaitingQueue,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QueueSummary(
          accent: accent,
          ticket: displayTicket,
          waitingCount: _tickets.length,
          isMine: displayTicket != null && displayTicket.isCurrentUser,
        ),
        if (showMissingNotice) ...[
          const SizedBox(height: 12),
          const _MissingTicketNotice(),
        ],
        const SizedBox(height: 20),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadWaitingQueue,
            child: _tickets.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      _EmptyQueuePlaceholder(),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return _QueueCard(
                        ticket: ticket,
                        accent: accent,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({
    required this.accent,
    required this.ticket,
    required this.waitingCount,
    required this.isMine,
  });

  final Color accent;
  final WaitingTicket? ticket;
  final int waitingCount;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentTicket = ticket;

    if (currentTicket == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 대기 환자가 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '접수 완료된 환자가 등록되면 순번 정보가 표시됩니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    final title = isMine ? '현재 나의 순서' : '현재 대기 1순위';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475467),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  currentTicket.queueNumber.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '번째',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentTicket.record.patientName} · ${currentTicket.record.patientId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF475467),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital_outlined,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            currentTicket.record.department,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF475467),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '전체 $waitingCount명 대기 중',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.ticket,
    required this.accent,
  });

  final WaitingTicket ticket;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = ticket.record;
    final timeLabel = _formatTime(record.receptionStartTime);
    final notesLines = record.noteLines;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: ticket.isCurrentUser ? accent.withOpacity(0.45) : Colors.transparent,
          width: ticket.isCurrentUser ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${ticket.queueNumber}번',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.patientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.patientId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '접수 $timeLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475467),
                    ),
                  ),
                  if (ticket.isCurrentUser) ...[
                    const SizedBox(height: 6),
                    Chip(
                      label: const Text('내 순번'),
                      backgroundColor: accent.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 20,
                color: accent.withOpacity(0.85),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.department,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2432),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: accent.withOpacity(0.85),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.statusLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),
          if (notesLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '메모',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notesLines
                  .map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '· $note',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingTicketNotice extends StatelessWidget {
  const _MissingTicketNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFBF5B04),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '현재 접수 내역이 확인되지 않습니다. 원무과 접수 후 다시 확인해 주세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFBF5B04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 56,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 불러오기'),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueuePlaceholder extends StatelessWidget {
  const _EmptyQueuePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text(
          '현재 대기 중인 환자가 없습니다.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '접수 완료된 환자가 발생하면 순번이 표시됩니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class WaitingTicket {
  const WaitingTicket({
    required this.queueNumber,
    required this.record,
    required this.isCurrentUser,
  });

  final int queueNumber;
  final MedicalRecord record;
  final bool isCurrentUser;
}

String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

