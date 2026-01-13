class Doctor {
  const Doctor({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.doctorId,
    required this.department,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String doctorId;
  final String department;

  static const Map<String, String> _departmentLabels = {
    'respiratory': '호흡기내과',
    'surgery': '외과',
    'cardiology': '심장내과',
    'orthopedics': '정형외과',
    'admin': '행정',
  };

  String get displayName {
    final hasNames = firstName.isNotEmpty || lastName.isNotEmpty;
    if (hasNames) {
      return '$lastName$firstName';
    }
    return username;
  }

  String get departmentLabel =>
      _departmentLabels[department] ?? department;

  static String labelForDepartment(String value) =>
      _departmentLabels[value] ?? value;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }
}
