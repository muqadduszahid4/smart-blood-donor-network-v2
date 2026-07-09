import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/hospital_model.dart';

class HospitalProvider extends ChangeNotifier {
  final CollectionReference _hospitalsRef =
  FirebaseFirestore.instance.collection('hospitals');

  bool isLoading = false;
  String? errorMessage;

  Future<List<HospitalModel>> fetchAllHospitals() async {
    try {
      final snapshot = await _hospitalsRef.get();
      final results = snapshot.docs
          .map((doc) => HospitalModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      results.sort((a, b) => a.name.compareTo(b.name));
      return results;
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> addHospital(HospitalModel hospital) async {
    try {
      final docRef = _hospitalsRef.doc();
      final withId = HospitalModel(
        id: docRef.id,
        name: hospital.name,
        type: hospital.type,
        address: hospital.address,
        phone: hospital.phone,
        latitude: hospital.latitude,
        longitude: hospital.longitude,
        createdAt: hospital.createdAt,
      );
      await docRef.set(withId.toMap());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateHospital(HospitalModel hospital) async {
    try {
      await _hospitalsRef.doc(hospital.id).set(hospital.toMap());
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteHospital(String id) async {
    try {
      await _hospitalsRef.doc(id).delete();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // One-time helper: only adds starter data if the collection is currently
  // empty, so it can never create duplicates if run more than once.
  Future<bool> seedStarterHospitalsIfEmpty() async {
    try {
      final existing = await _hospitalsRef.limit(1).get();
      if (existing.docs.isNotEmpty) return false; // already has data, do nothing

      final starterData = [
        HospitalModel(
          id: '',
          name: 'Allied Hospital',
          type: 'hospital',
          address: 'Jail Road, Faisalabad',
          phone: '0419210099',
          latitude: 31.4136,
          longitude: 73.0788,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '',
          name: 'DHQ Hospital Faisalabad',
          type: 'hospital',
          address: 'Mall Road, Faisalabad',
          phone: '0419200140',
          latitude: 31.4210,
          longitude: 73.0948,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '',
          name: 'Faisalabad Institute of Cardiology',
          type: 'hospital',
          address: 'New Civil Lines, Sargodha Road, Faisalabad',
          phone: '0419201527',
          latitude: 31.4228,
          longitude: 73.0865,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '',
          name: 'PIMS Hospital',
          type: 'hospital',
          address: 'G-8/3, Islamabad',
          phone: '0519261170',
          latitude: 33.6935,
          longitude: 73.0468,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '',
          name: 'Sundas Foundation Blood Bank',
          type: 'blood_bank',
          address: 'Gulistan Colony No. 2, Faisalabad',
          phone: '0415388032',
          latitude: 31.4020,
          longitude: 73.0790,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '',
          name: 'Fatimid Foundation Blood Bank',
          type: 'blood_bank',
          address: '72-A, Block D2, Johar Town, Lahore',
          phone: '04235210834',
          latitude: 31.4697,
          longitude: 74.2728,
          createdAt: DateTime.now(),
        ),
      ];

      for (final hospital in starterData) {
        await addHospital(hospital);
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}