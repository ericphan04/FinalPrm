import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../../../core/result/result.dart';

class FavoriteState {
  final List<String> favoriteIds;
  final bool isLoading;
  final String? error;

  FavoriteState({
    required this.favoriteIds,
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<String>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FavoriteController extends StateNotifier<FavoriteState> {
  final FavoriteRepository _repository;
  final String? _uid;

  FavoriteController(this._repository, this._uid)
      : super(FavoriteState(favoriteIds: [], isLoading: true)) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getFavorites(_uid);
    if (result is Success<List<String>>) {
      state = state.copyWith(favoriteIds: result.data, isLoading: false);
    } else if (result is Failure<List<String>>) {
      state = state.copyWith(error: result.failure.message, isLoading: false);
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final isFavorite = state.favoriteIds.contains(productId);
    
    // Optimistic update
    List<String> newFavorites = List.from(state.favoriteIds);
    if (isFavorite) {
      newFavorites.remove(productId);
    } else {
      newFavorites.add(productId);
    }
    state = state.copyWith(favoriteIds: newFavorites);

    Result<void> result;
    if (isFavorite) {
      result = await _repository.removeFavorite(_uid, productId);
    } else {
      result = await _repository.addFavorite(_uid, productId);
    }

    if (result is Failure<void>) {
      // Revert optimistic update and refresh
      state = state.copyWith(error: result.failure.message);
      await _loadFavorites();
    }
  }
  
  bool isFavorite(String productId) {
    return state.favoriteIds.contains(productId);
  }
}
