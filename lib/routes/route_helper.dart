import 'package:get/get.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/cart/cart_page.dart';
import '../pages/food/popular_food_detail.dart';
import '../pages/food/recommended_food_detail.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';

class RouteHelper {
  static const String initial = "/";
  static const String login = "/login";
  static const String register = "/register";
  static const String popularFood = "/popular-food";
  static const String recommendedFood = "/recommended-food";
  static const String cartPage = "/cart-page";
  static const String profilePage = "/profile";

  static String getInitial() => initial;
  static String getLogin() => login;
  static String getRegister() => register;
  static String getPopularFood(int pageId) => '$popularFood?pageId=$pageId';
  static String getRecommendedFood(int pageid) => '$recommendedFood?pageid=$pageid';
  static String getCartPage() => cartPage;
  static String getProfilePage() => profilePage;

  static List<GetPage> routes = [
    GetPage(
      name: initial,
      page: () => const HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: popularFood,
      page: () {
        var pageId = Get.parameters['pageId'];
        return PopularFoodDetail(pageId: int.parse(pageId!));
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recommendedFood,
      page: () {
        var pageId = Get.parameters['pageid'];
        return RecommendedFoodDetail(pageId: int.parse(pageId!));
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: cartPage,
      page: () => const CartPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: profilePage,
      page: () => const ProfilePage(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}