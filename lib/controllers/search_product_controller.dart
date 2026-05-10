import 'package:get/get.dart';
import '../data/repository/product_repo.dart';
import '../models/product_model.dart';
import 'branch_controller.dart';
import 'cart_controller.dart';

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
    // Carga inicial al arrancar
    getCategories();
    getFilteredProducts();
  }

  Future<void> getCategories() async {
    _isCategoriesLoaded = false;
    update();
    try {
      int branchId = Get.find<BranchController>().branchId;
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
      print("Error cargando categorías: $e");
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
    // Si toca la misma categoría, la deseleccionamos
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
      int branchId = Get.find<BranchController>().branchId;
      Response response = await productRepo.getProductList(
        branchId: branchId,
        categoryId: _selectedCategoryId,
        search: _searchQuery,
        sortBy: _sortBy,
      );

      if (response.statusCode == 200) {
        _productList = [];
        _productList.addAll(Product.fromJson(response.body).products);
      }
    } catch (e) {
      print("Error en búsqueda: $e");
    } finally {
      _isLoaded = true;
      update();
    }
  }

  void addToCart(ProductModel product) {
    Get.find<CartController>().addItem(product, 1);
  }
}
