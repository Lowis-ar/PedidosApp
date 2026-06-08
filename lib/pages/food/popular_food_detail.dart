import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/utils/dimensions.dart';
import 'package:pedidosapp/widgets/app_column.dart';
import 'package:pedidosapp/widgets/expandable_text_widget.dart';
import 'package:pedidosapp/widgets/review_widgets.dart';
import 'package:pedidosapp/helper/cart_animation_helper.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/popular_product_controller.dart';
import '../../data/repository/product_repo.dart';
import '../../models/product_model.dart';
import '../../routes/route_helper.dart';
import '../../utils/colors.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/big_text.dart';

class PopularFoodDetail extends StatefulWidget {
  final int pageId;

  const PopularFoodDetail({super.key, required this.pageId});

  @override
  State<PopularFoodDetail> createState() => _PopularFoodDetailState();
}

class _PopularFoodDetailState extends State<PopularFoodDetail> {
  ProductModel? _detailedProduct;
  bool _isLoading = true;
  final GlobalKey _cartKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    ProductModel baseProduct;
    if (Get.arguments != null && Get.arguments is ProductModel) {
      baseProduct = Get.arguments;
    } else {
      baseProduct = Get.find<PopularProductController>().popularProductList[widget.pageId];
    }

    final popularController = Get.find<PopularProductController>();
    popularController.initProduct(baseProduct, Get.find<CartController>());

    try {
      final productRepo = Get.find<ProductRepo>();
      final response = await productRepo.getProductDetail(baseProduct.id!);
      if (response.statusCode == 200 &&
          response.body != null &&
          response.body['success'] == true) {
        if (mounted) {
          setState(() {
            _detailedProduct = ProductModel.fromJson(response.body['data']);
            popularController.initProduct(
                _detailedProduct!, Get.find<CartController>());
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _detailedProduct = baseProduct;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detailedProduct = baseProduct;
          _isLoading = false;
        });
      }
    }
  }

  // ─── Reviews Modal ─────────────────────────────────────────────────────────

