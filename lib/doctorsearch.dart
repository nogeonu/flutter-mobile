import 'package:flutter/material.dart';

class Doctor {
  final int id;
  final String name;
  final String department;
  final String doctorId;
  final String userId;
  final String email;

  Doctor({
    required this.id,
    required this.name,
    required this.department,
    required this.doctorId,
    required this.userId,
    required this.email,
  });
}

class DoctorSearchMobile extends StatefulWidget {
  @override
  _DoctorSearchMobileState createState() => _DoctorSearchMobileState();
}

class _DoctorSearchMobileState extends State<DoctorSearchMobile> {
  final List<String> departments = [
    '전체',
    '외과',
    '호흡기내과',
  ];

  final List<Doctor> mockDoctors = [
    Doctor(id: 1, name: 'Dr. 김서연', department: '외과', doctorId: 'D20225001', userId: 'kim_sy', email: 'kim.seoyeon@hospital.com'),
    Doctor(id: 2, name: 'Dr. 박지훈', department: '외과', doctorId: 'D20225002', userId: 'park_jh', email: 'park.jihoon@hospital.com'),
    Doctor(id: 3, name: 'Dr. 이민지', department: '호흡기내과', doctorId: 'D20225003', userId: 'lee_mj', email: 'lee.minji@hospital.com'),
    Doctor(id: 4, name: 'Dr. 최동욱', department: '호흡기내과', doctorId: 'D20225004', userId: 'choi_dw', email: 'choi.dongwook@hospital.com'),
  ];

  String selectedDepartment = '전체';
  String searchQuery = '';
  Set<int> favorites = {};
  int _navIndex = 0;

  List<Doctor> get filteredDoctors {
    return mockDoctors.where((doctor) {
      final matchesDepartment = selectedDepartment == '전체' || doctor.department == selectedDepartment;
      final matchesSearch = searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          doctor.department.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesDepartment && matchesSearch;
    }).toList();
  }

  void toggleFavorite(int id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CDSSentials', style: theme.textTheme.headlineMedium),
                  SizedBox(height: 8),
                  Text('원하는 진료과와 의료진을 찾아보세요', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 4),
                  Text('호흡기내과와 외과에 소속된 의료진 정보를\n실시간으로 확인할 수 있습니다', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDepartment,
                    decoration: InputDecoration(labelText: '진료과 선택'),
                    items: departments.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartment = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '의료진 검색',
                      prefixIcon: Icon(Icons.search),
                      hintText: '의료진 이름, 이메일 또는 doctor_id로 검색해주세요.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('$selectedDepartment 의료진 (${filteredDoctors.length}명)', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                                      child: Text(doctor.department, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Doctor ID : ${doctor.doctorId}', style: TextStyle(color: Colors.grey[600])),
                                Text('아이디 : ${doctor.userId}', style: TextStyle(color: Colors.grey[600])),
                                Text('이메일 : ${doctor.email}', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                                        child: Text('진료예약 문의',style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        favorites.contains(doctor.id) ? Icons.favorite : Icons.favorite_border,
                                        color: favorites.contains(doctor.id) ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => toggleFavorite(doctor.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '메인화면'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), label: '나의검사'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: '건강알림'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '로그인'),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _navIndex = index;
          });
          if (index == 0) {
            // 메인화면으로 돌아가기
            Navigator.of(context).maybePop();
          }
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: const Color(0xFF9AA4B2),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
      ),

    );
  }
}
