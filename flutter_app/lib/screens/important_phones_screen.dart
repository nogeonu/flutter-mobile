import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImportantPhonesScreen extends StatelessWidget {
  const ImportantPhonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phones = _phoneItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('주요 전화번호'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '뒤로 가기',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: phones.length,
            itemBuilder: (context, index) {
              final item = phones[index];
              return _PhoneTile(item: item);
            },
          ),
        ),
      ),
    );
  }
}

class _PhoneItem {
  const _PhoneItem({
    required this.title,
    required this.number,
    required this.icon,
  });

  final String title;
  final String number;
  final IconData icon;
}

final List<_PhoneItem> _phoneItems = const [
  _PhoneItem(
    title: '대표전화(예약·안내)',
    number: '042-600-9000',
    icon: Icons.support_agent_outlined,
  ),
  _PhoneItem(
    title: '진료예약',
    number: '042-600-9001',
    icon: Icons.medical_services_outlined,
  ),
  _PhoneItem(
    title: '건강검진예약',
    number: '042-600-9002',
    icon: Icons.favorite_border,
  ),
  _PhoneItem(
    title: '약처방문의',
    number: '042-600-9003',
    icon: Icons.medication_outlined,
  ),
  _PhoneItem(
    title: '약처방전 재발급',
    number: '042-600-9004',
    icon: Icons.description_outlined,
  ),
  _PhoneItem(
    title: '입원비 확인 ARS',
    number: '042-600-9005',
    icon: Icons.phone_in_talk_outlined,
  ),
  _PhoneItem(
    title: '응급실',
    number: '042-600-9119',
    icon: Icons.local_hospital_outlined,
  ),
  _PhoneItem(
    title: '고객상담실',
    number: '042-600-9006',
    icon: Icons.chat_bubble_outline,
  ),
];

class _PhoneTile extends StatelessWidget {
  const _PhoneTile({required this.item});

  final _PhoneItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Confirm in-app before opening dialer, giving user a clear back option
          final confirmed = await showModalBottomSheet<bool>(
            context: context,
            showDragHandle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) {
              final theme = Theme.of(ctx);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(item.icon, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                item.number,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            icon: const Icon(Icons.phone),
                            label: const Text('전화걸기'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
          if (confirmed == true) {
            // For ranges like '02-3410-3357~8', dial the primary number before '~'
            final primary = item.number.contains('~')
                ? item.number.split('~').first
                : item.number;
            final sanitized = primary.replaceAll(RegExp(r'[^0-9]'), '');
            if (sanitized.isEmpty) return;
            final uri = Uri(scheme: 'tel', path: sanitized);
            await launchUrl(uri);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  item.icon,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475467),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.number,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

