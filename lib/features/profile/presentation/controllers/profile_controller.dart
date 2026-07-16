import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileState {
  final UserProfile profile;
  final bool isLoading;
  final String? errorMessage;
  final bool isSaveSuccess;

  ProfileState({
    required this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.isSaveSuccess = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    bool? isSaveSuccess,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSaveSuccess: isSaveSuccess ?? this.isSaveSuccess,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String _uid = 'user_123'; // Hardcoded for demo/sprint 0

  ProfileController(this._repository) : super(ProfileState(profile: UserProfile.empty())) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSaveSuccess: false);
    try {
      final profile = await _repository.getProfile(_uid);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin cá nhân: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile({required String displayName, required String phone}) async {
    // Validate inputs locally first
    if (displayName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tên hiển thị không được để trống.');
      return;
    }
    if (phone.trim().isEmpty || phone.length < 10) {
      state = state.copyWith(errorMessage: 'Số điện thoại không hợp lệ (tối thiểu 10 chữ số).');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSaveSuccess: false);
    try {
      final updatedProfile = state.profile.copyWith(
        displayName: displayName,
        phone: phone,
      );
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile, isLoading: false, isSaveSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSaveSuccess: false);
    try {
      final newAvatarUrl = await _repository.uploadAvatar(_uid, imageFile);
      final updatedProfile = state.profile.copyWith(avatarUrl: newAvatarUrl);
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile, isLoading: false, isSaveSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải ảnh đại diện lên: ${e.toString()}',
      );
    }
  }

  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSaveSuccess: false);
  }
}

// Riverpod Provider for ProfileController
final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileController(repository);
});
