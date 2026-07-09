class DonorModel {
  final String uid;
  final String name;
  final String bloodGroup;
  final int age;
  final String gender;
  final String city;
  final double latitude;
  final double longitude;
  final String phone;
  final DateTime? lastDonationDate;
  final bool isAvailable;
  final bool isMedicallyEligible;
  final bool isActive;
  final DateTime createdAt;

  DonorModel({
    required this.uid,
    required this.name,
    required this.bloodGroup,
    required this.age,
    required this.gender,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.lastDonationDate,
    required this.isAvailable,
    required this.isMedicallyEligible,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'bloodGroup': bloodGroup,
      'age': age,
      'gender': gender,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'isAvailable': isAvailable,
      'isMedicallyEligible': isMedicallyEligible,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DonorModel.fromMap(Map<String, dynamic> map) {
    return DonorModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      city: map['city'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      phone: map['phone'] ?? '',
      lastDonationDate: map['lastDonationDate'] != null
          ? DateTime.parse(map['lastDonationDate'])
          : null,
      isAvailable: map['isAvailable'] ?? true,
      isMedicallyEligible: map['isMedicallyEligible'] ?? true,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  DonorModel copyWith({
    bool? isAvailable,
    bool? isActive,
  }) {
    return DonorModel(
      uid: uid,
      name: name,
      bloodGroup: bloodGroup,
      age: age,
      gender: gender,
      city: city,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      lastDonationDate: lastDonationDate,
      isAvailable: isAvailable ?? this.isAvailable,
      isMedicallyEligible: isMedicallyEligible,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  // Days until next eligible donation (56-day rule between whole blood donations)
  int daysUntilEligible() {
    if (lastDonationDate == null) return 0;
    final nextEligible = lastDonationDate!.add(const Duration(days: 56));
    final diff = nextEligible.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
}