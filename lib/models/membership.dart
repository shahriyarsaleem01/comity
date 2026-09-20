import 'package:cloud_firestore/cloud_firestore.dart';

class Membership {
  final String id;
  final String committeeId;
  final String userId;
  final String displayName;
  final String phoneNumber;
  final int monthlyContribution;
  final int payoutPosition;
  final int payoutMonth;
  final bool payoutReceived;
  final List<int> paidMonths;
  final DateTime joinedAt;
  final bool isOrganizer;

  Membership({
    required this.id,
    required this.committeeId,
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
    required this.monthlyContribution,
    required this.payoutPosition,
    required this.payoutMonth,
    required this.payoutReceived,
    required this.paidMonths,
    required this.joinedAt,
    this.isOrganizer = false,
  });

  factory Membership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Membership(
      id: doc.id,
      committeeId: data['committeeId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      monthlyContribution: data['monthlyContribution'] ?? 0,
      payoutPosition: data['payoutPosition'] ?? 0,
      payoutMonth: data['payoutMonth'] ?? 0,
      payoutReceived: data['payoutReceived'] ?? false,
      paidMonths: List<int>.from(data['paidMonths'] ?? []),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOrganizer: data['isOrganizer'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'committeeId': committeeId,
      'userId': userId,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'monthlyContribution': monthlyContribution,
      'payoutPosition': payoutPosition,
      'payoutMonth': payoutMonth,
      'payoutReceived': payoutReceived,
      'paidMonths': paidMonths,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isOrganizer': isOrganizer,
    };
  }

  Membership copyWith({
    String? displayName,
    String? phoneNumber,
    int? monthlyContribution,
    int? payoutPosition,
    int? payoutMonth,
    bool? payoutReceived,
    List<int>? paidMonths,
    bool? isOrganizer,
  }) {
    return Membership(
      id: id,
      committeeId: committeeId,
      userId: userId,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      payoutPosition: payoutPosition ?? this.payoutPosition,
      payoutMonth: payoutMonth ?? this.payoutMonth,
      payoutReceived: payoutReceived ?? this.payoutReceived,
      paidMonths: paidMonths ?? this.paidMonths,
      joinedAt: joinedAt,
      isOrganizer: isOrganizer ?? this.isOrganizer,
    );
  }

  bool hasPaidMonth(int month) => paidMonths.contains(month);
  int get monthsPaid => paidMonths.length;
  bool get isFullyPaid => paidMonths.length >= payoutMonth;
}