import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/seller_application.dart';
import '../../data/repositories/seller_repository.dart';

class SellerApplicationState {
  final bool isLoading;
  final String? errorMessage;
  final SellerApplication? application;

  SellerApplicationState({
    this.isLoading = false,
    this.errorMessage,
    this.application,
  });

  SellerApplicationState copyWith({
    bool? isLoading,
    String? errorMessage,
    SellerApplication? application,
    bool clearApplication = false,
  }) {
    return SellerApplicationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      application: clearApplication ? null : (application ?? this.application),
    );
  }
}

class SellerApplicationController
    extends StateNotifier<SellerApplicationState> {
  final SellerRepository _repository;
  final String? _uid;

  SellerApplicationController(this._repository, this._uid)
    : super(SellerApplicationState()) {
    loadApplication();
  }

  Future<void> loadApplication() async {
    if (_uid == null || _uid!.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSellerApplication(_uid!);
    result.when(
      onSuccess: (app) {
        state = state.copyWith(isLoading: false, application: app);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  Future<bool> apply({
    required String storeName,
    required String phone,
    required String description,
    required String address,
  }) async {
    if (_uid == null || _uid!.isEmpty) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final app = SellerApplication(
      id: _uid!,
      storeName: storeName,
      phone: phone,
      description: description,
      address: address,
      status: SellerApplicationStatus.pending,
      createdAt: DateTime.now(),
    );

    final result = await _repository.applyForSeller(app);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, application: app);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }
}
