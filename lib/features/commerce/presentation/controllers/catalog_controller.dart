import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../data/repositories/catalog_repository.dart';

class CatalogState {
  final bool isLoading;
  final String? errorMessage;
  final List<Product> products;
  final List<Category> categories;
  final String? selectedCategoryId;

  CatalogState({
    this.isLoading = false,
    this.errorMessage,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
  });

  CatalogState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Product>? products,
    List<Category>? categories,
    String? selectedCategoryId,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CatalogController extends StateNotifier<CatalogState> {
  final CatalogRepository _repository;

  CatalogController(this._repository) : super(CatalogState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final categoryResult = await _repository.getCategories();
    final productResult = await _repository.getProducts();

    List<Category> categories = [];
    List<Product> products = [];
    String? error;

    categoryResult.when(
      onSuccess: (data) => categories = data,
      onFailure: (failure) => error = failure.message,
    );

    productResult.when(
      onSuccess: (data) => products = data,
      onFailure: (failure) => error = failure.message,
    );

    state = state.copyWith(
      isLoading: false,
      categories: categories,
      products: products,
      errorMessage: error,
    );
  }

  Future<void> filterByCategory(String? categoryId) async {
    state = state.copyWith(isLoading: true, selectedCategoryId: categoryId);
    final result = await _repository.getProducts(categoryId: categoryId);
    result.when(
      onSuccess: (data) {
        state = state.copyWith(isLoading: false, products: data);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }
}
