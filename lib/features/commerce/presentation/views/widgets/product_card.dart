import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/product.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _imageIndex = 0;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : const ['https://via.placeholder.com/400x400.png?text=Khong+co+anh'];
    final totalStock = widget.product.variants.fold<int>(
      0,
      (total, variant) => total + variant.stockQuantity,
    );

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'product-${widget.product.id}',
                            child: PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _imageIndex = index);
                              },
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
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.04),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: AppSpacing.xs,
                            left: AppSpacing.xs,
                            child: _GlassPill(
                              text: totalStock > 0 ? 'Còn hàng' : 'Hết hàng',
                              icon: totalStock > 0
                                  ? Icons.verified_rounded
                                  : Icons.remove_shopping_cart_rounded,
                            ),
                          ),
                          if (images.length > 1)
                            Positioned(
                              left: AppSpacing.xs,
                              bottom: AppSpacing.xs,
                              child: _GlassPill(
                                text: '${_imageIndex + 1}/${images.length}',
                                icon: Icons.photo_library_outlined,
                              ),
                            ),
                          Positioned(
                            top: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: _IconSurface(
                              isDark: isDark,
                              onTap: widget.onFavoriteToggle,
                              icon: widget.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: widget.isFavorite ? AppColors.error : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currencyFormatter.format(
                                  widget.product.basePrice,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? AppColors.textDarkPrimary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.textLightMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
        border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconSurface extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? color;

  const _IconSurface({
    required this.isDark,
    required this.onTap,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.86)
          : Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: color ?? (isDark ? Colors.white : AppColors.primary),
          ),
        ),
      ),
    );
  }
}
