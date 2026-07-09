import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/donor_model.dart';
import '../data/models/donation_model.dart';
import '../data/models/medical_verification_model.dart';

class DonorProvider extends ChangeNotifier {
  final CollectionReference _donorsRef =
  FirebaseFirestore.instance.collection('donors');

  bool isLoading = false;
  String? errorMessage;
  DonorModel? currentDonor;

  Future<bool> registerDonor(DonorModel donor) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _donorsRef.doc(donor.uid).set(donor.toMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firestore write timed out — check internet or Firestore rules'),
      );
      currentDonor = donor;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<DonorModel?> fetchDonorProfile(String uid) async {
    try {
      final doc = await _donorsRef.doc(uid).get();
      if (doc.exists) {
        currentDonor = DonorModel.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
        return currentDonor;
      }
      return null;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  Future<void> toggleAvailability(String uid, bool value) async {
    await _donorsRef.doc(uid).update({'isAvailable': value});
    if (currentDonor != null) {
      currentDonor = currentDonor!.copyWith(isAvailable: value);
      notifyListeners();
    }
  }

  Future<bool> deleteDonorProfile(String uid) async {
    try {
      await _donorsRef.doc(uid).delete();
      currentDonor = null;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<List<DonorModel>> fetchAllDonors() async {
    try {
      final snapshot = await _donorsRef.get();
      return snapshot.docs
          .map((doc) => DonorModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> toggleDonorActiveStatus(String uid, bool isActive) async {
    try {
      await _donorsRef.doc(uid).update({'isActive': isActive});
      if (currentDonor != null && currentDonor!.uid == uid) {
        currentDonor = currentDonor!.copyWith(isActive: isActive);
        notifyListeners();
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  final CollectionReference _donationsRef =
  FirebaseFirestore.instance.collection('donations');

  Future<bool> logDonation(DonationModel donation) async {
    try {
      final docRef = _donationsRef.doc();
      final donationWithId = DonationModel(
        id: docRef.id,
        donorId: donation.donorId,
        bloodGroup: donation.bloodGroup,
        date: donation.date,
        location: donation.location,
        requestId: donation.requestId,
        requesterId: donation.requesterId,
      );
      await docRef.set(donationWithId.toMap());

      await _donorsRef.doc(donation.donorId).update({
        'lastDonationDate': donation.date.toIso8601String(),
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<List<DonationModel>> fetchDonationHistory(String donorId) async {
    try {
      final snapshot =
      await _donationsRef.where('donorId', isEqualTo: donorId).get();
      final results = snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.date.compareTo(a.date));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  // ===== Medical verification =====
  final CollectionReference _medicalRef =
  FirebaseFirestore.instance.collection('medicalVerification');

  Future<bool> submitMedicalVerification(MedicalVerificationModel record) async {
    try {
      await _medicalRef.doc(record.donorId).set(record.toMap());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<MedicalVerificationModel?> fetchMedicalVerification(String donorId) async {
    try {
      final doc = await _medicalRef.doc(donorId).get();
      if (doc.exists) {
        return MedicalVerificationModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  Future<List<MedicalVerificationModel>> fetchPendingVerifications() async {
    try {
      final snapshot =
      await _medicalRef.where('verificationStatus', isEqualTo: 'pending').get();
      final results = snapshot.docs
          .map((doc) => MedicalVerificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> approveMedicalVerification(String donorId) async {
    try {
      await _medicalRef.doc(donorId).update({
        'verificationStatus': 'approved',
        'rejectionReason': null,
      });
      await _donorsRef.doc(donorId).update({'isMedicallyEligible': true});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectMedicalVerification(String donorId, String reason) async {
    try {
      await _medicalRef.doc(donorId).update({
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
      });
      await _donorsRef.doc(donorId).update({'isMedicallyEligible': false});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // ===== Favorites (persisted in Firestore, not just on-device) =====
  final CollectionReference _favoritesRef =
  FirebaseFirestore.instance.collection('favorites');

  String _favoriteDocId(String requesterId, String donorId) => '${requesterId}_$donorId';

  Future<bool> addFavoriteDonor(String requesterId, String donorId) async {
    try {
      await _favoritesRef.doc(_favoriteDocId(requesterId, donorId)).set({
        'requesterId': requesterId,
        'donorId': donorId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> removeFavoriteDonor(String requesterId, String donorId) async {
    try {
      await _favoritesRef.doc(_favoriteDocId(requesterId, donorId)).delete();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<Set<String>> fetchFavoriteDonorIds(String requesterId) async {
    try {
      final snapshot =
      await _favoritesRef.where('requesterId', isEqualTo: requesterId).get();
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['donorId'] as String)
          .toSet();
    } catch (e) {
      errorMessage = e.toString();
      return {};
    }
  }
}