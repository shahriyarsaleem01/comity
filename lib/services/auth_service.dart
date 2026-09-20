import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseService _firebase = FirebaseService();

  FirebaseService get firebase => _firebase;

  Future<void> initialize() async {
    await _firebase.initialize();
  }

  Future<void> sendOTP(String phoneNumber) async {
    await _firebase.auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (kDebugMode) {
          print('Auto-verification completed');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        if (kDebugMode) {
          print('Code sent to $phoneNumber, verificationId: $verificationId');
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (kDebugMode) {
          print('Code auto-retrieval timeout');
        }
      },
    );
  }

  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebase.auth.signInWithCredential(credential);
  }

  Future<AppUser?> getCurrentUserData() async {
    final user = _firebase.currentUser;
    if (user == null) return null;

    final doc = await _firebase.getUserDocument(user.uid);
    if (!doc.exists) return null;

    return AppUser.fromFirestore(doc);
  }

  Future<AppUser> createUserProfile({
    required String uid,
    required String phoneNumber,
    required String displayName,
    required String role,
  }) async {
    final appUser = AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firebase.createUserDocument(uid, appUser.toFirestore());
    return appUser;
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firebase.updateUserDocument(uid, {'role': role});
  }

  Future<void> addCommitteeToUser(String uid, String committeeId) async {
    final doc = await _firebase.getUserDocument(uid);
    if (!doc.exists) return;

    final userData = doc.data() as Map<String, dynamic>;
    final committeeIds = List<String>.from(userData['committeeIds'] ?? []);
    if (!committeeIds.contains(committeeId)) {
      committeeIds.add(committeeId);
      await _firebase.updateUserDocument(uid, {'committeeIds': committeeIds});
    }
  }

  Future<void> signOut() async {
    await _firebase.signOut();
  }

  Stream<AppUser?> get currentUserStream {
    return _firebase.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firebase.getUserDocument(user.uid);
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }
}