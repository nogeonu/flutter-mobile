import 'package:flutter/material.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final List<String> _departments = const ['전체', '외과', '호흡기내과'];

  final List<Doctor> _mockDoctors = const [
    Doctor(
      id: 1,
      name: 'Dr. 김서연',
      department: '외과',
      doctorId: 'D20225001',
      userId: 'kim_sy',
      email: 'kim.seoyeon@hospital.com',
    ),
    Doctor(
      id: 2,
      name: 'Dr. 박지훈',
      department: '외과',
      doctorId: 'D20225002',
      userId: 'park_jh',
      email: 'park.jihoon@hospital.com',
    ),
    Doctor(
      id: 3,
      name: 'Dr. 이민지',
      department: '호흡기내과',
      doctorId: 'D20225003',
      userId: 'lee_mj',
      email: 'lee.minji@hospital.com',
    ),
    Doctor(
      id: 4,
      name: 'Dr. 최동욱',
      department: '호흡기내과',
      doctorId: 'D20225004',
      userId: 'choi_dw',
      email: 'choi.dongwook@hospital.com',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Doctor> get _filteredDoctors {
    final query = _searchController.text.toLowerCase();
    return _mockDoctors.where((doctor) {
      final matchesDepartment = _selectedDepartment == '전체'
          ? true
          : doctor.department == _selectedDepartment;
      final matchesQuery =
          doctor.name.toLowerCase().contains(query) ||
          doctor.email.toLowerCase().contains(query) ||
          doctor.doctorId.toLowerCase().contains(query);
      return matchesDepartment && matchesQuery;
    }).toList();
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
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '의료진 이름 또는 이메일 검색',
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
            if (doctors.isEmpty)
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
                    return _DoctorCard(doctor: doctor);
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
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
                      doctor.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(doctor.department, style: theme.textTheme.bodyMedium),
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
            value: doctor.email,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            label: '사용자 계정',
            value: doctor.userId,
          ),
        ],
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

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.department,
    required this.doctorId,
    required this.userId,
    required this.email,
  });

  final int id;
  final String name;
  final String department;
  final String doctorId;
  final String userId;
  final String email;
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
                child: Text(department, style: theme.textTheme.bodyMedium),
              ),
            )
            .toList(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selected,
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
