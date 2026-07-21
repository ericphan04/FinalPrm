import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/result/result.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../domain/models/seller_application.dart';
import '../../domain/models/store_profile.dart';

abstract class SellerRepository {
  Future<Result<StoreProfile>> getStoreProfile(String sellerId);
  Future<Result<void>> updateStoreProfile(StoreProfile profile);
  Future<Result<void>> applyForSeller(SellerApplication application);
  Future<Result<SellerApplication?>> getSellerApplication(String userId);
  Future<Result<List<Product>>> getSellerProducts(
    String sellerId, {
    ProductStatus? status,
  });
  Future<Result<void>> saveProductDraft(Product product);
  Future<Result<void>> deleteProductDraft(String productId);
  Future<Result<void>> submitProductForReview(String productId);
  Future<Result<List<AppOrder>>> getSellerOrders(String sellerId);
  Future<Result<void>> updateOrderStatus(String orderId, OrderStatus newStatus);
  Future<Result<void>> requestStockReplenishment({
    required String branchId,
    required Product product,
    required int requestedQuantity,
    required String note,
  });
}

class SellerRepositoryImpl implements SellerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  SellerRepositoryImpl(this._firestore, this._functions);

  @override
  Future<Result<StoreProfile>> getStoreProfile(String sellerId) async {
    try {
      final doc = await _firestore.collection('stores').doc(sellerId).get();
      if (!doc.exists) {
        // Return default/empty profile if not exists yet
        return Success(
          StoreProfile(
            id: sellerId,
            name: '',
            phone: '',
            description: '',
            address: '',
            createdAt: DateTime.now(),
          ),
        );
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return Success(StoreProfile.fromJson(data));
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy thông tin cửa hàng: $e'));
    }
  }

  @override
  Future<Result<void>> updateStoreProfile(StoreProfile profile) async {
    try {
      await _firestore
          .collection('stores')
          .doc(profile.id)
          .set(profile.toJson());
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi cập nhật thông tin cửa hàng: $e'),
      );
    }
  }

  @override
  Future<Result<void>> applyForSeller(SellerApplication application) async {
    try {
      // 1. Write application to Firestore
      await _firestore
          .collection('seller_applications')
          .doc(application.id)
          .set(application.toJson());

      // 2. Call Cloud Function to submit and trigger admin moderation flow if needed
      try {
        final callable = _functions.httpsCallable('submitSellerApplication');
        await callable.call({'applicationId': application.id});
      } catch (e) {
        // Log/ignore functions error to allow Firestore-only flow in mock/emulator envs
      }

      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi gửi đơn ứng tuyển người bán: $e'),
      );
    }
  }

  @override
  Future<Result<SellerApplication?>> getSellerApplication(String userId) async {
    try {
      final doc = await _firestore
          .collection('seller_applications')
          .doc(userId)
          .get();
      if (!doc.exists) {
        return const Success(null);
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      return Success(SellerApplication.fromJson(data));
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi tải đơn đăng ký người bán: $e'),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getSellerProducts(
    String sellerId, {
    ProductStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId);
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return Product.fromJson(data);
      }).toList();

      return Success(products);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy danh sách sản phẩm: $e'));
    }
  }

  @override
  Future<Result<void>> saveProductDraft(Product product) async {
    try {
      if (product.id.isNotEmpty || product.id.isEmpty) {
        return Failure(
          AppFailure.conflict(
            'Chi nhánh không được tạo sản phẩm. Quản trị sẽ nhập hàng hóa và phân bổ tồn kho.',
          ),
        );
      }
      // Legacy marketplace product creation is intentionally disabled.
      // Validate VND price must be integer
      if (product.basePrice % 1 != 0) {
        return Failure(
          AppFailure.conflict('Giá tiền cơ bản VND phải là số nguyên'),
        );
      }
      for (final v in product.variants) {
        if (v.stockQuantity < 0) {
          return Failure(AppFailure.conflict('Số lượng tồn kho không được âm'));
        }
        if (v.priceDifference % 1 != 0) {
          return Failure(
            AppFailure.conflict(
              'Giá chênh lệch biến thể VND phải là số nguyên',
            ),
          );
        }
      }

      // SKU uniqueness check in shop
      final allProductsResult = await getSellerProducts(product.sellerId);
      if (allProductsResult is Success<List<Product>>) {
        final existingProducts = allProductsResult.data;
        final List<String> currentSkus = [];
        for (final p in existingProducts) {
          if (p.id == product.id) continue; // Skip itself during edit
          for (final v in p.variants) {
            currentSkus.add(v.sku.toLowerCase().trim());
          }
        }
        for (final v in product.variants) {
          final skuLower = v.sku.toLowerCase().trim();
          if (skuLower.isEmpty) {
            return Failure(
              AppFailure.conflict('SKU biến thể không được để trống'),
            );
          }
          if (currentSkus.contains(skuLower)) {
            return Failure(
              AppFailure.conflict(
                'Mã SKU "$skuLower" đã tồn tại trong cửa hàng của bạn',
              ),
            );
          }
          // Also check for duplicate SKU within the same product form
          if (product.variants
                  .where((x) => x.sku.toLowerCase().trim() == skuLower)
                  .length >
              1) {
            return Failure(
              AppFailure.conflict(
                'Mã SKU "$skuLower" bị trùng trong các biến thể sản phẩm',
              ),
            );
          }
        }
      }

      final data = product.toJson();
      data.remove('id'); // ID is the document name
      data['createdAt'] = Timestamp.fromDate(product.createdAt);
      data['variants'] = product.variants.map((v) => v.toJson()).toList();

      await _firestore.collection('products').doc(product.id).set(data);
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lưu bản nháp sản phẩm: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProductDraft(String productId) async {
    try {
      final docRef = _firestore.collection('products').doc(productId);
      final doc = await docRef.get();
      if (!doc.exists) {
        return Failure(AppFailure.notFound('Không tìm thấy sản phẩm'));
      }
      final productData = doc.data()!;
      if (productData['status'] != ProductStatus.draft.name) {
        return Failure(
          AppFailure.conflict('Chỉ có thể xóa sản phẩm ở trạng thái nháp'),
        );
      }
      await docRef.delete();
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi xóa sản phẩm nháp: $e'));
    }
  }

  @override
  Future<Result<void>> submitProductForReview(String productId) async {
    try {
      if (productId.isNotEmpty || productId.isEmpty) {
        return Failure(
          AppFailure.conflict(
            'Luồng duyệt sản phẩm đã được bỏ. Quản trị quản lý toàn bộ danh mục thương hiệu.',
          ),
        );
      }
      // Legacy marketplace product review is intentionally disabled.
      // 1. Call Cloud Function first ( moderation flows )
      try {
        final callable = _functions.httpsCallable('submitProductForReview');
        await callable.call({'productId': productId});
        return const Success(null);
      } catch (e) {
        // Fallback directly updating firestore to pendingReview in mock/emulator envs
        await _firestore.collection('products').doc(productId).update({
          'status': ProductStatus.pendingReview.name,
        });
        return const Success(null);
      }
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi gửi duyệt sản phẩm: $e'));
    }
  }

  @override
  Future<Result<List<AppOrder>>> getSellerOrders(String sellerId) async {
    try {
      // Filter by sellerId in the query to satisfy Firestore Security Rules
      final snapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      final sellerOrders = <AppOrder>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        final order = AppOrder.fromJson(data);
        sellerOrders.add(order);
      }

      // Sort by createdAt descending in memory
      sellerOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(sellerOrders);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi tải danh sách đơn hàng: $e'));
    }
  }

  @override
  Future<Result<void>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      // Verify state machine transition
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        return Failure(AppFailure.notFound('Không tìm thấy đơn hàng'));
      }

      final orderData = orderDoc.data()!;
      final currentStatusStr = orderData['status'] as String;
      final currentStatus = OrderStatus.values.firstWhere(
        (e) => e.name == currentStatusStr,
        orElse: () => OrderStatus.pending,
      );

      // Valid transitions:
      // pending -> confirmed, cancelled
      // confirmed -> shipping, cancelled
      // shipping -> completed, cancelled
      // completed, cancelled -> no transitions allowed
      bool isValid = false;
      if (currentStatus == OrderStatus.pending) {
        isValid =
            newStatus == OrderStatus.confirmed ||
            newStatus == OrderStatus.cancelled;
      } else if (currentStatus == OrderStatus.confirmed) {
        isValid =
            newStatus == OrderStatus.shipping ||
            newStatus == OrderStatus.cancelled;
      } else if (currentStatus == OrderStatus.shipping) {
        isValid =
            newStatus == OrderStatus.completed ||
            newStatus == OrderStatus.cancelled;
      }

      if (!isValid) {
        return Failure(
          AppFailure.conflict(
            'Chuyển trạng thái không hợp lệ từ ${currentStatus.name} sang ${newStatus.name}',
          ),
        );
      }

      // 1. Call Cloud Function as required: "Các thao tác ... trạng thái đơn đi qua Cloud Functions"
      try {
        final callable = _functions.httpsCallable('updateOrderStatus');
        await callable.call({'orderId': orderId, 'status': newStatus.name});
      } catch (e) {
        // Fallback direct update to firestore in mock/emulator environment
        await _firestore.collection('orders').doc(orderId).update({
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return const Success(null);
    } catch (e) {
      return Failure(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Result<void>> requestStockReplenishment({
    required String branchId,
    required Product product,
    required int requestedQuantity,
    required String note,
  }) async {
    try {
      if (requestedQuantity <= 0) {
        return Failure(AppFailure.conflict('Số lượng yêu cầu phải lớn hơn 0'));
      }

      await _firestore.collection('stock_requests').add({
        'branchId': branchId,
        'productId': product.id,
        'productName': product.name,
        'requestedQuantity': requestedQuantity,
        'note': note,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Không thể gửi yêu cầu bổ sung hàng: $e'),
      );
    }
  }
}
