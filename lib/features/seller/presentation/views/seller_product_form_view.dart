import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../commerce/domain/models/category.dart';
import '../../../commerce/presentation/providers/commerce_providers.dart';
import '../providers/seller_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final sellerCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(catalogRepositoryProvider);
  final result = await repo.getCategories();
  return result.when(onSuccess: (list) => list, onFailure: (_) => []);
});

class SellerProductFormView extends ConsumerStatefulWidget {
  final Product? product; // null means create new product draft

  const SellerProductFormView({super.key, this.product});

  @override
  ConsumerState<SellerProductFormView> createState() =>
      _SellerProductFormViewState();
}

class _SellerProductFormViewState extends ConsumerState<SellerProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late String _productId;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategoryId;
  List<String> _images = [];
  List<ProductVariant> _variants = [];

  bool _simulateUploadFailure = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _productId = p.id;
      _nameController.text = p.name;
      _descController.text = p.description;
      _priceController.text = p.basePrice.toInt().toString();
      _selectedCategoryId = p.categoryId;
      _images = List.from(p.images);
      _variants = List.from(p.variants);
    } else {
      _productId = const Uuid().v4();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _uploadImage() async {
    // We mock picking an image and uploading it
    final mockPath =
        'picked_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final uploadedUrl = await ref
        .read(sellerProductControllerProvider.notifier)
        .uploadImageMock(mockPath, simulateFailure: _simulateUploadFailure);

    if (uploadedUrl != null) {
      setState(() {
        _images.add(uploadedUrl);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tải ảnh lên thành công!')),
        );
      }
    }
  }

  void _reorderImage(int index, bool moveLeft) {
    if (moveLeft && index > 0) {
      setState(() {
        final img = _images.removeAt(index);
        _images.insert(index - 1, img);
      });
    } else if (!moveLeft && index < _images.length - 1) {
      setState(() {
        final img = _images.removeAt(index);
        _images.insert(index + 1, img);
      });
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        ProductVariant(
          id: const Uuid().v4(),
          size: '',
          color: '',
          sku: '',
          stockQuantity: 0,
          priceDifference: 0.0,
        ),
      );
    });
  }

  void _deleteVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final double? basePrice = double.tryParse(_priceController.text.trim());
      if (basePrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giá tiền cơ bản không hợp lệ'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm phải có ít nhất 1 biến thể'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final sellerId = ref.read(authStateProvider).uid;

      final draftProduct = Product(
        id: _productId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId ?? '',
        basePrice: basePrice,
        sellerId: sellerId,
        status: widget.product?.status ?? ProductStatus.draft,
        rejectReason: widget.product?.rejectReason,
        images: _images,
        isAvailable: true,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        variants: _variants,
      );

      ref
          .read(sellerProductControllerProvider.notifier)
          .saveProductDraft(draftProduct)
          .then((success) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã lưu sản phẩm nháp thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(sellerCategoriesProvider);
    final state = ref.watch(sellerProductControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to error notifications
    ref.listen(sellerProductControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              widget.product == null
                  ? 'Thêm Sản phẩm Nháp'
                  : 'Chỉnh sửa Sản phẩm',
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reject Reason Banner
                  if (widget.product != null &&
                      widget.product!.status == ProductStatus.rejected &&
                      widget.product!.rejectReason != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.report_problem_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                'Sản phẩm bị từ chối duyệt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.product!.rejectReason!,
                            style: TextStyle(
                              color: isDark ? Colors.red[100] : Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Text(
                    'Thông tin chung',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AppTextField(
                    controller: _nameController,
                    labelText: 'Tên sản phẩm',
                    hintText: 'Nhập tên sản phẩm giày/dép',
                    prefixIcon: const Icon(
                      Icons.abc_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Tên sản phẩm không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _descController,
                    labelText: 'Mô tả chi tiết',
                    hintText: 'Chất liệu, màu sắc, phom dáng...',
                    maxLines: 4,
                    prefixIcon: const Icon(
                      Icons.description_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Mô tả sản phẩm không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Không thể tải danh mục: $e'),
                    data: (categories) {
                      return DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(
                            Icons.category_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng chọn danh mục';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _priceController,
                    labelText: 'Giá niêm yết cơ bản (VND)',
                    hintText: 'Ví dụ: 850000',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Giá cơ bản không được để trống';
                      }
                      final intVal = int.tryParse(val.trim());
                      if (intVal == null) {
                        return 'Giá bán phải là số nguyên (VND)';
                      }
                      if (intVal < 0) {
                        return 'Giá bán không được âm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Image Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hình ảnh sản phẩm',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Giả lập lỗi upload',
                            style: TextStyle(fontSize: 12),
                          ),
                          Checkbox(
                            value: _simulateUploadFailure,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _simulateUploadFailure = val ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildImagesList(),
                  const SizedBox(height: AppSpacing.xl),

                  // Variants Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biến thể sản phẩm',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addVariant,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Thêm biến thể'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildVariantsList(),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: widget.product == null
                          ? 'Lưu sản phẩm nháp'
                          : 'Cập nhật sản phẩm',
                      onPressed: _saveProduct,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
        if (state.isLoading)
          const LoadingView(message: 'Đang xử lý sản phẩm...', isOverlay: true),
      ],
    );
  }

  Widget _buildImagesList() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + 1,
        itemBuilder: (context, index) {
          if (index == _images.length) {
            // Upload button
            return InkWell(
              onTap: _uploadImage,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tải ảnh lên',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            );
          }

          final imageUrl = _images[index];
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[350]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
              // Delete overlay button
              Positioned(
                top: 4,
                right: 12,
                child: InkWell(
                  onTap: () => _deleteImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Reorder buttons overlay at bottom
              Positioned(
                bottom: 4,
                left: 4,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (index > 0)
                      InkWell(
                        onTap: () => _reorderImage(index, true),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    if (index < _images.length - 1)
                      InkWell(
                        onTap: () => _reorderImage(index, false),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVariantsList() {
    if (_variants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.grey[100]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Chưa có biến thể nào. Vui lòng thêm biến thể (ví dụ: Size 40, màu Đen).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _variants.length,
      itemBuilder: (context, index) {
        final variant = _variants[index];
        return Card(
          key: ValueKey(variant.id),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biến thể #${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                      ),
                      onPressed: () => _deleteVariant(index),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: TextEditingController(text: variant.size),
                        labelText: 'Kích cỡ (Size)',
                        hintText: '38, 39...',
                        onChanged: (val) {
                          _variants[index] = _variants[index].copyWith(
                            size: val.trim(),
                          );
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: TextEditingController(text: variant.color),
                        labelText: 'Màu sắc',
                        hintText: 'Đen, Trắng...',
                        onChanged: (val) {
                          _variants[index] = _variants[index].copyWith(
                            color: val.trim(),
                          );
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: TextEditingController(text: variant.sku),
                  labelText: 'Mã SKU cửa hàng (Duy nhất)',
                  hintText: 'G-SHOE-39-BLACK',
                  onChanged: (val) {
                    _variants[index] = _variants[index].copyWith(
                      sku: val.trim(),
                    );
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập SKU';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: TextEditingController(
                          text: variant.stockQuantity.toString(),
                        ),
                        labelText: 'Tồn kho',
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final stock = int.tryParse(val) ?? 0;
                          _variants[index] = _variants[index].copyWith(
                            stockQuantity: stock,
                          );
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          final stock = int.tryParse(val);
                          if (stock == null) {
                            return 'Số nguyên';
                          }
                          if (stock < 0) {
                            return 'Không âm';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: TextEditingController(
                          text: variant.priceDifference.toInt().toString(),
                        ),
                        labelText: 'Chênh lệch giá (VND)',
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final priceDiff = double.tryParse(val) ?? 0.0;
                          _variants[index] = _variants[index].copyWith(
                            priceDifference: priceDiff,
                          );
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Bắt buộc';
                          }
                          final priceDiff = int.tryParse(val);
                          if (priceDiff == null) {
                            return 'Số nguyên';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
