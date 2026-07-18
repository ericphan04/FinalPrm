import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPrefsProvider in main.dart');
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(FirebaseFirestore.instance);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return CartRepositoryImpl(FirebaseFirestore.instance, prefs);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    FirebaseFunctions.instance,
    FirebaseFirestore.instance,
  );
});

final catalogControllerProvider =
    StateNotifierProvider<CatalogController, CatalogState>((ref) {
      return CatalogController(ref.watch(catalogRepositoryProvider));
    });

final cartControllerProvider = StateNotifierProvider<CartController, CartState>(
  (ref) {
    final repository = ref.watch(cartRepositoryProvider);
    final authState = ref.watch(authControllerProvider);
    final uid = authState.user.uid.isEmpty ? null : authState.user.uid;
    return CartController(repository, uid);
  },
);

final orderControllerProvider =
    StateNotifierProvider<OrderController, OrderState>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      final authState = ref.watch(authControllerProvider);
      final uid = authState.user.uid.isEmpty ? null : authState.user.uid;
      return OrderController(repository, uid);
    });

final cartMergeListenerProvider = Provider<void>((ref) {
  ref.listen(authControllerProvider, (previous, next) {
    final prevUid = previous?.user.uid;
    final nextUid = next.user.uid;
    if ((prevUid == null || prevUid.isEmpty) && nextUid.isNotEmpty) {
      ref.read(cartRepositoryProvider).mergeGuestCart(nextUid).then((_) {
        // Refresh cart controller after merge
        ref.invalidate(cartControllerProvider);
      });
    }
  });
});
