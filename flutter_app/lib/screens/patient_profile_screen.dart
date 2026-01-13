import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/patient_profile.dart';
import '../models/patient_session.dart';
import '../services/patient_repository.dart';
import '../state/app_state.dart';

const Map<String, String> _genderLabels = {
  'M': '남성',
  'F': '여성',
};

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key, required this.session});

  final PatientSession session;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final PatientRepository _repository = PatientRepository();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();

  PatientProfile? _profile;
  DateTime? _birthDate;
  String? _gender;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.fetchProfile(widget.session.accountId);
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _birthDate = profile.birthDate;
        _gender = _normalizeGender(profile.gender);
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
        _bloodTypeController.text = profile.bloodType ?? '';
        _addressController.text = profile.address ?? '';
        _emergencyContactController.text = profile.emergencyContact ?? '';
        _medicalHistoryController.text = profile.medicalHistory ?? '';
        _allergiesController.text = profile.allergies ?? '';
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = _profile;
    if (profile == null) return;

    final updated = profile.copyWith(
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      phone: _phoneController.text.trim(),
      bloodType: _bloodTypeController.text.trim(),
      address: _addressController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      allergies: _allergiesController.text.trim(),
    );

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = updated.toUpdateJson();
      final saved = await _repository.updateProfile(
        accountId: widget.session.accountId,
        payload: payload,
      );

      if (!mounted) return;
      setState(() {
        _profile = saved;
        _birthDate = saved.birthDate;
        _gender = _normalizeGender(saved.gender);
        _nameController.text = saved.name;
        _phoneController.text = saved.phone ?? '';
        _bloodTypeController.text = saved.bloodType ?? '';
        _addressController.text = saved.address ?? '';
        _emergencyContactController.text = saved.emergencyContact ?? '';
        _medicalHistoryController.text = saved.medicalHistory ?? '';
        _allergiesController.text = saved.allergies ?? '';
        _isSaving = false;
      });

      final currentSession = AppState.instance.session;
      if (currentSession != null &&
          currentSession.accountId == widget.session.accountId) {
        AppState.instance.updateSession(
          currentSession.copyWith(
            name: saved.name,
            phone: saved.phone ?? currentSession.phone,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSaving = false;
      });
    }
  }

  String? _normalizeGender(String? value) {
    if (value == null || value.isEmpty) return null;
    final upper = value.toUpperCase();
    if (_genderLabels.containsKey(upper)) {
      return upper;
    }
    for (final entry in _genderLabels.entries) {
      if (entry.value == value ||
          entry.value == value.toUpperCase() ||
          entry.value == value.toLowerCase()) {
        return entry.key;
      }
    }
    return upper;
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 정보'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _ErrorView(
                    message: _errorMessage!,
                    onRetry: _loadProfile,
                  )
                : _ProfileForm(
                    formKey: _formKey,
                    profile: _profile!,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    bloodTypeController: _bloodTypeController,
                    addressController: _addressController,
                    emergencyContactController: _emergencyContactController,
                    medicalHistoryController: _medicalHistoryController,
                    allergiesController: _allergiesController,
                    birthDate: _birthDate,
                    onPickBirthDate: _pickBirthDate,
                    gender: _gender,
                    onGenderChanged: (value) => setState(() => _gender = value),
                  ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.profile,
    required this.nameController,
    required this.phoneController,
    required this.bloodTypeController,
    required this.addressController,
    required this.emergencyContactController,
    required this.medicalHistoryController,
    required this.allergiesController,
    required this.birthDate,
    required this.onPickBirthDate,
    required this.gender,
    required this.onGenderChanged,
  });

  final GlobalKey<FormState> formKey;
  final PatientProfile profile;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController bloodTypeController;
  final TextEditingController addressController;
  final TextEditingController emergencyContactController;
  final TextEditingController medicalHistoryController;
  final TextEditingController allergiesController;
  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: '기본 정보'),
            const SizedBox(height: 12),
            _ReadOnlyField(label: '환자 번호', value: profile.patientId),
            const SizedBox(height: 12),
            _ReadOnlyField(label: '계정 ID', value: profile.accountId),
            if (profile.age != null) ...[
              const SizedBox(height: 12),
              _ReadOnlyField(label: '나이', value: '${profile.age}세'),
            ],
            const SizedBox(height: 20),
            _EditableField(
              controller: nameController,
              label: '이름',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해 주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _BirthGenderRow(
              birthDate: birthDate,
              onPickBirthDate: onPickBirthDate,
              gender: gender,
              onGenderChanged: onGenderChanged,
            ),
            const SizedBox(height: 20),
            _EditableField(
              controller: phoneController,
              label: '전화번호',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _EditableField(
              controller: bloodTypeController,
              label: '혈액형',
              hintText: '예: A+, O-',
            ),
            const SizedBox(height: 16),
            _EditableField(
              controller: addressController,
              label: '주소',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _EditableField(
              controller: emergencyContactController,
              label: '비상 연락처',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _SectionHeader(label: '건강 정보'),
            const SizedBox(height: 12),
            _EditableField(
              controller: medicalHistoryController,
              label: '과거 병력',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _EditableField(
              controller: allergiesController,
              label: '알레르기',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BirthGenderRow extends StatelessWidget {
  const _BirthGenderRow({
    required this.birthDate,
    required this.onPickBirthDate,
    required this.gender,
    required this.onGenderChanged,
  });

  final DateTime? birthDate;
  final VoidCallback onPickBirthDate;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthLabel =
        birthDate == null ? '생년월일 선택' : DateFormat('yyyy-MM-dd').format(birthDate!);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onPickBirthDate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '생년월일',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      birthLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: gender,
            decoration: InputDecoration(
              labelText: '성별',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _genderLabels.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: onGenderChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '성별을 선택해 주세요.';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

