class DonationModel {
  final String id;
  final String donorId;
  final String bloodGroup;
  final DateTime date;
  final String? location;
  final String? requestId;
  final String? requesterId;

  DonationModel({
    required this.id,
    required this.donorId,
    required this.bloodGroup,
    required this.date,
    this.location,
    this.requestId,
    this.requesterId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'bloodGroup': bloodGroup,
      'date': date.toIso8601String(),
      'location': location,
      'requestId': requestId,
      'requesterId': requesterId,
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      location: map['location'],
      requestId: map['requestId'],
      requesterId: map['requesterId'],
    );
  }
}