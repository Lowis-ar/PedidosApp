import 'package:flutter/material.dart';
import '../cart/cart_page.dart';
import 'main_food_page.dart';
import 'order_history_page.dart';
import '../profile/profile_page.dart';
import '../../utils/colors.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/popular_product_controller.dart';
import '../../controllers/recommended_product_controller.dart';
import '../../controllers/review_controller.dart';
import '../../controllers/auth_controller.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    // Force AuthController initialization to load token
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().getCartData();
      }
      if (Get.isRegistered<PopularProductController>()) {
        Get.find<PopularProductController>().getPopularProductList();
      }
      if (Get.isRegistered<RecommendedProductController>()) {
        Get.find<RecommendedProductController>().getRecommendedProductList();
      }
    });
  }

  final List<Widget> _pages = const [
    MainFoodPage(),
    OrderHistoryPage(),
    CartPage(showHeader: false),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() {
          // ── Badge count from ReviewController ──────────────────────
          final reviewCtrl = Get.isRegistered<ReviewController>()
              ? Get.find<ReviewController>()
              : null;
          final pendingCount = reviewCtrl?.pendingReviews.length ?? 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.mainColor,
            unselectedItemColor: AppColors.textColor,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              // ── Orders tab with badge ──────────────────────────────
              BottomNavigationBarItem(
                icon: pendingCount > 0
                    ? Badge(
                        label: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.receipt_long_outlined),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                activeIcon: pendingCount > 0
                    ? Badge(
                        label: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.receipt_long),
                      )
                    : const Icon(Icons.receipt_long),
                label: 'Pedidos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Carrito',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          );
        }),
      ),
    );
  }
}
