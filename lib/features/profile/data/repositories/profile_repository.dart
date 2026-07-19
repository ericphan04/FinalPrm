import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<UserProfile> getProfile(String uid) async {
    if (uid.trim().isEmpty) {
      throw Exception('ID người dùng không hợp lệ.');
    }

    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final email = currentUser?.email ?? '';
      final displayName = currentUser?.displayName ?? '';

      String role = 'user';
      if (email.startsWith('admin') || email.contains('admin@')) {
        role = 'admin';
      } else if (email.startsWith('seller') || email.contains('seller@')) {
        role = 'seller';
      } else if (email.startsWith('guest') || email.contains('guest@')) {
        role = 'guest';
      }

      final initialDisplayName = displayName.isNotEmpty
          ? displayName
          : (email.isNotEmpty ? email.split('@')[0] : 'Người dùng mới');

      final newProfileMap = {
        'uid': uid,
        'email': email,
        'displayName': initialDisplayName,
        'phone': '',
        'avatarUrl': currentUser?.photoURL ?? '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(newProfileMap);

      return UserProfile(
        uid: uid,
        email: email,
        displayName: initialDisplayName,
        phone: '',
        avatarUrl: currentUser?.photoURL ?? '',
      );
    }

    final data = doc.data()!;
    return UserProfile.fromMap(data);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (profile.uid.trim().isEmpty) {
      throw Exception('ID người dùng không hợp lệ.');
    }
    if (profile.displayName.trim().isEmpty) {
      throw Exception('Tên hiển thị không được để trống.');
    }
    if (profile.phone.trim().isEmpty || profile.phone.length < 10) {
      throw Exception('Số điện thoại không hợp lệ (tối thiểu 10 số).');
    }

    final docRef = _firestore.collection('users').doc(profile.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': profile.uid,
        'email': profile.email,
        'displayName': profile.displayName,
        'phone': profile.phone,
        'avatarUrl': profile.avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({
        'displayName': profile.displayName,
        'phone': profile.phone,
        'avatarUrl': profile.avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<String> uploadAvatar(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('avatar.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      AppLogger.error('Lỗi Firebase Storage khi tải ảnh đại diện', e);
      throw Exception(
        'Dịch vụ Firebase Storage chưa được kích hoạt trên Firebase Console. Vui lòng truy cập Firebase Console -> Storage -> nhấn "Get Started" để kích hoạt dịch vụ tải ảnh.',
      );
    } catch (e) {
      AppLogger.error('Lỗi không xác định khi tải ảnh đại diện', e);
      rethrow;
    }
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
