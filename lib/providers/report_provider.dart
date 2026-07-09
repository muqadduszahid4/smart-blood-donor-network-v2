import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final CollectionReference _reportsRef =
  FirebaseFirestore.instance.collection('reports');

  String? errorMessage;

  Future<bool> submitReport(ReportModel report) async {
    try {
      final docRef = _reportsRef.doc();
      final withId = ReportModel(
        id: docRef.id,
        reporterId: report.reporterId,
        reporterName: report.reporterName,
        targetType: report.targetType,
        targetId: report.targetId,
        targetLabel: report.targetLabel,
        reason: report.reason,
        status: 'pending',
        createdAt: report.createdAt,
      );
      await docRef.set(withId.toMap());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<List<ReportModel>> fetchPendingReports() async {
    try {
      final snapshot =
      await _reportsRef.where('status', isEqualTo: 'pending').get();
      final results = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> dismissReport(String reportId) async {
    try {
      await _reportsRef.doc(reportId).update({'status': 'dismissed'});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> markActioned(String reportId) async {
    try {
      await _reportsRef.doc(reportId).update({'status': 'actioned'});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}