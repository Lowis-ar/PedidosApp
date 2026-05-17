
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repository/recommended_product_repo.dart';
import '../models/product_model.dart';

class RecommendedProductController extends GetxController{
  final RecommendedProductRepo recommendedProductRepo;
  RecommendedProductController({required this.recommendedProductRepo});
  List<ProductModel> _recommendedProductList = [];
  List<ProductModel> get recommendedProductList => _recommendedProductList;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;



  Future<void> getRecommendedProductList() async {
    debugPrint("Fetching recommended products...");
    Response response = await recommendedProductRepo.getRecommendedProductList();
    debugPrint("Recommended products response: ${response.statusCode} - ${response.body}");
    if (response.statusCode == 200) {
      _recommendedProductList = [];
      _recommendedProductList.addAll(Product.fromJson(response.body).products);
      _isLoaded = true;
      update();
    } else {
      debugPrint("Failed to load recommended products: ${response.statusCode}");
    }
  }
}