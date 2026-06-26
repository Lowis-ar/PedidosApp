import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/repository/product_repo.dart';
import '../models/product_model.dart';
import 'branch_controller.dart';
import 'cart_controller.dart';
import '../utils/app_snackbar.dart';

class SearchProductController extends GetxController {
  final ProductRepo productRepo;
  SearchProductController({required this.productRepo});

  List<ProductModel> _productList = [];
  List<ProductModel> get productList => _productList;

  List<CategoryModel> _categoryList = [];
  List<CategoryModel> get categoryList => _categoryList;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _isCategoriesLoaded = false;
  bool get isCategoriesLoaded => _isCategoriesLoaded;

  String _searchQuery = "";
  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;
  
  String? _sortBy;
  String? get sortBy => _sortBy;

  @override
  void onInit() {
    super.onInit();
    getCategories();
    getFilteredProducts();
  }

  Future<void> getCategories() async {
    _isCategoriesLoaded = false;
    update();
    try {
      // Try to get branchId from BranchController, default to 1
      int branchId = 2;
      try {
        if (Get.isRegistered<BranchController>()) {
          final controller = Get.find<BranchController>();
          branchId = controller.isLoaded ? controller.branchId : 2;
        }
      } catch (_) {}
      
      Response response = await productRepo.getCategoryList(branchId);
      if (response.statusCode == 200) {
        _categoryList = [];
        var list = response.body is List ? response.body : response.body['data'];
        if (list != null) {
          for (var v in list) {
            _categoryList.add(CategoryModel.fromJson(v));
          }
        }
      }
    } catch (e) {
      // Categories are optional, don't crash if they fail
    } finally {
      _isCategoriesLoaded = true;
      update();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    getFilteredProducts();
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = (_selectedCategoryId == categoryId) ? null : categoryId;
    getFilteredProducts();
  }

  void setSortBy(String? sort) {
    _sortBy = (_sortBy == sort) ? null : sort;
    getFilteredProducts();
  }

  Future<void> getFilteredProducts() async {
    _isLoaded = false;
    update();

    try {
      int? branchId;
      try {
        if (Get.isRegistered<BranchController>()) {
          final controller = Get.find<BranchController>();
          branchId = controller.isLoaded ? controller.branchId : 2;
        }
      } catch (_) {}

      Response response = await productRepo.getProductList(
        branchId: branchId,
        categoryId: _selectedCategoryId,
        search: _searchQuery,
        sortBy: _sortBy,
      );

      debugPrint("[SearchProductController] getProductList response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        _productList = [];
        _productList.addAll(Product.fromJson(response.body).products);
      } else {
        debugPrint("[SearchProductController] Failed to load filtered products: ${response.statusCode} - ${response.statusText}");
        AppSnackbar.error('Error', 'No se pudieron cargar los productos del buscador');
      }
    } catch (e) {
      debugPrint("[SearchProductController] Exception in getFilteredProducts: $e");
      AppSnackbar.error('Error', 'Ocurrió un error al filtrar los productos');
    } finally {
      _isLoaded = true;
      update();
    }
  }

  void addToCart(ProductModel product) {
    Get.find<CartController>().addItem(product, 1);
  }
}
