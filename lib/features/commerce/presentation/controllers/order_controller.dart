import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_order.dart';
import '../../domain/models/cart_item.dart';
import '../../data/repositories/order_repository.dart';

class OrderState {
  final bool isLoading;
  final String? errorMessage;
  final List<AppOrder> orders;
  
  OrderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
  });

  OrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AppOrder>? orders,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
    );
  }
}

class OrderController extends StateNotifier<OrderState> {
  final OrderRepository _repository;
  final String? _uid;

  OrderController(this._repository, this._uid) : super(OrderState()) {
    if (_uid != null) {
      _repository.watchUserOrders(_uid).listen((orders) {
        if (mounted) {
          state = state.copyWith(orders: orders, isLoading: false);
        }
      }, onError: (err) {
        if (mounted) {
          state = state.copyWith(errorMessage: err.toString(), isLoading: false);
        }
      });
    }
  }

  Future<bool> createCheckout(List<CartItem> items, ShippingAddress address, String paymentMethod) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.createCheckout(items, address, paymentMethod);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<bool> cancelOrder(String orderId, String reason) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.cancelOrder(orderId, reason);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }
}
