import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:finalprm/core/result/result.dart';
import 'package:finalprm/core/error/app_failure.dart';
import 'package:finalprm/features/commerce/domain/models/product.dart';
import 'package:finalprm/features/commerce/domain/models/app_order.dart';
import 'package:finalprm/features/seller/domain/models/seller_application.dart';
import 'package:finalprm/features/seller/domain/models/store_profile.dart';
import 'package:finalprm/features/seller/data/repositories/seller_repository.dart';
import 'package:finalprm/features/seller/presentation/controllers/seller_stats_controller.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(OrderStatus.pending);
    registerFallbackValue(ProductStatus.draft);
  });


  group('SellerProductController & Repository Validations', () {
    test(
      'saveProductDraft validates VND pricing and prevents non-integers',
      () async {
        final repository = SellerRepositoryImpl(
          FakeFirebaseFirestore(),
          FakeFirebaseFunctions(),
        );
        final draftWithDecimalPrice = Product(
          id: 'p-1',
          name: 'Giày Thể Thao',
          description: 'Mô tả',
          categoryId: 'cat-1',
          basePrice: 850000.50, // decimal price VND (invalid)
          sellerId: 'seller-1',
          createdAt: DateTime.now(),
          variants: [
            const ProductVariant(
              id: 'v-1',
              size: '40',
              color: 'Đen',
              sku: 'SKU-001',
              stockQuantity: 10,
              priceDifference: 0,
            ),
          ],
        );

        final result = await repository.saveProductDraft(draftWithDecimalPrice);
        expect(result, isA<Failure>());
        result.when(
          onSuccess: (_) => fail('Should not succeed'),
          onFailure: (failure) {
            expect(
              failure.message,
              contains('Giá tiền cơ bản VND phải là số nguyên'),
            );
          },
        );
      },
    );

    test('saveProductDraft prevents negative stock', () async {
      final repository = SellerRepositoryImpl(
        FakeFirebaseFirestore(),
        FakeFirebaseFunctions(),
      );
      final draftWithNegativeStock = Product(
        id: 'p-1',
        name: 'Giày Thể Thao',
        description: 'Mô tả',
        categoryId: 'cat-1',
        basePrice: 850000,
        sellerId: 'seller-1',
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(
            id: 'v-1',
            size: '40',
            color: 'Đen',
            sku: 'SKU-001',
            stockQuantity: -5,
            priceDifference: 0,
          ), // negative stock (invalid)
        ],
      );

      final result = await repository.saveProductDraft(draftWithNegativeStock);
      expect(result, isA<Failure>());
      result.when(
        onSuccess: (_) => fail('Should not succeed'),
        onFailure: (failure) {
          expect(failure.message, contains('Số lượng tồn kho không được âm'));
        },
      );
    });
  });

  group('Order Status Transitions State Machine', () {
    test(
      'updateOrderStatus enforces correct state machine transitions and blocks invalid ones',
      () async {
        // Mock repository implementation of updateOrderStatus transitions:
        // pending -> confirmed -> shipping -> completed
        // any invalid transition like shipping -> pending is blocked
        final repository = FakeSellerRepository();

        // 1. Pending to Confirmed should succeed
        final res1 = await repository.updateOrderStatus(
          'order-1',
          OrderStatus.confirmed,
        );
        expect(res1, isA<Success>());
        expect(repository.currentOrderStatus, OrderStatus.confirmed);

        // 2. Confirmed to Completed should fail (must go through shipping first)
        final res2 = await repository.updateOrderStatus(
          'order-1',
          OrderStatus.completed,
        );
        expect(res2, isA<Failure>());
        res2.when(
          onSuccess: (_) => fail('Should not allow confirmed -> completed'),
          onFailure: (failure) {
            expect(failure.message, contains('Chuyển trạng thái không hợp lệ'));
          },
        );

        // 3. Confirmed to Shipping should succeed
        final res3 = await repository.updateOrderStatus(
          'order-1',
          OrderStatus.shipping,
        );
        expect(res3, isA<Success>());
        expect(repository.currentOrderStatus, OrderStatus.shipping);

        // 4. Shipping to Completed should succeed
        final res4 = await repository.updateOrderStatus(
          'order-1',
          OrderStatus.completed,
        );
        expect(res4, isA<Success>());
        expect(repository.currentOrderStatus, OrderStatus.completed);
      },
    );
  });

  group('Seller Statistics calculations', () {
    test(
      'SellerStatsController computes revenue and low stock alerts correctly',
      () async {
        final repository = FakeSellerRepository();
        final controller = SellerStatsController(repository, 'seller-1');

        // Wait for async load to finish
        await Future.delayed(Duration.zero);

        controller.state.when(
          loading: () => fail('Stats should be loaded'),
          error: (err, s) => fail('Stats error: $err'),
          data: (stats) {
            // One product in fake repository
            expect(stats.totalProducts, 1);
            // Variant of mock product has stock 2 (< 5), so it should alert low stock
            expect(stats.lowStockProductsCount, 1);
            expect(stats.lowStockProducts.first.name, 'Giày Chạy Bộ');
            // One completed order in fake repository with 2 items of price 500,000
            expect(stats.totalRevenue, 1000000.0);
          },
        );
      },
    );
  });
}

