import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/repository/branch_repo.dart';
import '../models/branch_model.dart';
import '../utils/app_constants.dart';
import 'popular_product_controller.dart';
import 'recommended_product_controller.dart';
import 'search_product_controller.dart';

class BranchController extends GetxController {
  final BranchRepo branchRepo;
  BranchController({required this.branchRepo});

  int _branchId = 2;
  String _branchName = "Cargando...";
  List<Branch> _branchList = [];
  bool _isLoaded = false;

  int get branchId => _branchId;
  String get branchName => _branchName;
  List<Branch> get branchList => _branchList;
  bool get isLoaded => _isLoaded;

  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadBranchId();
    getBranchList();
  }

  void _loadBranchId() {
    if (_storage.hasData(AppConstants.BRANCH_ID_KEY)) {
      _branchId = _storage.read(AppConstants.BRANCH_ID_KEY);
    }
  }

  Future<void> getBranchList() async {
    Response response = await branchRepo.getBranchList();
    if (response.statusCode == 200) {
      _branchList = [];
      // Suponiendo que Laravel responde con { "data": [...] }
      var list = response.body is List ? response.body : response.body['data'];
      if (list != null) {
        list.forEach((v) {
          _branchList.add(Branch.fromJson(v));
        });
      }
      
      // Actualizar el nombre según el ID guardado
      _updateBranchName();
      _isLoaded = true;
      update();
    }
  }

  void _updateBranchName() {
    try {
      _branchName = _branchList.firstWhere((b) => b.id == _branchId).name;
    } catch (e) {
      if (_branchList.isNotEmpty) {
        _branchId = _branchList[0].id;
        _branchName = _branchList[0].name;
      } else {
        _branchName = "Sin sucursales";
      }
    }
  }

  void setBranch(int id, String name) {
    _branchId = id;
    _branchName = name;
    _storage.write(AppConstants.BRANCH_ID_KEY, id);
    update();
    
    // Recargar productos automáticamente al cambiar de sucursal
    if (Get.isRegistered<PopularProductController>()) {
      Get.find<PopularProductController>().getPopularProductList();
    }
    if (Get.isRegistered<RecommendedProductController>()) {
      Get.find<RecommendedProductController>().getRecommendedProductList();
    }
    if (Get.isRegistered<SearchProductController>()) {
      Get.find<SearchProductController>().getCategories();
      Get.find<SearchProductController>().getFilteredProducts();
    }
  }
}
