class BloodCompatibility {
  // Standard ABO/Rh donor compatibility: which donor blood groups can
  // safely give blood to a recipient needing the given group.
  // Exact match is always listed first.
  static List<String> compatibleDonorGroupsFor(String neededGroup) {
    switch (neededGroup) {
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-'];
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+':
        return ['AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-'];
      case 'AB-':
        return ['AB-', 'A-', 'B-', 'O-'];
      default:
        return [neededGroup];
    }
  }

  static bool isExactMatch(String donorGroup, String neededGroup) {
    return donorGroup == neededGroup;
  }
}