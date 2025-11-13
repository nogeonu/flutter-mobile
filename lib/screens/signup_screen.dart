import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _accountIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _accountIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).padding.bottom + 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('회원가입', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                '진료 예약과 건강 기록 확인을 위한 환자 계정을 지금 생성하세요.',
                style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            // 계정 ID
            _SignupField(
              controller: _accountIdController,
              label: '계정 ID',
              hintText: '아이디를 입력하세요',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 18),

            // 이름
            _SignupField(
              controller: _nameController,
              label: '이름',
              hintText: '이름을 입력하세요',
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 18),

            // 이메일
            _SignupField(
              controller: _emailController,
              label: '이메일',
              hintText: 'patient@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),

            // 연락처
            _SignupField(
              controller: _phoneController,
              label: '연락처',
              hintText: '010-1234-5678',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),

            // 비밀번호
            _SignupField(
              controller: _passwordController,
              label: '비밀번호',
              hintText: '비밀번호를 입력하세요',
              obscureText: _obscurePassword,
              suffix: IconButton(
                splashRadius: 18,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 18),

            // 비밀번호 확인
            _SignupField(
              controller: _passwordConfirmController,
              label: '비밀번호 확인',
              hintText: '비밀번호를 다시 입력하세요',
              obscureText: _obscurePasswordConfirm,
              suffix: IconButton(
                splashRadius: 18,
                icon: Icon(
                  _obscurePasswordConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePasswordConfirm = !_obscurePasswordConfirm;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons: 취소, 회원가입
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final pwd = _passwordController.text.trim();
                      final confirm = _passwordConfirmController.text.trim();
                      if (pwd != confirm) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) {
                            final theme = Theme.of(ctx);
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '비밀번호가 일치하지 않습니다.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        '확인',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          final theme = Theme.of(ctx);
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '회원가입이 완료되었습니다.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop(); // close dialog
                                      Navigator.of(context).pop(); // back to login
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      '확인',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('이미 계정이 있으신가요?', style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: () {
                    // If this screen was opened from login, pop will return to it.
                    Navigator.pop(context);
                  },
                  child: const Text('환자 로그인'),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.4,
              ),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

