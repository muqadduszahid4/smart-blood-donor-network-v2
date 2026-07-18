class EligibilityExceptionModel {
  final String id;
  final String donorId;
  final String donorName;
  final DateTime lastDonationDate;
  final DateTime nextEligibleDate;
  final String reason; // donor's explanation for requesting early approval
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminRejectionReason;
  final DateTime createdAt;

  EligibilityExceptionModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.lastDonationDate,
    required this.nextEligibleDate,
    required this.reason,
    this.status = 'pending',
    this.adminRejectionReason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'lastDonationDate': lastDonationDate.toIso8601String(),
      'nextEligibleDate': nextEligibleDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'adminRejectionReason': adminRejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EligibilityExceptionModel.fromMap(Map<String, dynamic> map) {
    return EligibilityExceptionModel(
      id: map['id'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      lastDonationDate: map['lastDonationDate'] != null
          ? DateTime.parse(map['lastDonationDate'])
          : DateTime.now(),
      nextEligibleDate: map['nextEligibleDate'] != null
          ? DateTime.parse(map['nextEligibleDate'])
          : DateTime.now(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      adminRejectionReason: map['adminRejectionReason'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}