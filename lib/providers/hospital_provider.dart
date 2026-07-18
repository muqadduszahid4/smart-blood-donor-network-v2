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

  Future<List<HospitalModel>> fetchHospitalsByCity(String city) async {
    try {
      final snapshot = await _hospitalsRef.where('city', isEqualTo: city).get();
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

  Future<List<String>> fetchDistinctCities() async {
    try {
      final snapshot = await _hospitalsRef.get();
      final cities = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['city'] as String? ?? 'Unknown')
          .toSet()
          .toList();
      cities.sort();
      return cities;
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
        city: hospital.city,
        address: hospital.address,
        phone: hospital.phone,
        whatsapp: hospital.whatsapp,
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
  //
  // Every entry below has a verified phone number. Coordinates are set to
  // each city's general center — use "Edit" in Manage Hospitals to fine-tune
  // exact pins later using Google Maps coordinates.
  Future<bool> seedStarterHospitalsIfEmpty() async {
    try {
      final existing = await _hospitalsRef.limit(1).get();
      if (existing.docs.isNotEmpty) return false;

      final starterData = [
        // ================= ISLAMABAD =================
        HospitalModel(
          id: '', name: 'Pakistan Institute of Medical Sciences (PIMS)',
          type: 'hospital', city: 'Islamabad',
          address: 'Ibn-e-Sina Road, G-8/3, Islamabad',
          phone: '0519261170', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'PIMS Blood Bank',
          type: 'blood_bank', city: 'Islamabad',
          address: 'Ibn-e-Sina Road, G-8/3, Islamabad',
          phone: '0519260272', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Shifa International Hospital',
          type: 'hospital', city: 'Islamabad',
          address: 'Sector H-8/4, Islamabad',
          phone: '0518464646', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Ali Medical Centre',
          type: 'hospital', city: 'Islamabad',
          address: 'F-8 Markaz, Islamabad',
          phone: '0518090200', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Advanced International Hospital',
          type: 'hospital', city: 'Islamabad',
          address: 'Main Faisal Avenue, G-8/1, Islamabad',
          phone: '051111786005', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Maroof International Hospital',
          type: 'hospital', city: 'Islamabad',
          address: 'Service Road East, F-10 Markaz, Islamabad',
          phone: '051111644911', latitude: 33.6844, longitude: 73.0479,
          createdAt: DateTime.now(),
        ),

        // ================= RAWALPINDI =================
        HospitalModel(
          id: '', name: 'Holy Family Hospital',
          type: 'hospital', city: 'Rawalpindi',
          address: 'Holy Family Road, Block F, Satellite Town, Rawalpindi',
          phone: '0519290379', latitude: 33.5651, longitude: 73.0169,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Benazir Bhutto Hospital',
          type: 'hospital', city: 'Rawalpindi',
          address: 'Murree Road, near Chandni Chowk, Rawalpindi',
          phone: '0519290102', latitude: 33.5651, longitude: 73.0169,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'District Headquarter (DHQ) Hospital',
          type: 'hospital', city: 'Rawalpindi',
          address: 'Raja Bazar, Rawalpindi',
          phone: '0515556311', latitude: 33.5651, longitude: 73.0169,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Bilal Hospital',
          type: 'hospital', city: 'Rawalpindi',
          address: 'Satellite Town, Rawalpindi',
          phone: '0514853001', latitude: 33.5651, longitude: 73.0169,
          createdAt: DateTime.now(),
        ),

        // ================= KARACHI =================
        HospitalModel(
          id: '', name: 'Fatimid Foundation Blood Bank',
          type: 'blood_bank', city: 'Karachi',
          address: '393 Britto Road, Garden East, Karachi',
          phone: '02132225284', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Husaini Blood Bank',
          type: 'blood_bank', city: 'Karachi',
          address: 'Opp. Abbasi Shaheed Hospital, Tabish Dehlavi Road, Karachi',
          phone: '02137639502', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Burhani Blood Bank',
          type: 'blood_bank', city: 'Karachi',
          address: 'Saifee Road, Karachi',
          phone: '02156644490', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Aga Khan University Hospital',
          type: 'hospital', city: 'Karachi',
          address: 'Stadium Road, Karachi',
          phone: '02134861558', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Liaquat National Hospital',
          type: 'hospital', city: 'Karachi',
          address: 'Stadium Road, Karachi',
          phone: '02134412525', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Dow University Hospital — Regional Blood Center (Ojha Campus)',
          type: 'blood_bank', city: 'Karachi',
          address: 'University Road, Near SUPARCO Chowk, Karachi',
          phone: '02138771111', latitude: 24.8607, longitude: 67.0011,
          createdAt: DateTime.now(),
        ),

        // ================= FAISALABAD =================
        HospitalModel(
          id: '', name: 'Allied Hospital',
          type: 'hospital', city: 'Faisalabad',
          address: 'Jail Road, Faisalabad',
          phone: '0419210099', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'DHQ Hospital Faisalabad',
          type: 'hospital', city: 'Faisalabad',
          address: 'Mall Road, Faisalabad',
          phone: '0419200140', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Faisalabad Institute of Cardiology',
          type: 'hospital', city: 'Faisalabad',
          address: 'New Civil Lines, Sargodha Road, Faisalabad',
          phone: '0419201527', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Children Hospital & Institute of Child Health',
          type: 'hospital', city: 'Faisalabad',
          address: 'Jhang Road, near GC University New Campus, Faisalabad',
          phone: '0419203065', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Sundas Foundation Blood Bank',
          type: 'blood_bank', city: 'Faisalabad',
          address: 'Gulistan Colony No. 2, Faisalabad',
          phone: '0415388032', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Chiniot Blood Bank & Dialysis Centre',
          type: 'blood_bank', city: 'Faisalabad',
          address: '388 Jinnah Avenue, Jinnah Colony, Faisalabad',
          phone: '0412628868', latitude: 31.4187, longitude: 73.0791,
          createdAt: DateTime.now(),
        ),

        // ================= LAHORE =================
        HospitalModel(
          id: '', name: 'Husaini Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: '109 Habitat Villas, Jail Road, Shadman 2, Lahore',
          phone: '04237581067', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Sundas Foundation Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: '880-Shadman-I, near Crescent Model School, Lahore',
          phone: '04237539232', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Mayo Hospital',
          type: 'hospital', city: 'Lahore',
          address: 'Hospital Road, Anarkali Bazaar, Lahore',
          phone: '04299211129', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Jinnah Hospital Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: 'Maulana Shaukat Ali Road, Faisal Town, Lahore',
          phone: '04299231400', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Services Hospital Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: 'Shadman 1, Ghaus-ul-Azam (Jail) Road, Lahore',
          phone: '04299203402', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Lahore General Hospital Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: 'Main Ferozepur Road, near Chuhan Colony, Lahore',
          phone: '04299264091', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Sir Ganga Ram Hospital Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: "Shara-i-Fatima Jinnah, Queen's Road, Lahore",
          phone: '04299200572', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Shaikh Zayed Hospital',
          type: 'hospital', city: 'Lahore',
          address: 'University Avenue, Block D, Muslim Town, Lahore',
          phone: '04235865731', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Shaukat Khanum Memorial Cancer Hospital Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: '7A Block R-3, M.A. Johar Town, Lahore',
          phone: '04235905000', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Hameed Latif Hospital',
          type: 'hospital', city: 'Lahore',
          address: '14 New, Abu Bakar Block, Garden Town, Lahore',
          phone: '042111000043', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Ittefaq Hospital (Trust) Blood Bank',
          type: 'blood_bank', city: 'Lahore',
          address: 'Near H-Block Park, Model Town (Bahar Colony), Lahore',
          phone: '04235881981', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Aadil Hospital Blood Bank & Transfusion Centre',
          type: 'blood_bank', city: 'Lahore',
          address: 'Main Boulevard, DHA Phase 3, Lahore Cantt',
          phone: '042111223451', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Fatima Memorial Hospital Transfusion Service',
          type: 'blood_bank', city: 'Lahore',
          address: 'Shadman Road, Ichhra, Lahore',
          phone: '042111555600', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Evercare Hospital Lahore',
          type: 'hospital', city: 'Lahore',
          address: 'Near Khayaban-e-Jinnah, Wapda Town Phase 1, Lahore',
          phone: '042111227333', latitude: 31.5497, longitude: 74.3436,
          createdAt: DateTime.now(),
        ),

        // ================= MULTAN =================
        HospitalModel(
          id: '', name: 'Regional Blood Centre (RBC) Multan',
          type: 'blood_bank', city: 'Multan',
          address: 'Near MIKD, Muzaffargarh Road, Multan',
          phone: '0616354501', latitude: 30.1575, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Blood Bank — Nishtar Hospital Multan',
          type: 'blood_bank', city: 'Multan',
          address: 'Gate No. 3, Nishtar Medical College & Hospital, Nishtar Road, Multan',
          phone: '0619201288', latitude: 30.1575, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Indus Hospital — Multan Institute of Kidney Diseases',
          type: 'hospital', city: 'Multan',
          address: 'Multan-Muzaffargarh Road, Najarpur, Multan',
          phone: '0618048600', latitude: 30.1575, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Fatimid Foundation Multan Center',
          type: 'blood_bank', city: 'Multan',
          address: 'J-26, T Chowk, Shah Rukn-e-Alam Colony, Multan',
          phone: '0614554520', latitude: 30.1575, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Safe Blood Bank & Hematological Services',
          type: 'blood_bank', city: 'Multan',
          address: '1967 Aqsa Street, Hazoor Bagh Road, Multan',
          phone: '03006301473', latitude: 30.1575, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),

        // ================= PESHAWAR =================
        HospitalModel(
          id: '', name: 'Regional Blood Center (RBC) Peshawar',
          type: 'blood_bank', city: 'Peshawar',
          address: 'Near Burn Center, Phase 4, Hayatabad, Peshawar',
          phone: '0919217922', latitude: 34.0151, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Lady Reading Hospital (LRH) MTI',
          type: 'hospital', city: 'Peshawar',
          address: 'Soekarno Road, Pipal Mandi, near Qala Bala Hisar, Peshawar',
          phone: '0919211430', latitude: 34.0151, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Khyber Teaching Hospital (KTH) MTI',
          type: 'hospital', city: 'Peshawar',
          address: 'Main University Road, opposite University of Peshawar, Peshawar',
          phone: '0919224400', latitude: 34.0151, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Hayatabad Medical Complex (HMC)',
          type: 'hospital', city: 'Peshawar',
          address: 'Phase 4, Hayatabad, Peshawar',
          phone: '0919217140', latitude: 34.0151, longitude: 71.5249,
          createdAt: DateTime.now(),
        ),

        // ================= HYDERABAD =================
        HospitalModel(
          id: '', name: 'Liaquat University Hospital (LUH) Blood Bank',
          type: 'hospital', city: 'Hyderabad',
          address: 'Hospital Road, Station Road Area, Hyderabad',
          phone: '0229210207', latitude: 25.3960, longitude: 68.3578,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Aga Khan Maternal and Child Care Centre',
          type: 'hospital', city: 'Hyderabad',
          address: 'Plot No. 4, Block D, Unit No. 7, Latifabad, Hyderabad',
          phone: '0223812160', latitude: 25.3960, longitude: 68.3578,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Rajputana Hospital Blood Bank',
          type: 'blood_bank', city: 'Hyderabad',
          address: 'Collector House Road, Civil Lines, Hyderabad',
          phone: '0222782735', latitude: 25.3960, longitude: 68.3578,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Bone Care Hospital & Blood Bank',
          type: 'blood_bank', city: 'Hyderabad',
          address: "Near Saint Mary's School, Heerabad, Hyderabad",
          phone: '0222618151', latitude: 25.3960, longitude: 68.3578,
          createdAt: DateTime.now(),
        ),
        HospitalModel(
          id: '', name: 'Asian Institute of Medical Sciences (AIMS) Hospital Blood Bank',
          type: 'hospital', city: 'Hyderabad',
          address: 'AIMS Hospital Road, Hala Naka, Hyderabad',
          phone: '0222410141', latitude: 25.3960, longitude: 68.3578,
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