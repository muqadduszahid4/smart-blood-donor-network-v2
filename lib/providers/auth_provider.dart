import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  bool isLoading = false;
  String? errorMessage;

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Registration failed";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Login failed";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Reset failed";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? "Could not delete account";
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> saveUserProfile(String uid, String name, String email, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isActive': true,
    }, SetOptions(merge: true));
  }

  Future<String?> fetchUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Admin: fetch all users with a given role ('requester' or 'donor')
  Future<List<Map<String, dynamic>>> fetchUsersByRole(String role) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Unnamed user',
          'email': data['email'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  // Admin: disable a user's account access at the app level (does not delete Firebase Auth account)
  Future<bool> toggleUserActiveStatus(String uid, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'isActive': isActive}, SetOptions(merge: true));
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // ===== Self-service profile editing =====
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> updateUserProfile(
      String uid, String name, String phone, String city, String address) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'city': city,
        'address': address,
      }, SetOptions(merge: true));
      await _auth.currentUser?.updateDisplayName(name);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}