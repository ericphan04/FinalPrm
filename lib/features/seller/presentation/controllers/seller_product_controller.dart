import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commerce/domain/models/product.dart';
import '../../data/repositories/seller_repository.dart';

class SellerProductState {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;
  final ProductStatus? filterStatus;

  SellerProductState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
    this.filterStatus,
  });

  SellerProductState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
    ProductStatus? filterStatus,
    bool clearFilter = false,
  }) {
    return SellerProductState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
    );
  }
}

class SellerProductController extends StateNotifier<SellerProductState> {
  final SellerRepository _repository;
  final String? _uid;

  SellerProductController(this._repository, this._uid)
    : super(SellerProductState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    if (_uid == null || _uid!.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSellerProducts(
      _uid!,
      status: state.filterStatus,
    );
    result.when(
      onSuccess: (products) async {
        final hasSeeded = products.any((p) => p.id.startsWith('seed-prod-$_uid-'));
        if (!hasSeeded && state.filterStatus == null) {
          // Catalog is empty of seed products, seed 10 high-fidelity shoe and sandal products!
          await _seedTenProducts(_uid!);
          final reResult = await _repository.getSellerProducts(
            _uid!,
            status: state.filterStatus,
          );
          reResult.when(
            onSuccess: (reProducts) {
              state = state.copyWith(isLoading: false, products: reProducts);
            },
            onFailure: (failure) {
              state = state.copyWith(isLoading: false, errorMessage: failure.message);
            },
          );
        } else {
          state = state.copyWith(isLoading: false, products: products);
        }
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  Future<void> _seedTenProducts(String sellerId) async {
    final seedData = [
      Product(
        id: 'seed-prod-$sellerId-1',
        name: 'Giày Sneaker Retro Classic',
        description: 'Được thiết kế theo phong cách cổ điển thập niên 90 với đệm êm ái, thích hợp cho hoạt động đi lại hàng ngày.',
        categoryId: 'cat-giay',
        basePrice: 1200000.0,
        sellerId: sellerId,
        status: ProductStatus.draft,
        images: ['https://picsum.photos/300/300?random=11'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-1-1', size: '40', color: 'Trắng', sku: 'SNE-W-40', stockQuantity: 15, priceDifference: 0),
          const ProductVariant(id: 'v-seed-1-2', size: '41', color: 'Trắng', sku: 'SNE-W-41', stockQuantity: 8, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-2',
        name: 'Giày Chạy Bộ Performance X',
        description: 'Giày chạy bộ chuyên nghiệp, siêu nhẹ, hỗ trợ phản hồi lực kéo cực tốt cho các vận động viên marathon.',
        categoryId: 'cat-giay',
        basePrice: 1850000.0,
        sellerId: sellerId,
        status: ProductStatus.published,
        images: ['https://picsum.photos/300/300?random=12'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-2-1', size: '42', color: 'Đen', sku: 'RUN-B-42', stockQuantity: 2, priceDifference: 50000), // Low stock
          const ProductVariant(id: 'v-seed-2-2', size: '43', color: 'Đen', sku: 'RUN-B-43', stockQuantity: 20, priceDifference: 50000),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-3',
        name: 'Giày Tây Oxford Classic Nâu',
        description: 'Chất liệu da bò thật 100%, thiết kế phom dáng ôm chân sang trọng tôn dáng lịch lãm công sở.',
        categoryId: 'cat-giay',
        basePrice: 2500000.0,
        sellerId: sellerId,
        status: ProductStatus.draft,
        images: ['https://picsum.photos/300/300?random=13'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-3-1', size: '39', color: 'Nâu', sku: 'OXF-BR-39', stockQuantity: 5, priceDifference: 0),
          const ProductVariant(id: 'v-seed-3-2', size: '40', color: 'Nâu', sku: 'OXF-BR-40', stockQuantity: 6, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-4',
        name: 'Dép Slide Sporty Quai Ngang',
        description: 'Dép quai ngang thể thao êm ái chống trượt, phù hợp đi trong nhà, đi mưa, hoặc đi chơi dã ngoại dạo phố.',
        categoryId: 'cat-dep',
        basePrice: 250000.0,
        sellerId: sellerId,
        status: ProductStatus.published,
        images: ['https://picsum.photos/300/300?random=14'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-4-1', size: '40', color: 'Xám', sku: 'SLI-GR-40', stockQuantity: 3, priceDifference: 0), // Low stock
          const ProductVariant(id: 'v-seed-4-2', size: '41', color: 'Xám', sku: 'SLI-GR-41', stockQuantity: 12, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-5',
        name: 'Dép Sandal Adventure Quai Chéo',
        description: 'Dép quai hậu sandal dã ngoại chắc chắn, quai vải dù nhanh khô, đế cao su bám đường đi phượt dã ngoại.',
        categoryId: 'cat-dep',
        basePrice: 650000.0,
        sellerId: sellerId,
        status: ProductStatus.pendingReview,
        images: ['https://picsum.photos/300/300?random=15'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-5-1', size: '41', color: 'Xanh Rêu', sku: 'SAN-G-41', stockQuantity: 8, priceDifference: 0),
          const ProductVariant(id: 'v-seed-5-2', size: '42', color: 'Xanh Rêu', sku: 'SAN-G-42', stockQuantity: 10, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-6',
        name: 'Dép Xỏ Ngón Beach Walker',
        description: 'Dép tông xỏ ngón đi biển siêu bền nhẹ, màu sắc năng động trẻ trung và cực kỳ thoải mái chân.',
        categoryId: 'cat-dep',
        basePrice: 180000.0,
        sellerId: sellerId,
        status: ProductStatus.rejected,
        rejectReason: 'Hình ảnh sản phẩm mờ, không rõ chi tiết. Vui lòng chụp lại hình ảnh rõ nét hơn.',
        images: ['https://picsum.photos/300/300?random=16'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-6-1', size: '39', color: 'Đen', sku: 'FLI-BLK-39', stockQuantity: 4, priceDifference: 0), // Low stock
          const ProductVariant(id: 'v-seed-6-2', size: '40', color: 'Đen', sku: 'FLI-BLK-40', stockQuantity: 15, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-7',
        name: 'Giày Cao Gót Nữ Glamour Pink',
        description: 'Giày cao gót mũi nhọn gót mảnh 7 phân quý phái lịch thiệp dành cho quý cô dự tiệc hội nghị.',
        categoryId: 'cat-giay',
        basePrice: 1100000.0,
        sellerId: sellerId,
        status: ProductStatus.draft,
        images: ['https://picsum.photos/300/300?random=17'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-7-1', size: '36', color: 'Hồng', sku: 'HEE-P-36', stockQuantity: 10, priceDifference: 0),
          const ProductVariant(id: 'v-seed-7-2', size: '37', color: 'Hồng', sku: 'HEE-P-37', stockQuantity: 7, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-8',
        name: 'Giày Lười Loafer Suede Da Lộn',
        description: 'Chất liệu da lộn mềm mại êm chân, màu bò cá tính phong lưu sang trọng cực kỳ hợp đồ dạo phố.',
        categoryId: 'cat-giay',
        basePrice: 1450000.0,
        sellerId: sellerId,
        status: ProductStatus.published,
        images: ['https://picsum.photos/300/300?random=18'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-8-1', size: '41', color: 'Da Bò', sku: 'LOA-TAN-41', stockQuantity: 4, priceDifference: 30000), // Low stock
          const ProductVariant(id: 'v-seed-8-2', size: '42', color: 'Da Bò', sku: 'LOA-TAN-42', stockQuantity: 11, priceDifference: 30000),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-9',
        name: 'Dép Da Quai Chéo Premium',
        description: 'Dép da quai chéo chất liệu da bò sang xịn đế đúc nguyên khối siêu sang thích hợp mặc đồ linen.',
        categoryId: 'cat-dep',
        basePrice: 750000.0,
        sellerId: sellerId,
        status: ProductStatus.draft,
        images: ['https://picsum.photos/300/300?random=19'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-9-1', size: '40', color: 'Đen', sku: 'LEA-BLK-40', stockQuantity: 12, priceDifference: 0),
          const ProductVariant(id: 'v-seed-9-2', size: '41', color: 'Đen', sku: 'LEA-BLK-41', stockQuantity: 14, priceDifference: 0),
        ],
      ),
      Product(
        id: 'seed-prod-$sellerId-10',
        name: 'Dép Clog Classic Unisex',
        description: 'Dép sục clog classic siêu bền nhẹ chống thấm nước, thích hợp đi làm đi chơi trong mọi thời tiết.',
        categoryId: 'cat-dep',
        basePrice: 550000.0,
        sellerId: sellerId,
        status: ProductStatus.rejected,
        rejectReason: 'Tên sản phẩm chứa thương hiệu bản quyền nhạy cảm chưa kiểm duyệt.',
        images: ['https://picsum.photos/300/300?random=20'],
        createdAt: DateTime.now(),
        variants: [
          const ProductVariant(id: 'v-seed-10-1', size: '38', color: 'Trắng', sku: 'CLO-W-38', stockQuantity: 1, priceDifference: -20000), // Low stock
          const ProductVariant(id: 'v-seed-10-2', size: '40', color: 'Trắng', sku: 'CLO-W-40', stockQuantity: 18, priceDifference: 0),
        ],
      ),
    ];
    for (final p in seedData) {
      await _repository.saveProductDraft(p);
    }
  }

  void setFilterStatus(ProductStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
    loadProducts();
  }

  Future<bool> saveProductDraft(Product product) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Safety check: force status to draft if it's new or was a draft
    Product draftProduct = product;
    if (product.status != ProductStatus.rejected) {
      draftProduct = product.copyWith(status: ProductStatus.draft);
    }

    final result = await _repository.saveProductDraft(draftProduct);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        loadProducts();
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<bool> deleteProductDraft(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.deleteProductDraft(productId);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        loadProducts();
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<bool> submitProductForReview(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.submitProductForReview(productId);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        loadProducts();
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Simulate uploading image with potential mock failures.
  /// Ensure we keep form details elsewhere when this fails.
  Future<String?> uploadImageMock(
    String imagePath, {
    bool simulateFailure = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (simulateFailure) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải ảnh lên Storage. Vui lòng thử lại.',
      );
      return null;
    }

    state = state.copyWith(isLoading: false);
    // Return a mock URL
    return 'https://picsum.photos/300/300?random=${DateTime.now().millisecond}';
  }
}
