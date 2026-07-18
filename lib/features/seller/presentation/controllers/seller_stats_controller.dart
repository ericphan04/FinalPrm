import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/result/result.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../data/repositories/seller_repository.dart';

class SellerStats {
  final int totalProducts;
  final int lowStockProductsCount;
  final double totalRevenue;
  final List<Product> lowStockProducts;

  SellerStats({
    required this.totalProducts,
    required this.lowStockProductsCount,
    required this.totalRevenue,
    required this.lowStockProducts,
  });
}

class SellerStatsController extends StateNotifier<AsyncValue<SellerStats>> {
  final SellerRepository _repository;
  final String? _uid;

  SellerStatsController(this._repository, this._uid)
    : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    if (_uid == null || _uid!.isEmpty) {
      state = AsyncValue.error('Người dùng chưa đăng nhập', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    final productsRes = await _repository.getSellerProducts(_uid!);
    final ordersRes = await _repository.getSellerOrders(_uid!);

    if (productsRes is Failure<List<Product>>) {
      state = AsyncValue.error(
        (productsRes as Failure).failure.message,
        StackTrace.current,
      );
      return;
    }
    if (ordersRes is Failure<List<AppOrder>>) {
      state = AsyncValue.error(
        (ordersRes as Failure).failure.message,
        StackTrace.current,
      );
      return;
    }

    final products = (productsRes as Success<List<Product>>).data;
    final orders = (ordersRes as Success<List<AppOrder>>).data;

    // Calculate low stock products (any variant stock < 5)
    final lowStock = products.where((p) {
      return p.variants.any((v) => v.stockQuantity < 5);
    }).toList();

    // Calculate total revenue from completed orders
    final sellerProductIds = products.map((e) => e.id).toSet();
    double revenue = 0.0;
    for (final order in orders) {
      if (order.status == OrderStatus.completed) {
        for (final item in order.items) {
          if (sellerProductIds.contains(item.productId)) {
            revenue += item.price * item.quantity;
          }
        }
      }
    }

    state = AsyncValue.data(
      SellerStats(
        totalProducts: products.length,
        lowStockProductsCount: lowStock.length,
        totalRevenue: revenue,
        lowStockProducts: lowStock,
      ),
    );
  }
}
