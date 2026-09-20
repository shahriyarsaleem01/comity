import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String role;
  final DateTime createdAt;
  final List<String> committeeIds;

  AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.committeeIds = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      committeeIds: List<String>.from(data['committeeIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'committeeIds': committeeIds,
    };
  }

  AppUser copyWith({
    String? phoneNumber,
    String? displayName,
    String? role,
    List<String>? committeeIds,
  }) {
    return AppUser(
      uid: uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt,
      committeeIds: committeeIds ?? this.committeeIds,
    );
  }
}