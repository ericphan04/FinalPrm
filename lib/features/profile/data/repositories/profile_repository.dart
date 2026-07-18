import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String uid);
  Future<void> updateProfile(UserProfile profile);
  Future<String> uploadAvatar(String uid, File imageFile);
}

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<UserProfile> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('Không tìm thấy thông tin cá nhân của người dùng.');
    }
    final data = doc.data()!;
    return UserProfile.fromMap(data);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (profile.displayName.trim().isEmpty) {
      throw Exception('Tên hiển thị không được để trống.');
    }
    if (profile.phone.trim().isEmpty || profile.phone.length < 10) {
      throw Exception('Số điện thoại không hợp lệ (tối thiểu 10 số).');
    }

    await _firestore.collection('users').doc(profile.uid).update({
      'displayName': profile.displayName,
      'phone': profile.phone,
      'avatarUrl': profile.avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> uploadAvatar(String uid, File imageFile) async {
    final ref = _storage.ref().child('users').child(uid).child('avatar.jpg');
    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}

class MockProfileRepository implements ProfileRepository {
  // Simple local state to persist changes during the app run
  UserProfile _cachedProfile = const UserProfile(
    uid: 'user_123',
    email: 'hieu.nguyen@shoeapp.dev',
    displayName: 'Nguyễn Văn Hiếu',
    phone: '0987654321',
    avatarUrl: '', // Defaults to initials
  );

  @override
  Future<UserProfile> getProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _cachedProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (profile.displayName.trim().isEmpty) {
      throw Exception('Tên hiển thị không được để trống.');
    }
    if (profile.phone.trim().isEmpty || profile.phone.length < 10) {
      throw Exception('Số điện thoại không hợp lệ (tối thiểu 10 số).');
    }

    _cachedProfile = profile.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<String> uploadAvatar(String uid, File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return imageFile.path;
  }
}

// Riverpod Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});
