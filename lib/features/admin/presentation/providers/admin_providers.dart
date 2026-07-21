import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/audit_log.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../../commerce/domain/models/category.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../commerce/presentation/providers/commerce_providers.dart';
import '../../../seller/domain/models/seller_application.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

final pendingSellerApplicationsProvider =
    FutureProvider.autoDispose<List<SellerApplication>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      final result = await repo.getPendingSellerApplications();
      return result.when(
        onSuccess: (data) => data,
        onFailure: (failure) => throw failure.message,
      );
    });

final pendingProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getPendingProducts();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAllUsers();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final allOrdersProvider = FutureProvider.autoDispose<List<AppOrder>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAllOrders();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAuditLogs();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final systemConfigProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getSystemConfig();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final allProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  final result = await repo.getAllProducts();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final adminCategoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final result = await repo.getCategories();
  return result.when(
    onSuccess: (data) => data,
    onFailure: (failure) => throw failure.message,
  );
});

final stockRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      final result = await repo.getStockRequests();
      return result.when(
        onSuccess: (data) => data,
        onFailure: (failure) => throw failure.message,
      );
    });
