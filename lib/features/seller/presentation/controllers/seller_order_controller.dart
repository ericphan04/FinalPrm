import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../data/repositories/seller_repository.dart';

class SellerOrderState {
  final bool isLoading;
  final String? errorMessage;
  final List<AppOrder> orders;
  final OrderStatus? filterStatus;

  SellerOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
    this.filterStatus,
  });

  SellerOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AppOrder>? orders,
    OrderStatus? filterStatus,
    bool clearFilter = false,
  }) {
    return SellerOrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
    );
  }
}

class SellerOrderController extends StateNotifier<SellerOrderState> {
  final SellerRepository _repository;
  final String? _uid;

  SellerOrderController(this._repository, this._uid)
    : super(SellerOrderState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    if (_uid == null || _uid!.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSellerOrders(_uid!);
    result.when(
      onSuccess: (orders) {
        state = state.copyWith(isLoading: false, orders: orders);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  void setFilterStatus(OrderStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  List<AppOrder> get filteredOrders {
    if (state.filterStatus == null) return state.orders;
    return state.orders.where((o) => o.status == state.filterStatus).toList();
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.updateOrderStatus(orderId, newStatus);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        loadOrders();
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }
}
