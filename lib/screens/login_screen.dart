import 'package:flutter/material.dart';

import '../models/medical_record.dart';
import '../models/patient_profile.dart';
import '../models/patient_session.dart';
import '../services/patient_repository.dart';
import '../state/app_state.dart';
import '../widgets/social_login_button.dart';
import 'patient_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repository = PatientRepository();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  PatientSession? _session;
  String? _errorMessage;
  String? _profileError;
  List<MedicalRecord> _medicalRecords = const [];

  @override
  void initState() {
    super.initState();
    _session = AppState.instance.session;
    if (_session != null) {
      _loadPatientInfo(_session!);
    }
    AppState.instance.addListener(_handleAppStateChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    AppState.instance.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    final session = AppState.instance.session;
    if (session != _session) {
      setState(() {
        _session = session;
        _profileError = null;
        _medicalRecords = const [];
      });
      if (session != null) {
        _loadPatientInfo(session);
      }
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final accountId = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (accountId.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '계정 ID와 비밀번호를 모두 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _repository.login(accountId: accountId, password: password);
      AppState.instance.updateSession(session);
      setState(() {
        _session = session;
        _profileError = null;
      });
      await _loadPatientInfo(session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인에 성공했습니다.')));
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPatientInfo(PatientSession session) async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    try {
      final records = await _repository.fetchMedicalRecords(session.patientId);
      records.sort(
        (a, b) => b.receptionStartTime.compareTo(a.receptionStartTime),
      );
      if (!mounted) return;
      setState(() {
        _medicalRecords = records;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  void _handleLogout() {
    AppState.instance.updateSession(null);
    setState(() {
      _session = null;
      _medicalRecords = const [];
      _profileError = null;
    });
    _emailController.clear();
    _passwordController.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('로그아웃되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_session != null) {
      return _MyPageView(
        session: _session!,
        isLoading: _isLoadingProfile,
        errorMessage: _profileError,
        records: _medicalRecords,
        onLogout: _handleLogout,
      );
    }

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
            const SizedBox(height: 12),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (_session != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('현재 로그인 정보', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('${_session!.name} · ${_session!.patientId}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
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
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
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

class _MyPageView extends StatelessWidget {
  const _MyPageView({
    required this.session,
    required this.records,
    required this.isLoading,
    required this.onLogout,
    this.errorMessage,
  });

  final PatientSession session;
  final List<MedicalRecord> records;
  final bool isLoading;
  final VoidCallback onLogout;
  final String? errorMessage;

  Future<void> _handleProfileTap(BuildContext context) async {
    final updated = await Navigator.of(context).push<PatientProfile>(
      MaterialPageRoute(
        builder: (_) => PatientProfileScreen(session: session),
      ),
    );
    if (!context.mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 정보가 저장되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final visitsThisYear = records
        .where((record) => record.receptionStartTime.year == now.year)
        .length;
    final upcoming = records
        .where((record) => record.receptionStartTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.receptionStartTime.compareTo(b.receptionStartTime));
    final completed = records
        .where((record) => !record.receptionStartTime.isAfter(now))
        .toList()
      ..sort((a, b) => b.receptionStartTime.compareTo(a.receptionStartTime));

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name.isEmpty ? '안녕하세요!' : '${session.name}님, 환영합니다.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CDSSentials 서비스를 이용 중입니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475467),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoCard(
            title: '계정 정보',
            onTap: () => _handleProfileTap(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: '계정 ID', value: session.accountId),
                const SizedBox(height: 8),
                _InfoRow(label: '환자 번호', value: session.patientId),
                const SizedBox(height: 8),
                _InfoRow(label: '이메일', value: session.email),
                const SizedBox(height: 8),
                _InfoRow(label: '전화번호', value: session.phone),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SummaryGrid(
            visitsThisYear: visitsThisYear,
            recentRecord: completed.isNotEmpty ? completed.first : null,
            upcomingRecord: upcoming.isNotEmpty ? upcoming.first : null,
          ),
          const SizedBox(height: 20),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB42318),
                ),
              ),
            )
          else ...[
            Text(
              '최근 진료 기록',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '최근 진료 기록이 없습니다.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Column(
                children: records.take(3).map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordTile(record: record),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.onTap});

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onTap != null)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: '상세 보기',
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475467),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.visitsThisYear,
    required this.recentRecord,
    required this.upcomingRecord,
  });

  final int visitsThisYear;
  final MedicalRecord? recentRecord;
  final MedicalRecord? upcomingRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      _SummaryCard(
        icon: Icons.calendar_month_outlined,
        label: '올해 방문',
        value: '$visitsThisYear회',
      ),
      _SummaryCard(
        icon: Icons.local_hospital_outlined,
        label: '최근 진료과',
        value: recentRecord?.department.isNotEmpty == true
            ? recentRecord!.department
            : '기록 없음',
      ),
      _SummaryCard(
        icon: Icons.assignment_turned_in_outlined,
        label: '최근 진료 상태',
        value: recentRecord != null
            ? recentRecord!.statusLabel
            : '상태 정보 없음',
      ),
      _SummaryCard(
        icon: Icons.event_available_outlined,
        label: '다가오는 일정',
        value: upcomingRecord != null
            ? upcomingRecord!.visitDateLabel
            : '예정 없음',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: cards.map((card) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8FF),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                card.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475467),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 3,
                softWrap: true,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.department.isEmpty ? '진료 정보 없음' : record.department,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                record.visitDateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '상태: ${record.statusLabel}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475467),
            ),
          ),
          if (record.notesLabel.isNotEmpty && record.notesLabel != '메모 없음')
            Text(
              record.notesLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475467),
              ),
            ),
        ],
      ),
    );
  }
}
