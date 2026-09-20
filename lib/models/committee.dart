import 'package:cloud_firestore/cloud_firestore.dart';

class Committee {
  final String id;
  final String name;
  final String organizerId;
  final int monthlyAmount;
  final int totalMembers;
  final DateTime startDate;
  final int totalMonths;
  final int currentMonthIndex;
  final String status;
  final String committeeCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Committee({
    required this.id,
    required this.name,
    required this.organizerId,
    required this.monthlyAmount,
    required this.totalMembers,
    required this.startDate,
    required this.totalMonths,
    required this.currentMonthIndex,
    required this.status,
    required this.committeeCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Committee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Committee(
      id: doc.id,
      name: data['name'] ?? '',
      organizerId: data['organizerId'] ?? '',
      monthlyAmount: data['monthlyAmount'] ?? 0,
      totalMembers: data['totalMembers'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalMonths: data['totalMonths'] ?? 0,
      currentMonthIndex: data['currentMonthIndex'] ?? 0,
      status: data['status'] ?? 'draft',
      committeeCode: data['committeeCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'organizerId': organizerId,
      'monthlyAmount': monthlyAmount,
      'totalMembers': totalMembers,
      'startDate': Timestamp.fromDate(startDate),
      'totalMonths': totalMonths,
      'currentMonthIndex': currentMonthIndex,
      'status': status,
      'committeeCode': committeeCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Committee copyWith({
    String? name,
    int? monthlyAmount,
    int? totalMembers,
    DateTime? startDate,
    int? totalMonths,
    int? currentMonthIndex,
    String? status,
    String? committeeCode,
    DateTime? updatedAt,
  }) {
    return Committee(
      id: id,
      name: name ?? this.name,
      organizerId: organizerId,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      totalMembers: totalMembers ?? this.totalMembers,
      startDate: startDate ?? this.startDate,
      totalMonths: totalMonths ?? this.totalMonths,
      currentMonthIndex: currentMonthIndex ?? this.currentMonthIndex,
      status: status ?? this.status,
      committeeCode: committeeCode ?? this.committeeCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  int get monthlyPot => monthlyAmount * totalMembers;
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isDraft => status == 'draft';
}