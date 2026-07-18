import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/request_model.dart';
import '../core/services/notification_service.dart';

class RequestProvider extends ChangeNotifier {
  final CollectionReference _requestsRef =
  FirebaseFirestore.instance.collection('requests');

  bool isLoading = false;
  String? errorMessage;
  List<RequestModel> requests = [];

  Future<bool> createRequest(RequestModel request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final docRef = _requestsRef.doc();
      final requestWithId = RequestModel(
        id: docRef.id,
        requesterId: request.requesterId,
        requesterName: request.requesterName,
        requesterPhone: request.requesterPhone,
        bloodGroup: request.bloodGroup,
        units: request.units,
        hospitalName: request.hospitalName,
        city: request.city,
        notes: request.notes,
        latitude: request.latitude,
        longitude: request.longitude,
        status: request.status,
        createdAt: request.createdAt,
      );

      await docRef.set(requestWithId.toMap()).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request save timed out — check internet connection'),
      );

      await NotificationService.showNotification(
        title: 'Emergency request sent',
        body:
        '${request.bloodGroup} needed at ${request.hospitalName} — nearby donors will be alerted',
      );

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

  Future<List<RequestModel>> fetchActiveRequests() async {
    try {
      final snapshot = await _requestsRef
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 10));

      requests = snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      return requests;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<void> markFulfilled(String requestId) async {
    await _requestsRef.doc(requestId).update({'status': 'fulfilled'});
  }

  Future<List<RequestModel>> fetchMyRequests(String uid) async {
    try {
      final snapshot = await _requestsRef
          .where('requesterId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 10));

      final results = snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      errorMessage = null;
      notifyListeners();
      return results;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({'status': 'cancelled'});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).delete();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // Requester edits their own request's details while it's still
  // pending admin approval or active and not yet accepted by a donor.
  Future<bool> updateRequest({
    required String requestId,
    required String bloodGroup,
    required int units,
    required String hospitalName,
    String? city,
    String? requesterPhone,
    required String notes,
  }) async {
    try {
      await _requestsRef.doc(requestId).update({
        'bloodGroup': bloodGroup,
        'units': units,
        'hospitalName': hospitalName,
        'city': city,
        'requesterPhone': requesterPhone,
        'notes': notes,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> acceptRequest(
      String requestId, String donorId, String donorName, String? donorPhone) async {
    try {
      await _requestsRef.doc(requestId).update({
        'status': 'accepted',
        'donorId': donorId,
        'acceptedByName': donorName,
        'donorPhone': donorPhone,
        'requesterMedicalStatus': 'pending',
        'requesterMedicalRejectionReason': null,
      });
      await NotificationService.showNotification(
        title: 'Request accepted ✅',
        body: '$donorName has accepted your blood request',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<List<RequestModel>> fetchMyAcceptedRequests(String donorId) async {
    try {
      final snapshot = await _requestsRef
          .where('donorId', isEqualTo: donorId)
          .where('status', isEqualTo: 'accepted')
          .get()
          .timeout(const Duration(seconds: 10));

      final results = snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> markRequestCompleted(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({'status': 'completed'});
      await NotificationService.showNotification(
        title: 'Donation completed 🎉',
        body: 'Thank you! This request has been marked as fulfilled.',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> approveRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({'status': 'active'});
      await NotificationService.showNotification(
        title: 'Request approved',
        body: 'Your blood request is now visible to nearby donors',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({'status': 'rejected'});
      await NotificationService.showNotification(
        title: 'Request rejected',
        body: 'Your blood request was not approved. Please check the details and try again.',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<List<RequestModel>> fetchPendingRequests() async {
    try {
      final snapshot = await _requestsRef
          .where('status', isEqualTo: 'pending')
          .get()
          .timeout(const Duration(seconds: 10));

      final results = snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  // ===== Requester-level review of the donor's (already admin-approved)
  // medical report, specific to this one request =====

  Future<bool> approveMedicalByRequester(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({
        'requesterMedicalStatus': 'approved',
        'requesterMedicalRejectionReason': null,
      });
      await NotificationService.showNotification(
        title: 'Medical report approved',
        body: 'The requester approved your medical report.',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectMedicalByRequester(String requestId, String reason) async {
    try {
      await _requestsRef.doc(requestId).update({
        'requesterMedicalStatus': 'rejected',
        'requesterMedicalRejectionReason': reason,
      });
      await NotificationService.showNotification(
        title: 'Medical report needs changes',
        body: 'The requester asked you to review and update your medical report.',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // Donor calls this after updating their health info in response to a
  // requester's rejection — sends it back to that SAME requester only,
  // never re-enters the admin approval queue.
  Future<bool> resubmitMedicalToRequester(String requestId) async {
    try {
      await _requestsRef.doc(requestId).update({
        'requesterMedicalStatus': 'pending',
        'requesterMedicalRejectionReason': null,
      });
      await NotificationService.showNotification(
        title: 'Medical report resubmitted',
        body: 'Your updated medical report has been sent to the requester for review.',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}