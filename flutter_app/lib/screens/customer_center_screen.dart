import 'package:flutter/material.dart';
import 'chatbot_screen.dart';
import 'important_phones_screen.dart';
import 'voice_of_customer_screen.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
                child: Text(
                  '고객의 소리',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: '고객의 소리',
                subtitle: '병원을 이용하시면서 불편하신 점이나\n건의사항을 등록해 주세요.',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VoiceOfCustomerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
                child: Text(
                  '챗봇 상담',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: '챗봇',
                subtitle: '병원 이용 및 앱 관련 문의사항을 검색하실 수 있습니다.',
                icon: Icons.chat_bubble_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
                child: Text(
                  '주요 전화번호',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: '주요 전화번호',
                subtitle: '자주 사용하는 병원 대표 전화번호를 한 눈에 확인하고\n바로 통화하실 수 있습니다.',
                icon: Icons.call_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportantPhonesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 0, 4),
                child: Text(
                  '자주 묻는 질문',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _SectionCard(
                title: 'FAQ',
                subtitle: '진료 예약, 대기 순번, 진료 내역 등\n자주 묻는 질문을 확인하실 수 있습니다.',
                icon: Icons.help_outline,
                onTap: () => _showFAQDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자주 묻는 질문'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _FAQItem(
                question: '진료 예약은 어떻게 하나요?',
                answer: '앱 메인 화면의 "진료예약" 메뉴를 통해 예약하실 수 있습니다. 진료과와 담당의를 선택한 후 원하는 시간을 선택하세요.',
              ),
              Divider(height: 24),
              _FAQItem(
                question: '대기 순번은 어디서 확인하나요?',
                answer: '로그인 후 "대기순번" 메뉴에서 현재 대기 상태를 실시간으로 확인하실 수 있습니다.',
              ),
              Divider(height: 24),
              _FAQItem(
                question: '진료 내역은 어떻게 조회하나요?',
                answer: '로그인 후 "진료내역" 메뉴에서 과거 진료 기록을 조회하실 수 있습니다.',
              ),
              Divider(height: 24),
              _FAQItem(
                question: '주차는 어디서 하나요?',
                answer: '"주차장" 메뉴에서 실시간 주차 정보를 확인하실 수 있으며, 병원 내 지하 주차장과 옥외 주차장을 이용하실 수 있습니다.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 (왼쪽)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5C6672),
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // 화살표
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  const _FAQItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

