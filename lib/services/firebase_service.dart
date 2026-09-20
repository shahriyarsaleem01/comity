import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    
    if (kDebugMode) {
      print('Firebase initialized');
    }
  }

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Auth methods
  Future<ConfirmationResult> signInWithPhoneNumber(String phoneNumber) async {
    final confirmation = await _auth.signInWithPhoneNumber(phoneNumber);
    return confirmation;
  }

  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User document methods
  Future<void> createUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot> getUserDocumentStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Committee methods
  Future<String> createCommittee(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('committees').add(data);
    return docRef.id;
  }

  Future<void> updateCommittee(String committeeId, Map<String, dynamic> data) async {
    await _firestore.collection('committees').doc(committeeId).update(data);
  }

  Future<DocumentSnapshot> getCommittee(String committeeId) async {
    return await _firestore.collection('committees').doc(committeeId).get();
  }

  Stream<DocumentSnapshot> getCommitteeStream(String committeeId) {
    return _firestore.collection('committees').doc(committeeId).snapshots();
  }

  Stream<QuerySnapshot> getCommitteesByOrganizer(String organizerId) {
    return _firestore
        .collection('committees')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getCommitteeByCode(String committeeCode) async {
    return await _firestore
        .collection('committees')
        .where('committeeCode', isEqualTo: committeeCode)
        .limit(1)
        .get();
  }

  // Membership methods
  Future<String> createMembership(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('memberships').add(data);
    return docRef.id;
  }

  Future<void> updateMembership(String membershipId, Map<String, dynamic> data) async {
    await _firestore.collection('memberships').doc(membershipId).update(data);
  }

  Future<DocumentSnapshot> getMembership(String membershipId) async {
    return await _firestore.collection('memberships').doc(membershipId).get();
  }

  Stream<QuerySnapshot> getMembershipsByCommittee(String committeeId) {
    return _firestore
        .collection('memberships')
        .where('committeeId', isEqualTo: committeeId)
        .orderBy('payoutPosition')
        .snapshots();
  }

  Stream<QuerySnapshot> getMembershipsByUser(String userId) {
    return _firestore
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<QuerySnapshot> getMembershipByCommitteeAndUser(
    String committeeId,
    String userId,
  ) async {
    return await _firestore
        .collection('memberships')
        .where('committeeId', isEqualTo: committeeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
  }

  Stream<DocumentSnapshot> getMembershipStream(String membershipId) {
    return _firestore.collection('memberships').doc(membershipId).snapshots();
  }

  // Payment methods
  Future<String> createPayment(Map<String, dynamic> data) async {
    final docRef = await _firestore.collection('payments').add(data);
    return docRef.id;
  }

  Future<void> updatePayment(String paymentId, Map<String, dynamic> data) async {
    await _firestore.collection('payments').doc(paymentId).update(data);
  }

  Stream<QuerySnapshot> getPaymentsByMembership(String membershipId) {
    return _firestore
        .collection('payments')
        .where('membershipId', isEqualTo: membershipId)
        .orderBy('month')
        .snapshots();
  }

  Stream<QuerySnapshot> getPaymentsByCommitteeAndMonth(
    String committeeId,
    int month,
  ) {
    return _firestore
        .collection('payments')
        .where('committeeId', isEqualTo: committeeId)
        .where('month', isEqualTo: month)
        .snapshots();
  }

  Future<QuerySnapshot> getPaymentByMembershipAndMonth(
    String membershipId,
    int month,
  ) async {
    return await _firestore
        .collection('payments')
        .where('membershipId', isEqualTo: membershipId)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();
  }

  // Batch operations
  WriteBatch batch() => _firestore.batch();

  Future<void> commitBatch(WriteBatch batch) => batch.commit();
}