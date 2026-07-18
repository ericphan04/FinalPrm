import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_item.dart';
import '../../data/repositories/cart_repository.dart';
import 'package:uuid/uuid.dart';

class CartState {
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> items;

  CartState({this.isLoading = false, this.errorMessage, this.items = const []});

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartItem>? items,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
    );
  }

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

class CartController extends StateNotifier<CartState> {
  final CartRepository _repository;
  final String? _uid; // null if guest

  CartController(this._repository, this._uid) : super(CartState()) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getCartItems(_uid);
    result.when(
      onSuccess: (data) {
        state = state.copyWith(isLoading: false, items: data);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  Future<void> addToCart(CartItem item) async {
    // Generate an ID for guest cart items just in case, for user cart it will be removed by repo.
    final newItem = item.id.isEmpty
        ? item.copyWith(id: const Uuid().v4())
        : item;

    // Optimistic UI update
    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((i) => i.variantId == newItem.variantId);
    if (index >= 0) {
      newItems[index] = newItems[index].copyWith(
        quantity: newItems[index].quantity + newItem.quantity,
      );
    } else {
      newItems.add(newItem);
    }
    state = state.copyWith(items: newItems);

    final result = await _repository.addToCart(_uid, newItem);
    result.when(
      onSuccess: (_) {}, // already updated
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        _loadCart(); // revert
      },
    );
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      return removeFromCart(itemId);
    }

    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      newItems[index] = newItems[index].copyWith(quantity: quantity);
      state = state.copyWith(items: newItems);
    }

    final result = await _repository.updateQuantity(_uid, itemId, quantity);
    result.when(
      onSuccess: (_) {},
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        _loadCart(); // revert
      },
    );
  }

  Future<void> removeFromCart(String itemId) async {
    final newItems = List<CartItem>.from(state.items)
      ..removeWhere((i) => i.id == itemId);
    state = state.copyWith(items: newItems);

    final result = await _repository.removeFromCart(_uid, itemId);
    result.when(
      onSuccess: (_) {},
      onFailure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        _loadCart(); // revert
      },
    );
  }

  Future<void> mergeCart() async {
    if (_uid != null) {
      state = state.copyWith(isLoading: true);
      final result = await _repository.mergeGuestCart(_uid);
      result.when(
        onSuccess: (_) => _loadCart(),
        onFailure: (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
      );
    }
  }
}
