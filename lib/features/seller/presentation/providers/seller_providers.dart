import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../data/repositories/seller_repository.dart';
import '../controllers/seller_application_controller.dart';
import '../controllers/store_profile_controller.dart';
import '../controllers/seller_product_controller.dart';
import '../controllers/seller_order_controller.dart';
import '../controllers/seller_stats_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

final sellerApplicationControllerProvider =
    StateNotifierProvider<SellerApplicationController, SellerApplicationState>((
      ref,
    ) {
      final repository = ref.watch(sellerRepositoryProvider);
      final authUser = ref.watch(authStateProvider);
      final uid = authUser.uid.isEmpty ? null : authUser.uid;
      return SellerApplicationController(repository, uid);
    });

final storeProfileControllerProvider =
    StateNotifierProvider<StoreProfileController, StoreProfileState>((ref) {
      final repository = ref.watch(sellerRepositoryProvider);
      final authUser = ref.watch(authStateProvider);
      final uid = authUser.uid.isEmpty ? null : authUser.uid;
      return StoreProfileController(repository, uid);
    });

final sellerProductControllerProvider =
    StateNotifierProvider<SellerProductController, SellerProductState>((ref) {
      final repository = ref.watch(sellerRepositoryProvider);
      final authUser = ref.watch(authStateProvider);
      final uid = authUser.uid.isEmpty ? null : authUser.uid;
      return SellerProductController(repository, uid);
    });

final sellerOrderControllerProvider =
    StateNotifierProvider<SellerOrderController, SellerOrderState>((ref) {
      final repository = ref.watch(sellerRepositoryProvider);
      final authUser = ref.watch(authStateProvider);
      final uid = authUser.uid.isEmpty ? null : authUser.uid;
      return SellerOrderController(repository, uid);
    });

final sellerStatsControllerProvider =
    StateNotifierProvider<SellerStatsController, AsyncValue<SellerStats>>((
      ref,
    ) {
      final repository = ref.watch(sellerRepositoryProvider);
      final authUser = ref.watch(authStateProvider);
      final uid = authUser.uid.isEmpty ? null : authUser.uid;

      // Re-read stats when products or orders list updates
      ref.watch(sellerProductControllerProvider);
      ref.watch(sellerOrderControllerProvider);

      return SellerStatsController(repository, uid);
    });
