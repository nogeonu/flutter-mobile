import 'package:flutter/material.dart';

import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
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
            Text('로그인', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              'CDSSentials 서비스 이용을 위해 로그인해 주세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            _LoginField(
              controller: _emailController,
              label: '계정 ID',
              hintText: '아이디를 입력하세요',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            _LoginField(
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value;
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    Text('자동 로그인', style: theme.textTheme.bodyMedium),
                  ],
                ),
                TextButton(onPressed: () {}, child: const Text('비밀번호 찾기')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('처음 방문하셨나요?', style: theme.textTheme.bodyMedium),
                TextButton(onPressed: () {}, child: const Text('회원가입')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는'),
                ),
                Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
              ],
            ),
            const SizedBox(height: 12),
            SocialLoginButton(
              icon: Icons.account_circle_outlined,
              label: '간편 인증으로 로그인',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
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
