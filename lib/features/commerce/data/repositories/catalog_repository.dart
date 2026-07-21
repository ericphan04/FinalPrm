import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';

const _firestoreRequestTimeout = Duration(seconds: 8);

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
      final snapshot = await _firestore
          .collection('categories')
          .get()
          .timeout(_firestoreRequestTimeout);
      if (snapshot.docs.isEmpty) {
        await _firestore.collection('categories').doc('cat-giay').set({
          'name': 'Giày',
          'description': 'Các loại giày thể thao, sneaker, cao gót, giày tây',
        });
        await _firestore.collection('categories').doc('cat-dep').set({
          'name': 'Dép',
          'description': 'Các loại dép slide, sandal, clog, xỏ ngón thời trang',
        });
        final newSnapshot = await _firestore
            .collection('categories')
            .get()
            .timeout(_firestoreRequestTimeout);
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

      final snapshot = await query.get().timeout(_firestoreRequestTimeout);
      final List<Product> products = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        try {
          final prod = Product.fromJson(data);
          // Chỉ hiển thị các sản phẩm đã được duyệt/đăng bán (published) ra showroom công cộng
          if (prod.status == ProductStatus.published) {
            products.add(prod);
          }
        } catch (e) {
          // Bỏ qua nếu dữ liệu sản phẩm cũ bị lỗi format
        }
      }

      // Sắp xếp theo ngày tạo giảm dần (mới nhất lên đầu) trong bộ nhớ
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Phân trang giới hạn số lượng trong bộ nhớ
      final paginatedProducts = products.take(limit).toList();

      return Success(paginatedProducts);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi tải danh sách sản phẩm: $e'));
    }
  }

  @override
  Future<Result<Product>> getProductDetails(String productId) async {
    try {
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .get()
          .timeout(_firestoreRequestTimeout);
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
