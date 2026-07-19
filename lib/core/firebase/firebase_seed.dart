import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSeed {
  static Future<void> seedAll() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Seed pre-configured Auth test users in Auth Emulator if they don't exist
    final testUsers = {
      'admin@example.com': 'admin123',
      'seller@example.com': 'seller123',
      'user@example.com': 'user123',
    };

    for (final entry in testUsers.entries) {
      try {
        await auth.createUserWithEmailAndPassword(
          email: entry.key,
          password: entry.value,
        );
      } catch (_) {
        // Ignored if user already exists or in production
      }
    }

    // 1. Seed Categories
    final categories = {
      'nike': {
        'name': 'Nike',
        'slug': 'nike',
        'imageUrl':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        'status': 'active',
        'sortOrder': 1,
      },
      'adidas': {
        'name': 'Adidas',
        'slug': 'adidas',
        'imageUrl':
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        'status': 'active',
        'sortOrder': 2,
      },
      'puma': {
        'name': 'Puma',
        'slug': 'puma',
        'imageUrl':
            'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=400',
        'status': 'active',
        'sortOrder': 3,
      },
    };

    for (final entry in categories.entries) {
      await firestore.collection('categories').doc(entry.key).set(entry.value);
    }

    // 2. Seed Users
    final users = {
      'admin_1': {
        'displayName': 'Quản trị viên',
        'email': 'admin@example.com',
        'avatarUrl': '',
        'roleMirror': 'admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'seller_1': {
        'displayName': 'Cửa hàng Sneaker Kings',
        'email': 'seller@example.com',
        'avatarUrl': '',
        'roleMirror': 'seller',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'user_1': {
        'displayName': 'Nguyễn Văn Hiếu',
        'email': 'user@example.com',
        'avatarUrl': '',
        'roleMirror': 'user',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
    };

    for (final entry in users.entries) {
      await firestore.collection('users').doc(entry.key).set(entry.value);
    }

    // 3. Seed Store Profile
    await firestore.collection('stores').doc('seller_1').set({
      'ownerUid': 'seller_1',
      'name': 'Cửa hàng Sneaker Kings',
      'slug': 'sneaker-kings',
      'logoUrl':
          'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=400',
      'description':
          'Hệ thống phân phối giày sneaker chính hãng hàng đầu Việt Nam.',
      'status': 'active',
      'rating': 5.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 4. Seed Products
    final products = {
      'prod_pegasus': {
        'sellerId': 'seller_1',
        'storeId': 'seller_1',
        'name': 'Nike Air Zoom Pegasus 39',
        'searchTokens': ['nike', 'pegasus', 'zoom'],
        'description':
            'Dòng giày chạy bộ huyền thoại của Nike với đệm Air Zoom êm ái, hỗ trợ tối đa cho từng bước chạy.',
        'categoryId': 'nike',
        'basePrice': 2500000.0,
        'status': 'published',
        'minPrice': 2500000.0,
        'images': [
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
          'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=400',
        ],
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'prod_ultraboost': {
        'sellerId': 'seller_1',
        'storeId': 'seller_1',
        'name': 'Adidas Ultraboost Light',
        'searchTokens': ['adidas', 'ultraboost', 'boost'],
        'description':
            'Đỉnh cao của sự thoải mái với công nghệ Boost siêu nhẹ, tăng hoàn năng lượng tuyệt vời.',
        'categoryId': 'adidas',
        'basePrice': 3200000.0,
        'status': 'published',
        'minPrice': 3200000.0,
        'images': [
          'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400',
        ],
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'prod_rider': {
        'sellerId': 'seller_1',
        'storeId': 'seller_1',
        'name': 'Puma Future Rider Play On',
        'searchTokens': ['puma', 'rider', 'future'],
        'description':
            'Đôi giày thời trang mang đậm phong cách Retro năng động và trẻ trung.',
        'categoryId': 'puma',
        'basePrice': 1800000.0,
        'status':
            'pendingReview', // Bắt đầu ở dạng chờ duyệt để test flow moderation
        'minPrice': 1800000.0,
        'images': [
          'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=400',
        ],
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };

    for (final entry in products.entries) {
      await firestore.collection('products').doc(entry.key).set(entry.value);
    }

    // 5. Seed Variants
    final variants = {
      'prod_pegasus': [
        {
          'id': 'v_peg_42_red',
          'size': '42',
          'color': 'Đỏ',
          'sku': 'NIKE-PEG-42-RED',
          'stockQuantity': 10,
          'priceDifference': 0.0,
        },
        {
          'id': 'v_peg_43_black',
          'size': '43',
          'color': 'Đen',
          'sku': 'NIKE-PEG-43-BLACK',
          'stockQuantity': 5,
          'priceDifference': 150000.0,
        },
      ],
      'prod_ultraboost': [
        {
          'id': 'v_ub_41_white',
          'size': '41',
          'color': 'Trắng',
          'sku': 'ADI-UB-41-WHITE',
          'stockQuantity': 1, // Để test race condition / hết hàng
          'priceDifference': 0.0,
        },
        {
          'id': 'v_ub_42_black',
          'size': '42',
          'color': 'Đen',
          'sku': 'ADI-UB-42-BLACK',
          'stockQuantity': 8,
          'priceDifference': 100000.0,
        },
      ],
      'prod_rider': [
        {
          'id': 'v_rider_42_blue',
          'size': '42',
          'color': 'Xanh',
          'sku': 'PUMA-RIDER-42-BLUE',
          'stockQuantity': 15,
          'priceDifference': 0.0,
        },
      ],
    };

    for (final entry in variants.entries) {
      final prodId = entry.key;
      for (final v in entry.value) {
        final variantId = v['id'] as String;
        await firestore
            .collection('products')
            .doc(prodId)
            .collection('variants')
            .doc(variantId)
            .set(v);
      }
      // Also update the product document to contain nested variants array for the Flutter UI
      await firestore.collection('products').doc(prodId).update({
        'variants': entry.value,
      });
    }
  }
}