  void _showAllReviews(int productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewsBottomSheet(productId: productId),
    );
  }

  // ─── Sections ──────────────────────────────────────────────────────────────

  Widget _buildVariantsSection(
      ProductModel product, PopularProductController controller) {
    if (product.variants == null || product.variants!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(top: Dimensions.height20),
      padding: EdgeInsets.all(Dimensions.height15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radius15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: BigText(text: "Seleccioná una opción", size: Dimensions.font18),
              ),
              SizedBox(width: Dimensions.width10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Requerido",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            "Elige 1 opción",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          SizedBox(height: Dimensions.height10),
          Column(
            children: product.variants!.map((variant) {
              final isSelected = controller.selectedVariant?.id == variant.id;
              return GestureDetector(
                onTap: () => controller.selectVariant(variant),
                child: Container(
                  margin: EdgeInsets.only(bottom: Dimensions.height10),
                  padding: EdgeInsets.symmetric(
                      vertical: Dimensions.height10,
                      horizontal: Dimensions.width10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainColor.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(Dimensions.radius15 / 1.5),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.mainColor
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.mainColor
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.mainColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            SizedBox(width: Dimensions.width10),
                            Expanded(
                              child: Text(
                                variant.name ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: Dimensions.font16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: AppColors.mainBlackColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Dimensions.width10),
                      Text(
                        variant.priceModifier! >= 0
                            ? "+ \$ ${variant.priceModifier!.toStringAsFixed(2)}"
                            : "- \$ ${variant.priceModifier!.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: Dimensions.font16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.mainColor
                              : AppColors.paraColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasSection(
      ProductModel product, PopularProductController controller) {
    if (product.extras == null || product.extras!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(top: Dimensions.height20),
      padding: EdgeInsets.all(Dimensions.height15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radius15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: BigText(text: "Agregá complementos", size: Dimensions.font18),
              ),
              SizedBox(width: Dimensions.width10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Opcional",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.height10),
          Column(
            children: product.extras!.map((extra) {
              final qty = controller.extraQuantities[extra.id] ?? 0;
              final isSelected = qty > 0;
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.height10),
                padding: EdgeInsets.symmetric(
                    vertical: Dimensions.height10,
                    horizontal: Dimensions.width10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.mainColor.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(Dimensions.radius15 / 1.5),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.mainColor
                        : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: quantity controls + name
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => controller.setExtraQuantity(extra, false),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: qty > 0 ? AppColors.mainColor : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Icons.remove, size: 16, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: Dimensions.width10),
                          Text(
                            qty.toString(),
                            style: TextStyle(
                              fontSize: Dimensions.font16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainBlackColor,
                            ),
                          ),
                          SizedBox(width: Dimensions.width10),
                          GestureDetector(
                            onTap: () => controller.setExtraQuantity(extra, true),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: Dimensions.width15),
                          Expanded(
                            child: Text(
                              extra.name ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Dimensions.font16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.mainBlackColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: Dimensions.width10),
                    // Right: price
                    Text(
                      "+ \$ ${extra.price!.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: Dimensions.font16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.mainColor : AppColors.paraColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ProductModel product) {
    final reviews = product.reviews ?? [];
    final hasReviews = reviews.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(top: Dimensions.height30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BigText(text: "Opiniones del Plato", size: Dimensions.font18),
              if (product.id != null)
                GestureDetector(
                  onTap: () => _showAllReviews(product.id!),
                  child: Text(
                    "Mostrar todas",
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontSize: Dimensions.font16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: Dimensions.height15),
          if (!hasReviews)
            Container(
              padding: EdgeInsets.all(Dimensions.height20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(Dimensions.radius15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.star_border,
                        size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      "Sin opiniones aún",
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: Dimensions.font16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "¡Sé el primero en opinar!",
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return ReviewCard(review: review);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(PopularProductController controller) {
    final TextEditingController textController =
        TextEditingController(text: controller.notes);
    textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length));

    return Container(
      margin:
          EdgeInsets.only(top: Dimensions.height30, bottom: Dimensions.height30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BigText(text: "Notas para este producto", size: Dimensions.font18),
          const SizedBox(height: 4),
          Text(
            "El restaurante intentará seguirlas cuando lo prepare.",
            style: TextStyle(
                fontSize: Dimensions.font16 / 1.2,
                color: Colors.grey.shade500),
          ),
          SizedBox(height: Dimensions.height15),
          TextField(
            controller: textController,
            maxLines: 3,
            maxLength: 100,
            onChanged: (value) => controller.updateNotes(value),
            style: TextStyle(
                fontSize: Dimensions.font16, color: AppColors.mainBlackColor),
            decoration: InputDecoration(
              hintText: "Escribí las instrucciones que necesites.",
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: Dimensions.font16),
              counterText: "${controller.notes.length}/100",
              counterStyle:
                  TextStyle(color: Colors.grey.shade500, fontSize: 12),
              contentPadding: EdgeInsets.all(Dimensions.height15),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radius15),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radius15),
                borderSide: BorderSide(color: AppColors.mainColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ProductModel product;
    if (Get.arguments != null && Get.arguments is ProductModel) {
      product = Get.arguments;
    } else {
      product =
          Get.find<PopularProductController>().popularProductList[widget.pageId];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image
          Positioned(
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.maxFinite,
              height: Dimensions.popularFoodImgSize,
              child: CachedNetworkImage(
                imageUrl: product.img ?? "",
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: Dimensions.popularFoodImgSize,
                placeholder: (context, url) => Container(
                  width: double.maxFinite,
                  height: Dimensions.popularFoodImgSize,
                  color: Colors.grey.shade300,
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.maxFinite,
                  height: Dimensions.popularFoodImgSize,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          // Top icons
          Positioned(
            top: Dimensions.height45,
            left: Dimensions.width20,
            right: Dimensions.width20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const AppIcon(icon: Icons.arrow_back_ios),
                ),
                GetBuilder<PopularProductController>(builder: (controller) {
                  return GestureDetector(
                    key: _cartKey,
                    onTap: () {
                      if (controller.totalItems >= 1) {
                        Get.toNamed(RouteHelper.getCartPage());
                      }
                    },
                    child: Stack(
                      children: [
                        const AppIcon(icon: Icons.shopping_cart_outlined),
                        if (controller.totalItems >= 1)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: AppIcon(
                              icon: Icons.circle,
                              size: 20,
                              iconColor: Colors.transparent,
                              backgroundColor: AppColors.mainColor,
                            ),
                          ),
                        if (controller.totalItems >= 1)
                          Positioned(
                            right: 3,
                            top: 3,
                            child: BigText(
                              text: controller.totalItems.toString(),
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // White scrollable content sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: Dimensions.popularFoodImgSize - 20,
            child: Container(
              padding: EdgeInsets.only(
                left: Dimensions.width20,
                right: Dimensions.width20,
                top: Dimensions.height20,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(Dimensions.radius20),
                  topLeft: Radius.circular(Dimensions.radius20),
                ),
                color: Colors.white,
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.mainColor))
                  : GetBuilder<PopularProductController>(
                      builder: (popularProduct) {
                        final activeProduct = _detailedProduct ?? product;
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppColumn(
                                text: activeProduct.name ?? "",
                                stars: activeProduct.stars ?? 5.0,
                                category:
                                    activeProduct.category?.name ?? "General",
                                timePreparation: activeProduct.timePreparation,
                              ),
                              SizedBox(height: Dimensions.height20),
                              const BigText(text: "Introduce"),
                              SizedBox(height: Dimensions.height20),
                              ExpandableTextWidget(
                                  text: activeProduct.description ?? ""),
                              // ── Variantes
                              _buildVariantsSection(
                                  activeProduct, popularProduct),
                              // ── Extras
                              _buildExtrasSection(activeProduct, popularProduct),
                              // ── Opiniones
                              _buildReviewsSection(activeProduct),
                              // ── Notas
                              _buildNotesSection(popularProduct),
                              SizedBox(
                                  height: Dimensions.bottomHeightBar * 1.5),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          GetBuilder<PopularProductController>(builder: (popularProduct) {
        final activeProduct = _detailedProduct ?? product;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity row
            Container(
              padding: EdgeInsets.only(
                left: Dimensions.width20 * 2.5,
                right: Dimensions.width20 * 2.5,
                top: Dimensions.height10,
                bottom: Dimensions.height10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => popularProduct.setQuantity(false),
                    child: AppIcon(
                      iconSize: Dimensions.iconSize24,
                      icon: Icons.remove,
                      backgroundColor: AppColors.mainColor,
                      iconColor: Colors.white,
                      size: Dimensions.iconSize24 * 1.5,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      child: BigText(
                        text:
                            "\$ ${popularProduct.unitPrice.toStringAsFixed(2)} X ${popularProduct.inCartItems} ",
                        color: AppColors.mainBlackColor,
                        size: Dimensions.font26,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => popularProduct.setQuantity(true),
                    child: AppIcon(
                      iconSize: Dimensions.iconSize24,
                      icon: Icons.add,
                      backgroundColor: AppColors.mainColor,
                      iconColor: Colors.white,
                      size: Dimensions.iconSize24 * 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Add to cart bar
            Container(
              padding: EdgeInsets.only(
                top: Dimensions.height20,
                bottom: Dimensions.height20,
                left: Dimensions.width20,
                right: Dimensions.width20,
              ),
              decoration: BoxDecoration(
                color: AppColors.buttonBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radius20 * 2),
                  topRight: Radius.circular(Dimensions.radius20 * 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimensions.height15),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radius20),
                      color: Colors.white,
                    ),
                    child: Icon(Icons.favorite, color: AppColors.mainColor),
                  ),
                  Flexible(
                    child: GestureDetector(
                      key: _addButtonKey,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        CartAnimationHelper.runAddToCartAnimation(
                          context: context,
                          fromKey: _addButtonKey,
                          toKey: _cartKey,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mainColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onComplete: () {
                            popularProduct.addItem(activeProduct);
                          },
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(Dimensions.height15),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radius20),
                          color: AppColors.mainColor,
                        ),
                        child: FittedBox(
                          child: BigText(
                            text:
                                "\$ ${((popularProduct.unitPrice * popularProduct.inCartItems) + popularProduct.extrasPrice).toStringAsFixed(2)} | Agregar",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
