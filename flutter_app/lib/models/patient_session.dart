class PatientSession {
  const PatientSession({
    required this.accountId,
    required this.patientId,
    required this.name,
    required this.email,
    required this.phone,
    this.patientPk,
  });

  final String accountId;
  final String patientId;
  final String name;
  final String email;
  final String phone;
  final int? patientPk;

  PatientSession copyWith({
    String? accountId,
    String? patientId,
    String? name,
    String? email,
    String? phone,
    int? patientPk,
  }) {
    return PatientSession(
      accountId: accountId ?? this.accountId,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      patientPk: patientPk ?? this.patientPk,
    );
  }
}
