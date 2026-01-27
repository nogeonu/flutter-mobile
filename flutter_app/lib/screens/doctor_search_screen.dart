import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../services/doctor_repository.dart';
import 'doctor_detail_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final DoctorRepository _repository = DoctorRepository();
  final TextEditingController _searchController = TextEditingController();

  List<String> _departments = const ['전체'];
  List<Doctor> _allDoctors = const [];
  List<Doctor> _filteredDoctors = const [];
  String _selectedDepartment = '전체';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doctors = await _repository.fetchDoctors();
      final departments = <String>{'전체'};
      for (final doctor in doctors) {
        if (doctor.department.isNotEmpty) {
          departments.add(doctor.department);
        }
      }

      setState(() {
        _allDoctors = doctors;
        _departments = departments.toList();
      });
      _applyFilters();
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _allDoctors.where((doctor) {
      final matchesDepartment = _selectedDepartment == '전체'
          ? true
          : doctor.department == _selectedDepartment;
      final matchesQuery = query.isEmpty
          ? true
          : doctor.displayName.toLowerCase().contains(query) ||
              doctor.email.toLowerCase().contains(query) ||
              doctor.doctorId.toLowerCase().contains(query) ||
              doctor.username.toLowerCase().contains(query);
      return matchesDepartment && matchesQuery;
    }).toList();

    setState(() {
      _filteredDoctors = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctors = _filteredDoctors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('진료과 · 의료진'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.headlineMedium?.color,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DepartmentSelector(
              departments: _departments,
              selected: _selectedDepartment,
              onSelected: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
                _applyFilters();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '의료진 이름, 이메일, 계정 검색',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadDoctors,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (doctors.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '검색 조건에 맞는 의료진이 없습니다.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: doctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return _DoctorCard(
                      doctor: doctor,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DoctorDetailScreen(doctor: doctor),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, this.onTap});

  final Doctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        doctor.displayName.isEmpty ? '이름 미등록' : doctor.displayName;
    final department = doctor.department.isEmpty
        ? '진료과 미등록'
        : Doctor.labelForDepartment(doctor.department);
    final email =
        doctor.email.isEmpty ? '이메일 정보 없음' : doctor.email;
    final username =
        doctor.username.isEmpty ? '미등록' : doctor.username;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(department, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.3)),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: '의사 ID',
            value: doctor.doctorId,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.alternate_email,
            label: '이메일',
            value: email,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            label: '사용자 계정',
            value: username,
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartmentSelector extends StatelessWidget {
  const _DepartmentSelector({
    required this.departments,
    required this.selected,
    required this.onSelected,
  });

  final List<String> departments;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        offset: const Offset(0, 12),
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (context) => departments
            .map(
              (department) => PopupMenuItem<String>(
                value: department,
                child: Text(
                  department == '전체'
                      ? '전체'
                      : Doctor.labelForDepartment(department),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
            .toList(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selected == '전체'
                  ? '전체'
                  : Doctor.labelForDepartment(selected),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF1E2432),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF475467),
            ),
          ],
        ),
      ),
    );
  }
}
