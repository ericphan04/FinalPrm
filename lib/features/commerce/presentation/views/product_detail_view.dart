import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';
import '../providers/commerce_providers.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;
  int selectedImageIndex = 0;
  final _imagePageController = PageController();

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = catalogState.products
        .where((p) => p.id == widget.productId)
        .firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );
    final variant = product.variants
        .where((v) => v.size == selectedSize && v.color == selectedColor)
        .firstOrNull;
    final currentPrice = product.basePrice + (variant?.priceDifference ?? 0);
    final totalStock = product.variants.fold<int>(
      0,
      (total, item) => total + item.stockQuantity,
    );
    final sizes = product.variants.map((e) => e.size).toSet().toList();
    final colors = product.variants.map((e) => e.color).toSet().toList();
    final canAdd = sizes.isEmpty || colors.isEmpty
        ? product.isAvailable
        : selectedSize != null && selectedColor != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              ref.watch(favoriteControllerProvider);
              final isFavorite = ref
                  .read(favoriteControllerProvider.notifier)
                  .isFavorite(product.id);
              return IconButton(
                tooltip: 'Yêu thích',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.error : null,
                ),
                onPressed: () => ref
                    .read(favoriteControllerProvider.notifier)
                    .toggleFavorite(product.id),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final cartState = ref.watch(cartControllerProvider);
              final itemCount = cartState.items.fold<int>(
                0,
                (total, item) => total + item.quantity,
              );
              return IconButton(
                tooltip: 'Giỏ hàng',
                icon: Badge(
                  isLabelVisible: itemCount > 0,
                  label: Text(itemCount.toString()),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 148),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImageGallery(
              product: product,
              isDark: isDark,
              controller: _imagePageController,
              selectedIndex: selectedImageIndex,
              onChanged: (index) {
                setState(() => selectedImageIndex = index);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductInfoPanel(
                    product: product,
                    price: currencyFormatter.format(currentPrice),
                    totalStock: totalStock,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (sizes.isNotEmpty) ...[
                    _OptionGroup(
                      title: 'Size',
                      options: sizes,
                      selectedValue: selectedSize,
                      onSelected: (value) {
                        setState(() => selectedSize = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (colors.isNotEmpty) ...[
                    _OptionGroup(
                      title: 'Màu sắc',
                      options: colors,
                      selectedValue: selectedColor,
                      onSelected: (value) {
                        setState(() => selectedColor = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionCard(
                    title: 'Mô tả',
                    icon: Icons.notes_rounded,
                    child: Text(
                      product.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _BranchAvailabilitySection(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ProductActionBar(
        price: currencyFormatter.format(currentPrice),
        quantity: quantity,
        canAdd: canAdd,
        onDecrease: quantity > 1 ? () => setState(() => quantity--) : null,
        onIncrease: () => setState(() => quantity++),
        onAdd: () {
          if (sizes.isNotEmpty && colors.isNotEmpty && variant == null) {
            _snack(context, 'Vui lòng chọn đúng phân loại');
            return;
          }
          if (variant != null && variant.stockQuantity < quantity) {
            _snack(context, 'Số lượng trong kho không đủ');
            return;
          }

          final item = CartItem(
            id: '',
            productId: product.id,
            variantId: variant?.id ?? '',
            productName: product.name,
            imageUrl: product.images.isNotEmpty ? product.images.first : '',
            size: selectedSize ?? '',
            color: selectedColor ?? '',
            price: currentPrice,
            quantity: quantity,
            addedAt: DateTime.now(),
          );
          ref.read(cartControllerProvider.notifier).addToCart(item);
          _snack(context, 'Đã thêm vào giỏ hàng');
        },
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ProductImageGallery extends StatelessWidget {
  final Product product;
  final bool isDark;
  final PageController controller;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ProductImageGallery({
    required this.product,
    required this.isDark,
    required this.controller,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images = product.images.isNotEmpty
        ? product.images
        : const ['https://via.placeholder.com/800'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        children: [
          Hero(
            tag: 'product-${product.id}',
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      onPageChanged: onChanged,
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.primaryLight,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        );
                      },
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.04),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.22),
                          ],
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: _GlassPill(
                          text: '${selectedIndex + 1}/${images.length}',
                          icon: Icons.photo_library_outlined,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (images.length > 1)
            SizedBox(
              height: 88,
              child: ListView.separated(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final selected = selectedIndex == index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    onTap: () {
                      controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                      onChanged(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductInfoPanel extends StatelessWidget {
  final Product product;
  final String price;
  final int totalStock;

  const _ProductInfoPanel({
    required this.product,
    required this.price,
    required this.totalStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SoftChip(
                text: product.categoryId.toUpperCase(),
                icon: Icons.category_rounded,
              ),
              _SoftChip(
                text: totalStock > 0 ? 'Còn hàng' : 'Hết hàng',
                icon: totalStock > 0
                    ? Icons.verified_rounded
                    : Icons.remove_circle_outline_rounded,
                color: totalStock > 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            product.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _BranchAvailabilitySection extends StatelessWidget {
  final Product product;

  const _BranchAvailabilitySection({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<_BranchStock>>(
      future: _loadBranchStocks(product),
      builder: (context, snapshot) {
        final content = switch (snapshot.connectionState) {
          ConnectionState.waiting => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          ),
          _ when snapshot.hasError => Text(
            'Không tải được tồn kho chi nhánh',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
          _ when (snapshot.data ?? const []).isEmpty => const Text(
            'Chưa gán tồn kho cho chi nhánh nào.',
          ),
          _ => Column(
            children: snapshot.data!
                .map(
                  (stock) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _BranchStockTile(stock: stock),
                  ),
                )
                .toList(),
          ),
        };

        return _SectionCard(
          title: 'Tồn kho chi nhánh',
          icon: Icons.storefront_rounded,
          child: content,
        );
      },
    );
  }
}

class _BranchStockTile extends StatelessWidget {
  final _BranchStock stock;

  const _BranchStockTile({required this.stock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inStock = stock.stockQuantity > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: inStock
            ? AppColors.success.withValues(alpha: 0.07)
            : AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: inStock
              ? AppColors.success.withValues(alpha: 0.18)
              : AppColors.error.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: inStock ? AppColors.success : AppColors.error,
            child: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.branchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  stock.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            inStock ? '${stock.stockQuantity} cái' : 'Hết hàng',
            style: theme.textTheme.titleSmall?.copyWith(
              color: inStock ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  const _OptionGroup({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: Icons.tune_rounded,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((option) {
          final selected = selectedValue == option;
          return ChoiceChip(
            label: Text(option),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.borderLight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
            onSelected: (value) => onSelected(value ? option : null),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductActionBar extends StatelessWidget {
  final String price;
  final int quantity;
  final bool canAdd;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAdd;

  const _ProductActionBar({
    required this.price,
    required this.quantity,
    required this.canAdd,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Giảm',
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: onDecrease,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tăng',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: onIncrease,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                text: canAdd ? 'Thêm vào giỏ' : 'Chọn phân loại',
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                onPressed: canAdd ? onAdd : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _GlassPill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SoftChip({
    required this.text,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    border: Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

Future<List<_BranchStock>> _loadBranchStocks(Product product) async {
  final firestore = FirebaseFirestore.instance;
  final productDoc = await firestore
      .collection('products')
      .doc(product.id)
      .get();
  final productData = productDoc.data() ?? const <String, dynamic>{};
  final storesSnapshot = await firestore.collection('stores').get();

  final stores = <String, _BranchInfo>{};
  for (final doc in storesSnapshot.docs) {
    final data = doc.data();
    stores[doc.id] = _BranchInfo(
      id: doc.id,
      name: _stringValue(data['name'] ?? data['displayName'], 'Chi nhánh'),
      address: _stringValue(data['address'], 'Chưa cập nhật địa chỉ'),
      ownerUid: _stringValue(data['ownerUid'] ?? data['sellerId']),
    );
  }

  final entries = [
    ..._stockEntries(productData['branchInventory']),
    ..._stockEntries(productData['branchStocks']),
  ];

  final stocks = <_BranchStock>[];
  for (final entry in entries) {
    final branchId = _stringValue(
      entry['branchId'] ?? entry['storeId'] ?? entry['sellerId'],
    );
    final store = stores[branchId];
    stocks.add(
      _BranchStock(
        branchId: branchId,
        branchName: _stringValue(
          entry['branchName'] ?? entry['storeName'],
          store?.name ?? 'Chi nhánh',
        ),
        address: _stringValue(entry['address'], store?.address ?? ''),
        stockQuantity: _stockQuantityFromEntry(entry),
      ),
    );
  }

  if (stocks.isEmpty && product.sellerId.isNotEmpty) {
    final totalStock = product.variants.fold<int>(
      0,
      (total, variant) => total + variant.stockQuantity,
    );
    final directStore = stores[product.sellerId];
    final ownerStore = stores.values
        .where((store) => store.ownerUid == product.sellerId)
        .firstOrNull;
    final store = directStore ?? ownerStore;
    if (store != null) {
      stocks.add(
        _BranchStock(
          branchId: store.id,
          branchName: store.name,
          address: store.address,
          stockQuantity: totalStock,
        ),
      );
    }
  }

  stocks.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
  return stocks;
}

List<Map<String, dynamic>> _stockEntries(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

int _stockQuantityFromEntry(Map<String, dynamic> entry) {
  final direct =
      entry['stockQuantity'] ?? entry['totalStock'] ?? entry['stock'];
  if (direct is num) return direct.toInt();

  final variants = entry['variants'];
  if (variants is List) {
    return variants.fold<int>(0, (total, item) {
      if (item is! Map) return total;
      final stock = item['stockQuantity'] ?? item['stock'];
      return total + (stock is num ? stock.toInt() : 0);
    });
  }

  return 0;
}

class _BranchStock {
  final String branchId;
  final String branchName;
  final String address;
  final int stockQuantity;

  const _BranchStock({
    required this.branchId,
    required this.branchName,
    required this.address,
    required this.stockQuantity,
  });
}

class _BranchInfo {
  final String id;
  final String name;
  final String address;
  final String ownerUid;

  const _BranchInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.ownerUid,
  });
}

String _stringValue(Object? value, [String fallback = '']) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}
