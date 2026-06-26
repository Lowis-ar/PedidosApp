import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../controllers/search_product_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../widgets/big_text.dart';
import '../../widgets/small_text.dart';
import '../../routes/route_helper.dart';
import '../../utils/app_snackbar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos desde la API
    Get.find<SearchProductController>().getCategories();
    Get.find<SearchProductController>().getFilteredProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(Dimensions.radius20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => Get.find<SearchProductController>().setSearchQuery(value),
            decoration: InputDecoration(
              hintText: "Buscar en ${Get.find<BranchController>().branchName}",
              hintStyle: TextStyle(color: Colors.grey, fontSize: Dimensions.font16),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Filtro de Categorías Dinámico (Cargado desde la API)
          Container(
            padding: EdgeInsets.only(left: Dimensions.width20, top: 10),
            alignment: Alignment.centerLeft,
            child:  SmallText(text: "Categorías", color: Colors.black54),
          ),
          GetBuilder<SearchProductController>(builder: (searchController) {
            if (!searchController.isCategoriesLoaded) {
              return const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.width20, vertical: 5),
              child: Row(
                children: searchController.categoryList.map((category) {
                  return _categoryChip(category.name ?? "S/N", category.id!);
                }).toList(),
              ),
            );
          }),

          // 2. Filtros de ordenamiento
          Container(
            padding: EdgeInsets.only(left: Dimensions.width20, top: 5),
            alignment: Alignment.centerLeft,
            child:  SmallText(text: "Ordenar por", color: Colors.black54),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Dimensions.width20, vertical: 5),
            child: Row(
              children: [
                _sortChip("Todos", null),
                _sortChip("Más vendidos", "most_sold"),
                _sortChip("Precio Bajo", "price_low"),
                _sortChip("Precio Alto", "price_high"),
              ],
            ),
          ),
          const Divider(),
          
          // 3. Lista de resultados interactiva
          Expanded(
            child: GetBuilder<SearchProductController>(builder: (searchController) {
              if (!searchController.isLoaded) {
                return  Center(child: CircularProgressIndicator(color: AppColors.mainColor));
              }
              
              if (searchController.productList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                      const BigText(text: "Sin resultados", color: Colors.grey),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: searchController.productList.length,
                itemBuilder: (context, index) {
                  var product = searchController.productList[index];
                  return Container(
                    margin: EdgeInsets.only(left: Dimensions.width20, right: Dimensions.width20, bottom: 15),
                    child: Row(
                      children: [
                        // Imagen interactiva -> Navegación al detalle con argumento del producto
                        GestureDetector(
                          onTap: () {
                             Get.toNamed(RouteHelper.getPopularFood(0), arguments: product);
                          },
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radius20),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radius20),
                              child: CachedNetworkImage(
                                imageUrl: product.img ?? "",
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                memCacheWidth: 300,
                                placeholder: (context, url) => Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.mainColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Información interactiva
                        Expanded(
                          child: Container(
                            height: 110,
                            padding: const EdgeInsets.only(left: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => Get.toNamed(RouteHelper.getPopularFood(0), arguments: product),
                                  child: BigText(text: product.name ?? "Producto"),
                                ),
                                SmallText(text: product.category?.name ?? "General"),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    BigText(text: "\$ ${product.price}", color: Colors.redAccent),
                                    // BOTÓN AGREGAR AL CARRITO FUNCIONAL
                                    GestureDetector(
                                      onTap: () {
                                        searchController.addToCart(product);
                                        AppSnackbar.success('Agregado',
                                            '${product.name} al carrito',
                                            duration: const Duration(seconds: 1));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.mainColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(Dimensions.radius15),
                                        ),
                                        child:  Icon(Icons.add_shopping_cart, color: AppColors.mainColor, size: 22),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, int id) {
    return GetBuilder<SearchProductController>(builder: (controller) {
      bool isSelected = controller.selectedCategoryId == id;
      return GestureDetector(
        onTap: () => controller.setCategory(id),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor : Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radius20),
            border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.5)),
          ),
          child: SmallText(text: label, color: isSelected ? Colors.white : Colors.black87),
        ),
      );
    });
  }

  Widget _sortChip(String label, String? sortBy) {
    return GetBuilder<SearchProductController>(builder: (controller) {
      bool isSelected = controller.sortBy == sortBy;
      return GestureDetector(
        onTap: () => controller.setSortBy(sortBy),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor.withValues(alpha: 0.8) : AppColors.mainColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radius20),
          ),
          child: SmallText(text: label, color: isSelected ? Colors.white : Colors.black87),
        ),
      );
    });
  }
}
