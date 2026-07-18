class RequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPhone;
  final String bloodGroup;
  final int units;
  final String hospitalName;
  final String? city;
  final String notes;
  final double latitude;
  final double longitude;
  final String status;
  final String? acceptedByName;
  final String? donorId;
  final String? donorPhone;
  final String? requesterMedicalStatus;
  final String? requesterMedicalRejectionReason;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhone,
    required this.bloodGroup,
    required this.units,
    required this.hospitalName,
    this.city,
    required this.notes,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    this.acceptedByName,
    this.donorId,
    this.donorPhone,
    this.requesterMedicalStatus,
    this.requesterMedicalRejectionReason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'bloodGroup': bloodGroup,
      'units': units,
      'hospitalName': hospitalName,
      'city': city,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'acceptedByName': acceptedByName,
      'donorId': donorId,
      'donorPhone': donorPhone,
      'requesterMedicalStatus': requesterMedicalStatus,
      'requesterMedicalRejectionReason': requesterMedicalRejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterPhone: map['requesterPhone'],
      bloodGroup: map['bloodGroup'] ?? '',
      units: map['units'] ?? 1,
      hospitalName: map['hospitalName'] ?? '',
      city: map['city'],
      notes: map['notes'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      status: map['status'] ?? 'active',
      acceptedByName: map['acceptedByName'],
      donorId: map['donorId'],
      donorPhone: map['donorPhone'],
      requesterMedicalStatus: map['requesterMedicalStatus'],
      requesterMedicalRejectionReason: map['requesterMedicalRejectionReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}