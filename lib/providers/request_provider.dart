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

  Future<bool> acceptRequest(
      String requestId, String donorId, String donorName, String? donorPhone) async {
    try {
      await _requestsRef.doc(requestId).update({
        'status': 'accepted',
        'donorId': donorId,
        'acceptedByName': donorName,
        'donorPhone': donorPhone,
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
}