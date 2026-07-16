import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String uid);
  Future<void> updateProfile(UserProfile profile);
  Future<String> uploadAvatar(String uid, File imageFile);
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _cachedProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Simulate business rule / security rule constraint check
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
    // Simulate network upload delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Return the local file path as the URL for demonstration
    return imageFile.path;
  }
}

// Riverpod Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});
