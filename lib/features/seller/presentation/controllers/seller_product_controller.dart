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
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getSellerProducts(
      uid,
      status: state.filterStatus,
    );
    result.when(
      onSuccess: (products) {
        state = state.copyWith(isLoading: false, products: products);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
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

  Future<bool> requestStockReplenishment(
    Product product, {
    required int requestedQuantity,
    required String note,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.requestStockReplenishment(
      branchId: uid,
      product: product,
      requestedQuantity: requestedQuantity,
      note: note,
    );
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
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
