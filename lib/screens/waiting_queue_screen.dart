import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

<<<<<<< HEAD
<<<<<<< HEAD
import '../data/waiting_ticket.dart';

=======
>>>>>>> main
class WaitingQueueScreen extends StatelessWidget {
=======
import '../models/medical_record.dart';
import '../services/medical_record_repository.dart';
import '../state/app_state.dart';

class WaitingQueueScreen extends StatefulWidget {
>>>>>>> main
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
<<<<<<< HEAD
    final patients = mockWaitingPatients;

    if (patients.isEmpty) {
      return const _EmptyState();
    }

    WaitingPatient? myPatient;
    for (final patient in patients) {
      if (patient.isMine) {
        myPatient = patient;
        break;
      }
    }
    final aheadCount = myPatient != null ? patients.indexOf(myPatient) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('내 대기 순번'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          if (myPatient != null)
            _WaitingSummary(
              theme: theme,
              myPatient: myPatient,
              aheadCount: aheadCount!,
            )
          else
            _NoWaitingSummary(theme: theme),
          const SizedBox(height: 20),
          _WaitingList(
            theme: theme,
            patients: patients,
            myPatientId: myPatient?.patientId,
          ),
        ],
      ),
    );
  }
}

class _WaitingSummary extends StatelessWidget {
  const _WaitingSummary({
    required this.theme,
    required this.myPatient,
    required this.aheadCount,
  });

  final ThemeData theme;
  final WaitingPatient myPatient;
  final int aheadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 현재 순번',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${myPatient.queueNumber} 번째',
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (myPatient.name.isNotEmpty)
            Text(
              '환자명: ${_maskName(myPatient.name)}',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 4),
          Text(
            '내 앞에는 $aheadCount명 대기 중입니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _instructionMessage(myPatient.queueNumber),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingList extends StatelessWidget {
  const _WaitingList({
    required this.theme,
    required this.patients,
    required this.myPatientId,
  });

  final ThemeData theme;
  final List<WaitingPatient> patients;
  final String? myPatientId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text('대기 중인 환자 목록', style: theme.textTheme.titleMedium),
          ),
          const Divider(height: 1),
          for (var i = 0; i < patients.length; i++)
            _WaitingListTile(
              patient: patients[i],
              isMine:
                  myPatientId != null && patients[i].patientId == myPatientId,
              isLast: i == patients.length - 1,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _WaitingListTile extends StatelessWidget {
  const _WaitingListTile({
    required this.patient,
    required this.isMine,
    required this.isLast,
    required this.theme,
  });

  final WaitingPatient patient;
  final bool isMine;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isMine
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.primary.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _QueueBadge(
            number: patient.queueNumber,
            isMine: isMine,
            theme: theme,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _maskName(patient.name),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.patientId} · ${patient.department}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Text(
            patient.formattedTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({
    required this.number,
    required this.isMine,
    required this.theme,
  });

  final int number;
  final bool isMine;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.primary;
    final color = isMine ? baseColor : baseColor.withOpacity(0.4);

    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: Text(
        number.toString(),
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoWaitingSummary extends StatelessWidget {
  const _NoWaitingSummary({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 대기 중인 순번이 없습니다.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '접수 후 순번이 표시되며, 목록에서 내 정보를 확인할 수 있습니다.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('내 대기 순번'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.35),
              ),
              const SizedBox(height: 20),
              Text(
                '현재 대기 중인 환자가 없습니다.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '진료 접수 후 순번이 표시될 예정입니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
                textAlign: TextAlign.center,
=======
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
<<<<<<< HEAD
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QueueSummary(accent: accent, patients: patients),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final isNext = index == 0;
                    return _QueueCard(
                      patient: patient,
                      accent: accent,
                      isNext: isNext,
                    );
                  },
                ),
>>>>>>> main
              ),
            ],
=======
          child: _buildBody(
            accent: accent,
            displayTicket: displayTicket,
            showMissingNotice: showMissingNotice,
>>>>>>> main
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

<<<<<<< HEAD
String _maskName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return name;
  if (trimmed.length == 1) return trimmed;
  if (trimmed.length == 2) {
    return '${trimmed[0]}*';
  }
  final start = trimmed[0];
  final end = trimmed[trimmed.length - 1];
  final middle = List.filled(trimmed.length - 2, '*').join();
  return '$start$middle$end';
}

String _instructionMessage(int queueNumber) {
  if (queueNumber <= 1) {
    return '지금 바로 진료실로 입장해주세요.';
  }
  if (queueNumber == 2 || queueNumber == 3) {
    return '진료실 근처에서 대기해주세요.';
  }
  return '잠시만 기다려 주세요.';
}
=======
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

<<<<<<< HEAD
const mockWaitingPatients = <WaitingPatient>[
  WaitingPatient(
    queueNumber: 1,
    patientId: 'P2025002',
    name: '김우선',
    department: '호흡기내과',
    receptionTime: TimeOfDay(hour: 20, minute: 19),
  ),
  WaitingPatient(
    queueNumber: 2,
    patientId: 'P2025009',
    name: '심자윤',
    department: '호흡기내과',
    receptionTime: TimeOfDay(hour: 12, minute: 29),
  ),
  WaitingPatient(
    queueNumber: 3,
    patientId: 'P2025010',
    name: '양의지',
    department: '외과',
    receptionTime: TimeOfDay(hour: 12, minute: 45),
  ),
];
>>>>>>> main
=======
String _formatTime(DateTime time) => DateFormat('HH:mm').format(time);

>>>>>>> main
