class HospitalModel {
  final String id;
  final String name;
  final String type; // 'hospital' or 'blood_bank'
  final String city;
  final String address;
  final String phone;
  final String? whatsapp;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  HospitalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.address,
    required this.phone,
    this.whatsapp,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'city': city,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HospitalModel.fromMap(Map<String, dynamic> map) {
    return HospitalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'hospital',
      city: map['city'] ?? 'Unknown',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'],
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}