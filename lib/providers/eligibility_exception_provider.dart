import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/eligibility_exception_model.dart';

class EligibilityExceptionProvider extends ChangeNotifier {
  final CollectionReference _exceptionsRef =
  FirebaseFirestore.instance.collection('eligibilityExceptions');

  String? errorMessage;

  Future<bool> submitRequest(EligibilityExceptionModel request) async {
    try {
      final docRef = _exceptionsRef.doc();
      final withId = EligibilityExceptionModel(
        id: docRef.id,
        donorId: request.donorId,
        donorName: request.donorName,
        lastDonationDate: request.lastDonationDate,
        nextEligibleDate: request.nextEligibleDate,
        reason: request.reason,
        status: 'pending',
        createdAt: request.createdAt,
      );
      await docRef.set(withId.toMap());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // A donor's most recent exception request, so the UI can show them where
  // it stands (pending / approved / rejected with reason).
  Future<EligibilityExceptionModel?> fetchLatestForDonor(String donorId) async {
    try {
      final snapshot = await _exceptionsRef
          .where('donorId', isEqualTo: donorId)
          .get();
      if (snapshot.docs.isEmpty) return null;

      final results = snapshot.docs
          .map((doc) =>
          EligibilityExceptionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results.first;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  Future<List<EligibilityExceptionModel>> fetchPending() async {
    try {
      final snapshot =
      await _exceptionsRef.where('status', isEqualTo: 'pending').get();
      final results = snapshot.docs
          .map((doc) =>
          EligibilityExceptionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> approve(String id) async {
    try {
      await _exceptionsRef.doc(id).update({'status': 'approved'});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> reject(String id, String reason) async {
    try {
      await _exceptionsRef.doc(id).update({
        'status': 'rejected',
        'adminRejectionReason': reason,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}