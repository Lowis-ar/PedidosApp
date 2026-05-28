import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/repository/branch_repo.dart';
import '../data/repository/product_repo.dart';
import '../models/branch_model.dart';
import '../utils/app_constants.dart';
import '../utils/colors.dart';
import 'cart_controller.dart';
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

  Future<void> setBranch(int id, String name) async {
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

    // Filtrar el carrito según disponibilidad en la nueva sucursal
    await _filterCartForBranch(id);
  }

  /// Consulta los productos disponibles en [branchId], compara con el carrito
  /// actual y elimina los que no están disponibles. Muestra un diálogo si se
  /// removieron productos.
  Future<void> _filterCartForBranch(int branchId) async {
    try {
      if (!Get.isRegistered<CartController>()) return;
      final cartController = Get.find<CartController>();

      // Nada que verificar si el carrito está vacío
      if (cartController.items.isEmpty) return;

      // Obtener IDs disponibles en la nueva sucursal
      if (!Get.isRegistered<ProductRepo>()) return;
      final productRepo = Get.find<ProductRepo>();
      final availableIds = await productRepo.getProductIdsByBranch(branchId);

      // Si no se pudo obtener la lista (error de red), no tocar el carrito
      if (availableIds == null) return;

      final availableSet = availableIds.toSet();

      // Detectar IDs del carrito que NO están en la sucursal nueva
      final List<int> toRemove = cartController.items.values
          .where((item) {
            final pid = item.product?.id;
            return pid != null && !availableSet.contains(pid);
          })
          .map((item) => item.product!.id!)
          .toSet()
          .toList();

      if (toRemove.isEmpty) return;

      // Eliminar y obtener nombres para mostrar en la alerta
      final removedNames = cartController.removeItemsByProductIds(toRemove);

      // Mostrar diálogo informativo
      _showUnavailableProductsDialog(removedNames);
    } catch (e) {
      debugPrint('BranchController._filterCartForBranch error: $e');
    }
  }

  void _showUnavailableProductsDialog(List<String> productNames) {
    final context = Get.overlayContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Productos no disponibles',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Los siguientes productos no están disponibles en esta sucursal y fueron eliminados del carrito:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ...productNames.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mainColor,
            ),
            child: const Text('Entendido',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
