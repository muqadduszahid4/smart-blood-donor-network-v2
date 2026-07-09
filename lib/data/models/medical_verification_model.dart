class MedicalVerificationModel {
  final String donorId;
  final double weight;
  final double height;
  final String bloodPressure;
  final Map<String, bool> healthAnswers;
  final String verificationStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime submittedAt;

  MedicalVerificationModel({
    required this.donorId,
    required this.weight,
    required this.height,
    required this.bloodPressure,
    required this.healthAnswers,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'weight': weight,
      'height': height,
      'bloodPressure': bloodPressure,
      'healthAnswers': healthAnswers,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory MedicalVerificationModel.fromMap(Map<String, dynamic> map) {
    return MedicalVerificationModel(
      donorId: map['donorId'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      bloodPressure: map['bloodPressure'] ?? '',
      healthAnswers: Map<String, bool>.from(map['healthAnswers'] ?? {}),
      verificationStatus: map['verificationStatus'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'])
          : DateTime.now(),
    );
  }

  static const List<String> healthQuestionKeys = [
    'donated_last_3_months',
    'diabetes',
    'hepatitis',
    'hiv_aids',
    'heart_disease',
    'taking_medication',
    'recent_surgery',
    'smokes',
    'consumes_alcohol',
  ];

  static const Map<String, String> healthQuestionLabels = {
    'donated_last_3_months': 'Have you donated blood in the last 3 months?',
    'diabetes': 'Do you have diabetes?',
    'hepatitis': 'Do you have hepatitis?',
    'hiv_aids': 'Do you have HIV/AIDS?',
    'heart_disease': 'Do you have heart disease?',
    'taking_medication': 'Are you taking any medication?',
    'recent_surgery': 'Have you had surgery recently?',
    'smokes': 'Do you smoke?',
    'consumes_alcohol': 'Do you consume alcohol?',
  };
}