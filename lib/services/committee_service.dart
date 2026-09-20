import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';
import '../models/committee.dart';
import '../models/membership.dart';
import '../models/payment.dart';

class CommitteeService {
  static final CommitteeService _instance = CommitteeService._internal();
  factory CommitteeService() => _instance;
  CommitteeService._internal();

  final FirebaseService _firebase = FirebaseService();
  final Uuid _uuid = const Uuid();

  FirebaseService get firebase => _firebase;

  String generateCommitteeCode() {
    return 'COM-${_uuid.v4().substring(0, 6).toUpperCase()}';
  }

  Future<Committee> createCommittee({
    required String name,
    required String organizerId,
    required int monthlyAmount,
    required int totalMembers,
    required DateTime startDate,
  }) async {
    final committeeCode = generateCommitteeCode();
    final totalMonths = totalMembers;

    final committee = Committee(
      id: '',
      name: name,
      organizerId: organizerId,
      monthlyAmount: monthlyAmount,
      totalMembers: totalMembers,
      startDate: startDate,
      totalMonths: totalMonths,
      currentMonthIndex: 0,
      status: 'draft',
      committeeCode: committeeCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docId = await _firebase.createCommittee(committee.toFirestore());
    final createdCommittee = committee.copyWith(
      // We can't easily update the id since it's immutable in the model
      // The caller should use the returned docId
    );

    return Committee(
      id: docId,
      name: committee.name,
      organizerId: committee.organizerId,
      monthlyAmount: committee.monthlyAmount,
      totalMembers: committee.totalMembers,
      startDate: committee.startDate,
      totalMonths: committee.totalMonths,
      currentMonthIndex: committee.currentMonthIndex,
      status: committee.status,
      committeeCode: committee.committeeCode,
      createdAt: committee.createdAt,
      updatedAt: committee.updatedAt,
    );
  }

  Future<void> startCommittee(String committeeId) async {
    await _firebase.updateCommittee(committeeId, {
      'status': 'active',
      'currentMonthIndex': 1,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> advanceMonth(String committeeId) async {
    final committeeDoc = await _firebase.getCommittee(committeeId);
    if (!committeeDoc.exists) return;

    final committee = Committee.fromFirestore(committeeDoc);
    final nextMonth = committee.currentMonthIndex + 1;

    if (nextMonth > committee.totalMonths) {
      await _firebase.updateCommittee(committeeId, {
        'status': 'completed',
        'currentMonthIndex': committee.totalMonths,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      await _firebase.updateCommittee(committeeId, {
        'currentMonthIndex': nextMonth,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  Future<Membership> addMember({
    required String committeeId,
    required String userId,
    required String displayName,
    required String phoneNumber,
    required int monthlyContribution,
    required int payoutPosition,
    required bool isOrganizer,
  }) async {
    final payoutMonth = payoutPosition;

    final membership = Membership(
      id: '',
      committeeId: committeeId,
      userId: userId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      monthlyContribution: monthlyContribution,
      payoutPosition: payoutPosition,
      payoutMonth: payoutMonth,
      payoutReceived: false,
      paidMonths: [],
      joinedAt: DateTime.now(),
      isOrganizer: isOrganizer,
    );

    final docId = await _firebase.createMembership(membership.toFirestore());

    return Membership(
      id: docId,
      committeeId: membership.committeeId,
      userId: membership.userId,
      displayName: membership.displayName,
      phoneNumber: membership.phoneNumber,
      monthlyContribution: membership.monthlyContribution,
      payoutPosition: membership.payoutPosition,
      payoutMonth: membership.payoutMonth,
      payoutReceived: membership.payoutReceived,
      paidMonths: membership.paidMonths,
      joinedAt: membership.joinedAt,
      isOrganizer: membership.isOrganizer,
    );
  }

  Future<void> updateMember(
    String membershipId, {
    String? displayName,
    String? phoneNumber,
    int? monthlyContribution,
    int? payoutPosition,
    int? payoutMonth,
    bool? payoutReceived,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (monthlyContribution != null) updates['monthlyContribution'] = monthlyContribution;
    if (payoutPosition != null) updates['payoutPosition'] = payoutPosition;
    if (payoutMonth != null) updates['payoutMonth'] = payoutMonth;
    if (payoutReceived != null) updates['payoutReceived'] = payoutReceived;
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await _firebase.updateMembership(membershipId, updates);
  }

  Future<void> updateMembership(String membershipId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firebase.updateMembership(membershipId, updates);
  }

  Future<void> markPayment({
    required String committeeId,
    required String membershipId,
    required int month,
    required int amount,
    required String markedBy,
  }) async {
    final batch = _firebase.batch();

    // Check if payment already exists
    final existing = await _firebase.getPaymentByMembershipAndMonth(membershipId, month);

    if (existing.docs.isNotEmpty) {
      final paymentDoc = existing.docs.first;
      batch.update(paymentDoc.reference, {
        'amount': amount,
        'datePaid': Timestamp.fromDate(DateTime.now()),
        'markedBy': markedBy,
      });
    } else {
      final payment = Payment(
        id: '',
        membershipId: membershipId,
        committeeId: committeeId,
        month: month,
        amount: amount,
        datePaid: DateTime.now(),
        markedBy: markedBy,
        createdAt: DateTime.now(),
      );
      final paymentRef = _firebase.firestore.collection('payments').doc();
      batch.set(paymentRef, payment.toFirestore());
    }

    // Update membership paidMonths
    final membershipDoc = await _firebase.getMembership(membershipId);
    if (membershipDoc.exists) {
      final membership = Membership.fromFirestore(membershipDoc);
      final paidMonths = List<int>.from(membership.paidMonths);
      if (!paidMonths.contains(month)) {
        paidMonths.add(month);
        paidMonths.sort();
        batch.update(membershipDoc.reference, {'paidMonths': paidMonths});
      }
    }

    await _firebase.commitBatch(batch);
  }

  Future<void> markPayoutReceived(String membershipId) async {
    await _firebase.updateMembership(membershipId, {
      'payoutReceived': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> unmarkPayment({
    required String membershipId,
    required int month,
  }) async {
    final batch = _firebase.batch();

    // Delete payment record
    final existing = await _firebase.getPaymentByMembershipAndMonth(membershipId, month);
    if (existing.docs.isNotEmpty) {
      batch.delete(existing.docs.first.reference);
    }

    // Update membership paidMonths
    final membershipDoc = await _firebase.getMembership(membershipId);
    if (membershipDoc.exists) {
      final membership = Membership.fromFirestore(membershipDoc);
      final paidMonths = List<int>.from(membership.paidMonths);
      paidMonths.remove(month);
      batch.update(membershipDoc.reference, {'paidMonths': paidMonths});
    }

    await _firebase.commitBatch(batch);
  }

  Stream<QuerySnapshot> getCommitteeMembersStream(String committeeId) {
    return _firebase.getMembershipsByCommittee(committeeId);
  }

  Future<QuerySnapshot> getCommitteeMembersOnce(String committeeId) async {
    return await _firebase.firestore
        .collection('memberships')
        .where('committeeId', isEqualTo: committeeId)
        .get();
  }

  Stream<QuerySnapshot> getPaymentsForMonthStream(String committeeId, int month) {
    return _firebase.getPaymentsByCommitteeAndMonth(committeeId, month);
  }

  Stream<QuerySnapshot> getMembershipsByUser(String userId) {
    return _firebase.getMembershipsByUser(userId);
  }

  Future<QuerySnapshot> getMembershipsByUserOnce(String userId) async {
    return await _firebase.firestore
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .get();
  }

  Future<int> getMonthlyPot(String committeeId) async {
    final committeeDoc = await _firebase.getCommittee(committeeId);
    if (!committeeDoc.exists) return 0;
    final committee = Committee.fromFirestore(committeeDoc);
    return committee.monthlyPot;
  }

  Future<int> getCollectedThisMonth(String committeeId, int month) async {
    final paymentsSnapshot = await _firebase.firestore
        .collection('payments')
        .where('committeeId', isEqualTo: committeeId)
        .where('month', isEqualTo: month)
        .get();

    int total = 0;
    for (final doc in paymentsSnapshot.docs) {
      total += (doc.data()['amount'] as int? ?? 0);
    }
    return total;
  }
}