import 'dart:convert';
import 'package:flutter/material.dart';

class VoiceOfCustomerScreen extends StatefulWidget {
  const VoiceOfCustomerScreen({super.key});

  @override
  State<VoiceOfCustomerScreen> createState() => _VoiceOfCustomerScreenState();
}

enum _Relation { self, family, other }

enum _ConsultType { praise, complaint, proposal }

class _VoiceOfCustomerScreenState extends State<VoiceOfCustomerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  _Relation _relation = _Relation.self;
  _ConsultType _consultType = _ConsultType.praise;
  int _contentBytes = 0;

  static const int _maxBytes = 4000; // 한글 2000자, 영문 4000자 기준 안내

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateByteCount);
  }

  void _updateByteCount() {
    final value = _contentController.value;
    // If user is composing (e.g., Korean IME), skip rebuild to avoid breaking composition
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return;
    }
    final bytes = utf8.encode(value.text).length;
    if (bytes != _contentBytes) {
      setState(() {
        _contentBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객의 소리'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '고객상담실 안내',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Bullet(text: '칭찬 및 감사 의견 접수'),
                    SizedBox(height: 6),
                    _Bullet(text: '제안 및 불만 고충 상담'),
                    SizedBox(height: 6),
                    _Bullet(text: '유실물 접수 안내'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '고객상담실 방문 및 전화상담',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _KeyValueRow(label: '방문', value: '본관 지하 1층 고객상담실'),
                    SizedBox(height: 8),
                    _KeyValueRow(label: '전화', value: '042-600-9000'),
                    SizedBox(height: 8),
                    _KeyValueRow(
                      label: '상담시간',
                      value: '평일 09:00 ~ 16:30 (주말, 공휴일 휴무)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '온라인 접수',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InfoBox(
                child: Column(
                  children: [
                    _LabeledField(
                      label: '이름',
                      requiredMark: true,
                      child: TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: '',
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LabeledField(
                          label: '전화번호',
                          requiredMark: true,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              hintText: '',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LabeledField(
                          label: '이메일',
                          requiredMark: true,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              hintText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _LabeledField(
                      label: '환자와의관계',
                      requiredMark: true,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _RadioChip<_Relation>(
                            label: '본인',
                            value: _Relation.self,
                            groupValue: _relation,
                            onChanged: (v) => setState(() => _relation = v!),
                          ),
                          _RadioChip<_Relation>(
                            label: '가족',
                            value: _Relation.family,
                            groupValue: _relation,
                            onChanged: (v) => setState(() => _relation = v!),
                          ),
                          _RadioChip<_Relation>(
                            label: '기타',
                            value: _Relation.other,
                            groupValue: _relation,
                            onChanged: (v) => setState(() => _relation = v!),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _LabeledField(
                      label: '상담유형',
                      requiredMark: true,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _RadioChip<_ConsultType>(
                            label: '칭찬',
                            value: _ConsultType.praise,
                            groupValue: _consultType,
                            onChanged: (v) => setState(() => _consultType = v!),
                          ),
                          _RadioChip<_ConsultType>(
                            label: '불만',
                            value: _ConsultType.complaint,
                            groupValue: _consultType,
                            onChanged: (v) => setState(() => _consultType = v!),
                          ),
                          _RadioChip<_ConsultType>(
                            label: '제안 및 건의',
                            value: _ConsultType.proposal,
                            groupValue: _consultType,
                            onChanged: (v) => setState(() => _consultType = v!),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _LabeledField(
                      label: '제목',
                      requiredMark: true,
                      child: TextField(
                        controller: _titleController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: '',
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _LabeledField(
                      label: '내용',
                      requiredMark: true,
                      child: Column(
                        children: [
                          TextField(
                            controller: _contentController,
                            maxLines: 8,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Theme.of(context).colorScheme.primary),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$_contentBytes byte / 최대 $_maxBytes byte (한글 2000자, 영문 4000자)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF667085),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.edit),
                        label: const Text('접수하기'),
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

  void _submit() {
    // 간단한 유효성 검사 (필수값)
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목을 모두 입력해 주세요.')),
      );
      return;
    }
    if (_contentBytes > _maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용이 최대 바이트를 초과했습니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('온라인 접수 내용이 임시 저장되었습니다. (연동 준비 중)'),
      ),
    );
    
    // 접수 후 이전 화면으로 돌아가기
    Navigator.of(context).pop();
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.requiredMark = false,
  });

  final String label;
  final bool requiredMark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: label),
                  if (requiredMark)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RadioChip<T> extends StatelessWidget {
  const _RadioChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onChanged(value),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475467),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            '$label :',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475467),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

