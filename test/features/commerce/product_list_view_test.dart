import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finalprm/features/commerce/presentation/views/product_list_view.dart';
import 'package:finalprm/features/commerce/presentation/controllers/catalog_controller.dart';
import 'package:finalprm/features/commerce/presentation/controllers/cart_controller.dart';
import 'package:finalprm/features/commerce/presentation/providers/commerce_providers.dart';
import 'package:finalprm/core/widgets/product_card_skeleton.dart';
import 'package:finalprm/core/widgets/empty_view.dart';
import 'package:finalprm/core/widgets/error_view.dart';

class MockCatalogController extends StateNotifier<CatalogState>
    implements CatalogController {
  MockCatalogController(super.state);

  @override
  Future<void> filterByCategory(String? categoryId) async {}
}

class MockCartController extends StateNotifier<CartState>
    implements CartController {
  MockCartController(super.state);

  @override
  Future<void> addToCart(
    dynamic product, {
    int quantity = 1,
    String? selectedSize,
  }) async {}

  @override
  Future<void> clearCart() async {}

  @override
  Future<void> removeFromCart(String productId, {String? selectedSize}) async {}

  @override
  Future<void> updateQuantity(
    String productId,
    int quantity, {
    String? selectedSize,
  }) async {}

  @override
  Future<void> mergeCart() async {}
}

void main() {
  Widget createWidgetUnderTest(CatalogState state) {
    return ProviderScope(
      overrides: [
        catalogControllerProvider.overrideWith(
          (ref) => MockCatalogController(state),
        ),
        cartControllerProvider.overrideWith(
          (ref) => MockCartController(CartState()),
        ),
      ],
      child: const MaterialApp(home: ProductListView()),
    );
  }

  group('ProductListView States', () {
    testWidgets(
      'shows loading skeletons when isLoading is true and no products',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(CatalogState(isLoading: true)),
        );
        expect(find.byType(ProductCardSkeleton), findsWidgets);
      },
    );

    testWidgets('shows ErrorView when there is an error and no products', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(CatalogState(errorMessage: 'Error')),
      );
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('shows EmptyView when there are no products', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(CatalogState()));
      expect(find.byType(EmptyView), findsOneWidget);
    });
  });
}
