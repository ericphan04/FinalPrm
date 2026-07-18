import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/store_profile.dart';
import '../../data/repositories/seller_repository.dart';

class StoreProfileState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSaveSuccess;
  final StoreProfile? profile;

  StoreProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.isSaveSuccess = false,
    this.profile,
  });

  StoreProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSaveSuccess,
    StoreProfile? profile,
  }) {
    return StoreProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSaveSuccess: isSaveSuccess ?? this.isSaveSuccess,
      profile: profile ?? this.profile,
    );
  }
}

class StoreProfileController extends StateNotifier<StoreProfileState> {
  final SellerRepository _repository;
  final String? _uid;

  StoreProfileController(this._repository, this._uid)
    : super(StoreProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (_uid == null || _uid!.isEmpty) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSaveSuccess: false,
    );
    final result = await _repository.getStoreProfile(_uid!);
    result.when(
      onSuccess: (profile) {
        state = state.copyWith(isLoading: false, profile: profile);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String description,
    required String address,
    String logoUrl = '',
  }) async {
    if (_uid == null || _uid!.isEmpty) return false;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSaveSuccess: false,
    );

    final updatedProfile = StoreProfile(
      id: _uid!,
      name: name,
      phone: phone,
      description: description,
      address: address,
      logoUrl: logoUrl,
      createdAt: state.profile?.createdAt ?? DateTime.now(),
    );

    final result = await _repository.updateStoreProfile(updatedProfile);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          isSaveSuccess: true,
          profile: updatedProfile,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  void clearStatus() {
    state = state.copyWith(errorMessage: null, isSaveSuccess: false);
  }
}
