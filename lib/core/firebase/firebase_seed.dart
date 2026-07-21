import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSeed {
  static Future<void> seedAll() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    const seedEmail = 'seed_admin@emulator.local';
    const seedPassword = 'seed_admin_pass_123';
    try {
      await auth.createUserWithEmailAndPassword(
        email: seedEmail,
        password: seedPassword,
      );
    } catch (_) {
      try {
        await auth.signInWithEmailAndPassword(
          email: seedEmail,
          password: seedPassword,
        );
      } catch (_) {
        // Ignore outside the emulator.
      }
    }

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
        // Ignored if user already exists or auth emulator is unavailable.
      }
    }

    final categories = {
      'shoes': {
        'name': 'Shoes',
        'slug': 'shoes',
        'imageUrl':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        'status': 'active',
        'sortOrder': 1,
      },
      'sandals': {
        'name': 'Sandals',
        'slug': 'sandals',
        'imageUrl':
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        'status': 'active',
        'sortOrder': 2,
      },
      'accessories': {
        'name': 'Accessories',
        'slug': 'accessories',
        'imageUrl':
            'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=400',
        'status': 'active',
        'sortOrder': 3,
      },
    };

    for (final entry in categories.entries) {
      await firestore.collection('categories').doc(entry.key).set(entry.value);
    }

    final users = {
      'admin_1': {
        'displayName': 'Admin',
        'email': 'admin@example.com',
        'avatarUrl': '',
        'roleMirror': 'admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'seller_1': {
        'displayName': 'Branch 01',
        'email': 'seller@example.com',
        'avatarUrl': '',
        'roleMirror': 'seller',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'user_1': {
        'displayName': 'Customer',
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

    await firestore.collection('stores').doc('seller_1').set({
      'ownerUid': 'seller_1',
      'name': 'Branch 01',
      'slug': 'branch-01',
      'logoUrl':
          'https://images.unsplash.com/photo-1472851294608-062f824d296e?w=400',
      'description': 'Company branch account.',
      'status': 'active',
      'rating': 5.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Product seeding is intentionally disabled. Admin owns the brand catalog
    // now, and old marketplace demo products should not be recreated.
  }
}
