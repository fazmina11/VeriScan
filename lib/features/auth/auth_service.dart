import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Wraps Firebase Auth email/password and Firestore user profile operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current user (null if not logged in).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ──

  /// Sign up with email and password.
  Future<UserCredential> signUpWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(
      String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Firestore Profile ──

  /// Check if a user profile exists in Firestore.
  Future<bool> userProfileExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Save individual user profile.
  Future<void> saveIndividualProfile({
    required String uid,
    required String fullName,
    required bool locationEnabled,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'role': 'individual',
      'fullName': fullName,
      'locationEnabled': locationEnabled,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save professional user profile.
  Future<void> saveProfessionalProfile({
    required String uid,
    required String organizationName,
    required String licenseId,
    required String businessAddress,
    required String roleType,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'role': 'professional',
      'organizationName': organizationName,
      'licenseId': licenseId,
      'businessAddress': businessAddress,
      'roleType': roleType,
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
