import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String membershipId;
  final String committeeId;
  final int month;
  final int amount;
  final DateTime datePaid;
  final String markedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.membershipId,
    required this.committeeId,
    required this.month,
    required this.amount,
    required this.datePaid,
    required this.markedBy,
    required this.createdAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      membershipId: data['membershipId'] ?? '',
      committeeId: data['committeeId'] ?? '',
      month: data['month'] ?? 0,
      amount: data['amount'] ?? 0,
      datePaid: (data['datePaid'] as Timestamp?)?.toDate() ?? DateTime.now(),
      markedBy: data['markedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'membershipId': membershipId,
      'committeeId': committeeId,
      'month': month,
      'amount': amount,
      'datePaid': Timestamp.fromDate(datePaid),
      'markedBy': markedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Payment copyWith({
    int? month,
    int? amount,
    DateTime? datePaid,
    String? markedBy,
  }) {
    return Payment(
      id: id,
      membershipId: membershipId,
      committeeId: committeeId,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      datePaid: datePaid ?? this.datePaid,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt,
    );
  }
}