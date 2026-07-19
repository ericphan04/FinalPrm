import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finalprm/core/firebase/firebase_seed.dart';
import 'package:finalprm/features/commerce/data/repositories/order_repository.dart';
import 'package:finalprm/features/commerce/domain/models/app_order.dart';
import 'package:finalprm/features/commerce/domain/models/cart_item.dart';
import 'package:finalprm/features/admin/data/repositories/admin_repository.dart';
import 'package:finalprm/features/seller/data/repositories/seller_repository.dart';
import 'package:finalprm/core/result/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 Integration Test Suite', () {
    setUpAll(() async {
      // 1. Initialize Firebase and Emulators
      await Firebase.initializeApp();

      const host = '127.0.0.1';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.settings = const Settings(
        host: '$host:8080',
        sslEnabled: false,
        persistenceEnabled: false,
      );
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);

      // 2. Clear Database before seeding
      await _clearFirestoreCollections();

      // 3. Seed initial database data
      await FirebaseSeed.seedAll();
    });

    test('Customer Happy Path: Checkout & Stock Decrement', () async {
      // 1. Authenticate customer
      final auth = FirebaseAuth.instance;
      UserCredential userCred;
      try {
        userCred = await auth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'user123',
        );
      } catch (e) {
        userCred = await auth.createUserWithEmailAndPassword(
          email: 'user@example.com',
          password: 'user123',
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
              'displayName': 'Customer User',
              'email': 'user@example.com',
              'roleMirror': 'user',
              'status': 'active',
            });
      }

      expect(userCred.user, isNotNull);

      // 2. Setup Repositories
      final orderRepo = OrderRepositoryImpl(
        FirebaseFunctions.instance,
        FirebaseFirestore.instance,
      );

      final cartItem = CartItem(
        id: 'cart_item_test',
        productId: 'prod_pegasus',
        variantId: 'v_peg_42_red',
        productName: 'Nike Air Zoom Pegasus 39',
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        size: '42',
        color: 'Đỏ',
        price: 2500000.0,
        quantity: 2,
        addedAt: DateTime.now(),
      );

      final address = const ShippingAddress(
        fullName: 'Nguyễn Văn Hiếu',
        phone: '0987654321',
        addressLine: '123 Đường Lê Lợi',
        city: 'Hồ Chí Minh',
      );

      // Check current stock first
      final variantRef = FirebaseFirestore.instance
          .collection('products')
          .doc('prod_pegasus')
          .collection('variants')
          .doc('v_peg_42_red');
      var variantSnap = await variantRef.get();
      final originalStock = variantSnap.data()!['stockQuantity'] as int;
      expect(originalStock, equals(10));

      // 3. Perform Checkout
      final checkoutResult = await orderRepo.createCheckout(
        userCred.user!.uid,
        [cartItem],
        address,
        'COD',
      );

      expect(checkoutResult is Success<AppOrder>, isTrue);
      final order = (checkoutResult as Success<AppOrder>).data;
      expect(order.status, equals(OrderStatus.pending));
      expect(order.totalAmount, equals(5000000.0));

      // 4. Verify Stock Decremented (10 - 2 = 8)
      variantSnap = await variantRef.get();
      final newStock = variantSnap.data()!['stockQuantity'] as int;
      expect(newStock, equals(8));
    });

    test('Out of Stock Validation', () async {
      final auth = FirebaseAuth.instance;
      final userCred = await auth.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'user123',
      );

      final orderRepo = OrderRepositoryImpl(
        FirebaseFunctions.instance,
        FirebaseFirestore.instance,
      );

      final cartItem = CartItem(
        id: 'cart_item_test_2',
        productId: 'prod_ultraboost',
        variantId: 'v_ub_41_white',
        productName: 'Adidas Ultraboost Light',
        imageUrl:
            'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400',
        size: '41',
        color: 'Trắng',
        price: 3200000.0,
        quantity: 3,
        addedAt: DateTime.now(),
      );

      final address = const ShippingAddress(
        fullName: 'Nguyễn Văn Hiếu',
        phone: '0987654321',
        addressLine: '123 Đường Lê Lợi',
        city: 'Hồ Chí Minh',
      );

      final checkoutResult = await orderRepo.createCheckout(
        userCred.user!.uid,
        [cartItem],
        address,
        'COD',
      );

      expect(checkoutResult is Failure<AppOrder>, isTrue);
      final failure = (checkoutResult as Failure<AppOrder>).failure;
      expect(failure.message, contains('hết hàng'));
    });

    test('Idempotent Checkout Retry', () async {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createCheckout',
      );

      final items = [
        {
          'productId': 'prod_pegasus',
          'variantId': 'v_peg_43_black',
          'quantity': 1,
        },
      ];
      final address = {
        'fullName': 'Test User',
        'phone': '0987654321',
        'addressLine': '456 Test St',
        'city': 'Hanoi',
      };

      final idempotencyKey = 'key_idempotency_123';

      final firstRes = await callable.call({
        'items': items,
        'address': address,
        'paymentMethod': 'COD',
        'idempotencyKey': idempotencyKey,
      });

      expect(firstRes.data, isNotNull);
      final firstCheckoutId = firstRes.data['checkoutId'];
      final firstOrderIds = List<String>.from(firstRes.data['orderIds']);

      final secondRes = await callable.call({
        'items': items,
        'address': address,
        'paymentMethod': 'COD',
        'idempotencyKey': idempotencyKey,
      });

      expect(secondRes.data, isNotNull);
      expect(secondRes.data['checkoutId'], equals(firstCheckoutId));
      expect(
        List<String>.from(secondRes.data['orderIds']),
        equals(firstOrderIds),
      );
    });

    test('Seller/Admin: Order Status Transitions & Validation', () async {
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      expect(ordersSnap.docs.isNotEmpty, isTrue);
      final orderId = ordersSnap.docs.first.id;

      final auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: 'seller@example.com',
        password: 'seller123',
      );

      final sellerRepo = SellerRepositoryImpl(
        FirebaseFirestore.instance,
        FirebaseFunctions.instance,
      );

      final invalidRes = await sellerRepo.updateOrderStatus(
        orderId,
        OrderStatus.completed,
      );
      expect(invalidRes is Failure<void>, isTrue);

      final confirmRes = await sellerRepo.updateOrderStatus(
        orderId,
        OrderStatus.confirmed,
      );
      expect(confirmRes is Success<void>, isTrue);

      final shipRes = await sellerRepo.updateOrderStatus(
        orderId,
        OrderStatus.shipping,
      );
      expect(shipRes is Success<void>, isTrue);

      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      expect(orderDoc.data()!['status'], equals('shipping'));
    });

    test('Admin Moderation: Approve Product', () async {
      final auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: 'admin@example.com',
        password: 'admin123',
      );

      final adminRepo = AdminRepositoryImpl(
        FirebaseFirestore.instance,
        FirebaseFunctions.instance,
      );

      final prodSnap = await FirebaseFirestore.instance
          .collection('products')
          .doc('prod_rider')
          .get();
      expect(prodSnap.data()!['status'], equals('pendingReview'));

      final reviewProdRes = await adminRepo.reviewProduct(
        'prod_rider',
        'approve',
      );
      expect(reviewProdRes is Success<void>, isTrue);

      final approvedProdSnap = await FirebaseFirestore.instance
          .collection('products')
          .doc('prod_rider')
          .get();
      expect(approvedProdSnap.data()!['status'], equals('published'));
    });
  });
}

Future<void> _clearFirestoreCollections() async {
  final collections = [
    'categories',
    'users',
    'products',
    'stores',
    'orders',
    'checkouts',
    'auditLogs',
    'reviews',
    'stats',
  ];
  final firestore = FirebaseFirestore.instance;
  for (final col in collections) {
    final snap = await firestore.collection(col).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
