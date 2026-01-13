class PatientProfile {
  const PatientProfile({
    required this.patientId,
    required this.accountId,
    required this.name,
    this.birthDate,
    this.gender,
    this.phone,
    this.bloodType,
    this.address,
    this.emergencyContact,
    this.medicalHistory,
    this.allergies,
    this.age,
  });

  final String patientId;
  final String accountId;
  final String name;
  final DateTime? birthDate;
  final String? gender;
  final String? phone;
  final String? bloodType;
  final String? address;
  final String? emergencyContact;
  final String? medicalHistory;
  final String? allergies;
  final int? age;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    DateTime? birth;
    final birthValue = json['birth_date'];
    if (birthValue is String && birthValue.isNotEmpty) {
      birth = DateTime.tryParse(birthValue);
    }

    return PatientProfile(
      patientId: json['patient_id'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthDate: birth,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      bloodType: json['blood_type'] as String?,
      address: json['address'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      medicalHistory: json['medical_history'] as String?,
      allergies: json['allergies'] as String?,
      age: json['age'] as int?,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    final upperGender =
        gender == null || gender!.isEmpty ? null : gender!.toUpperCase();
    return {
      'name': name,
      'birth_date': birthDate == null
          ? null
          : '${birthDate!.year.toString().padLeft(4, '0')}-'
              '${birthDate!.month.toString().padLeft(2, '0')}-'
              '${birthDate!.day.toString().padLeft(2, '0')}',
      'gender': upperGender,
      'phone': phone ?? '',
      'blood_type': bloodType ?? '',
      'address': address ?? '',
      'emergency_contact': emergencyContact ?? '',
      'medical_history': medicalHistory ?? '',
      'allergies': allergies ?? '',
    };
  }

  PatientProfile copyWith({
    String? name,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? bloodType,
    String? address,
    String? emergencyContact,
    String? medicalHistory,
    String? allergies,
  }) {
    return PatientProfile(
      patientId: patientId,
      accountId: accountId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      age: age,
    );
  }
}

