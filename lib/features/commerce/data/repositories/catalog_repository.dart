import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';

abstract class CatalogRepository {
  Future<Result<List<Category>>> getCategories();

  Future<Result<List<Product>>> getProducts({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? categoryId,
    String? searchQuery,
  });

  Future<Result<Product>> getProductDetails(String productId);
}

class CatalogRepositoryImpl implements CatalogRepository {
  final FirebaseFirestore _firestore;

  CatalogRepositoryImpl(this._firestore);

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      if (snapshot.docs.isEmpty) {
        await _firestore.collection('categories').doc('cat-giay').set({
          'name': 'Giày',
          'description': 'Các loại giày thể thao, sneaker, cao gót, giày tây',
        });
        await _firestore.collection('categories').doc('cat-dep').set({
          'name': 'Dép',
          'description': 'Các loại dép slide, sandal, clog, xỏ ngón thời trang',
        });
        final newSnapshot = await _firestore.collection('categories').get();
        final categories = newSnapshot.docs
            .map((doc) => Category.fromJson({'id': doc.id, ...doc.data()}))
            .toList();
        return Success(categories);
      }
      final categories = snapshot.docs
          .map((doc) => Category.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      return Success(categories);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi tải danh mục: $e'));
    }
  }

  @override
  Future<Result<List<Product>>> getProducts({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      // Simple text search mock (Firestore doesn't support full-text search directly well,
      // usually requires Algolia, but we do basic filtering or ignore)
      // Here we just limit and sort
      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        // Timestamp to string conversion handled by JsonSerializable if needed,
        // but let's assume default mapping works for createdAt if it's stored as ISO string or we parse it
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return Product.fromJson(data);
      }).toList();

      return Success(products);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi tải danh sách sản phẩm: $e'));
    }
  }

  @override
  Future<Result<Product>> getProductDetails(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        return Failure(AppFailure.notFound('Không tìm thấy sản phẩm'));
      }
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      return Success(Product.fromJson(data));
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi tải chi tiết sản phẩm: $e'));
    }
  }
}
