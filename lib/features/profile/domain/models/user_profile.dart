class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String avatarUrl;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.avatarUrl,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phone,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final rawDate = map['updatedAt'];
    if (rawDate != null) {
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      } else if (rawDate is DateTime) {
        parsedDate = rawDate;
      } else {
        // Handle Firestore Timestamp or dynamic types
        try {
          parsedDate = (rawDate as dynamic).toDate();
        } catch (_) {
          parsedDate = DateTime.tryParse(rawDate.toString());
        }
      }
    }

    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      updatedAt: parsedDate,
    );
  }

  // Initial empty/placeholder user profile for fallback states
  factory UserProfile.empty() {
    return UserProfile(
      uid: '',
      email: '',
      displayName: '',
      phone: '',
      avatarUrl: '',
      updatedAt: DateTime.now(),
    );
  }
}