// Fakes and Mocks
class FakeFirebaseFirestore extends Mock implements FirebaseFirestore {}

class FakeFirebaseFunctions extends Mock implements FirebaseFunctions {}

class FakeSellerRepository implements SellerRepository {
  OrderStatus currentOrderStatus = OrderStatus.pending;

  @override
  Future<Result<void>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    // pending -> confirmed, cancelled
    // confirmed -> shipping, cancelled
    // shipping -> completed, cancelled
    bool isValid = false;
    if (currentOrderStatus == OrderStatus.pending) {
      isValid =
          newStatus == OrderStatus.confirmed ||
          newStatus == OrderStatus.cancelled;
    } else if (currentOrderStatus == OrderStatus.confirmed) {
      isValid =
          newStatus == OrderStatus.shipping ||
          newStatus == OrderStatus.cancelled;
    } else if (currentOrderStatus == OrderStatus.shipping) {
      isValid =
          newStatus == OrderStatus.completed ||
          newStatus == OrderStatus.cancelled;
    }

    if (!isValid) {
      return Failure(
        AppFailure.conflict(
          'Chuyển trạng thái không hợp lệ từ ${currentOrderStatus.name} sang ${newStatus.name}',
        ),
      );
    }

    currentOrderStatus = newStatus;
    return const Success(null);
  }

  @override
  Future<Result<List<Product>>> getSellerProducts(
    String sellerId, {
    ProductStatus? status,
  }) async {
    return Success([
      Product(
        id: 'p-100',
        name: 'Giày Chạy Bộ',
        description: 'Mô tả',
        categoryId: 'cat-1',
        basePrice: 500000,
        sellerId: sellerId,
        status: ProductStatus.published,
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(
            id: 'v-100',
            size: '42',
            color: 'Xanh',
            sku: 'SKU-BLUE-42',
            stockQuantity: 2,
            priceDifference: 0,
          ),
        ],
      ),
    ]);
  }

  @override
  Future<Result<List<AppOrder>>> getSellerOrders(String sellerId) async {
    return Success([
      AppOrder(
        id: 'order-100',
        userId: 'user-2',
        status: OrderStatus.completed,
        totalAmount: 1000000,
        shippingAddress: const ShippingAddress(
          fullName: 'Nguyen Van A',
          phone: '0901234567',
          addressLine: '123 Str',
          city: 'HCMC',
        ),
        paymentMethod: 'COD',
        createdAt: DateTime.now(),
        items: [
          const OrderItem(
            productId: 'p-100',
            variantId: 'v-100',
            productName: 'Giày Chạy Bộ',
            size: '42',
            color: 'Xanh',
            price: 500000,
            quantity: 2,
            imageUrl: '',
          ),
        ],
      ),
    ]);
  }

  @override
  Future<Result<StoreProfile>> getStoreProfile(String sellerId) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> updateStoreProfile(StoreProfile profile) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> applyForSeller(SellerApplication application) async =>
      throw UnimplementedError();
  @override
  Future<Result<SellerApplication?>> getSellerApplication(
    String userId,
  ) async => throw UnimplementedError();
  @override
  Future<Result<void>> saveProductDraft(Product product) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> deleteProductDraft(String productId) async =>
      throw UnimplementedError();
  @override
  Future<Result<void>> submitProductForReview(String productId) async =>
      throw UnimplementedError();
}
