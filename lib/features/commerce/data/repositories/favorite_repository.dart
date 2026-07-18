import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';

abstract class FavoriteRepository {
  Future<Result<List<String>>> getFavorites(String? uid);
  Future<Result<void>> addFavorite(String? uid, String productId);
  Future<Result<void>> removeFavorite(String? uid, String productId);
  Future<Result<void>> mergeGuestFavorites(String uid);
}

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  static const String _guestFavoritesKey = 'guest_favorites';

  FavoriteRepositoryImpl(this._firestore, this._prefs);

  @override
  Future<Result<List<String>>> getFavorites(String? uid) async {
    try {
      if (uid == null) {
        // Guest Favorites
        final List<String>? favorites = _prefs.getStringList(_guestFavoritesKey);
        return Success(favorites ?? []);
      } else {
        // User Favorites
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();
        final items = snapshot.docs.map((doc) => doc.id).toList();
        return Success(items);
      }
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy danh sách yêu thích: $e'));
    }
  }

  @override
  Future<Result<void>> addFavorite(String? uid, String productId) async {
    try {
      if (uid == null) {
        final List<String> favorites = _prefs.getStringList(_guestFavoritesKey) ?? [];
        if (!favorites.contains(productId)) {
          favorites.add(productId);
          await _prefs.setStringList(_guestFavoritesKey, favorites);
        }
      } else {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(productId)
            .set({'addedAt': FieldValue.serverTimestamp()});
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi thêm vào yêu thích: $e'));
    }
  }

  @override
  Future<Result<void>> removeFavorite(String? uid, String productId) async {
    try {
      if (uid == null) {
        final List<String> favorites = _prefs.getStringList(_guestFavoritesKey) ?? [];
        if (favorites.contains(productId)) {
          favorites.remove(productId);
          await _prefs.setStringList(_guestFavoritesKey, favorites);
        }
      } else {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(productId)
            .delete();
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi xóa khỏi yêu thích: $e'));
    }
  }

  @override
  Future<Result<void>> mergeGuestFavorites(String uid) async {
    try {
      final List<String> guestFavorites = _prefs.getStringList(_guestFavoritesKey) ?? [];
      if (guestFavorites.isNotEmpty) {
        final batch = _firestore.batch();
        final coll = _firestore.collection('users').doc(uid).collection('favorites');
        for (var productId in guestFavorites) {
          batch.set(coll.doc(productId), {'addedAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
        await _prefs.remove(_guestFavoritesKey);
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi đồng bộ yêu thích: $e'));
    }
  }
}
