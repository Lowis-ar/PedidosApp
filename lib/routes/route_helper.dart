import 'package:get/get.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/auth/reset_password_page.dart';
import '../pages/auth/verify_email_page.dart';
import '../pages/cart/cart_page.dart';
import '../pages/cart/checkout_page.dart';
import '../pages/food/popular_food_detail.dart';
import '../pages/food/recommended_food_detail.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/search/search_page.dart';
import '../pages/delivery/delivery_login_page.dart';
import '../pages/delivery/delivery_dashboard.dart';
import '../pages/delivery/delivery_history.dart';
import '../pages/delivery/delivery_profile.dart';
import '../pages/delivery/delivery_order_detail.dart';
import '../pages/review/review_delivery_page.dart';

class RouteHelper {
  static const String initial = "/";
  static const String login = "/login";
  static const String register = "/register";
  static const String forgotPassword = "/forgot-password";
  static const String resetPassword = "/reset-password";
  static const String verifyEmail = "/verify-email";
  static const String popularFood = "/popular-food";
  static const String recommendedFood = "/recommended-food";
  static const String cartPage = "/cart-page";
  static const String checkout = "/checkout";
  static const String profilePage = "/profile";
  static const String searchPage = "/search";

  // Delivery routes
  static const String deliveryLogin = "/delivery-login";
  static const String deliveryDashboard = "/delivery-dashboard";
  static const String deliveryHistory = "/delivery-history";
  static const String deliveryProfile = "/delivery-profile";
  static const String deliveryOrderDetail = "/delivery-order-detail";
  static const String reviewDelivery = "/review-delivery";

  static String getInitial({int pageId = 0}) => '$initial?pageId=$pageId';
  static String getLogin() => login;
  static String getRegister() => register;
  static String getForgotPassword() => forgotPassword;
  static String getResetPassword(String email) => '$resetPassword?email=$email';
  static String getVerifyEmail() => verifyEmail;
  static String getPopularFood(int pageId) => '$popularFood?pageId=$pageId';
  static String getRecommendedFood(int pageid) => '$recommendedFood?pageid=$pageid';
  static String getCartPage() => cartPage;
  static String getCheckout() => checkout;
  static String getProfilePage() => profilePage;
  static String getSearchPage() => searchPage;

  static String getDeliveryLogin() => deliveryLogin;
  static String getDeliveryDashboard() => deliveryDashboard;
  static String getDeliveryHistory() => deliveryHistory;
  static String getDeliveryProfile() => deliveryProfile;
  static String getDeliveryOrderDetail() => deliveryOrderDetail;
  static String getReviewDelivery() => reviewDelivery;

  static List<GetPage> routes = [
    GetPage(
      name: initial,
      page: () {
        int pageId = Get.parameters['pageId'] != null ? int.parse(Get.parameters['pageId']!) : 0;
        return HomePage(initialIndex: pageId);
      },
      transition: Transition.fade,
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
      name: forgotPassword,
      page: () => const ForgotPasswordPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: resetPassword,
      page: () {
        var email = Get.parameters['email'];
        return ResetPasswordPage(email: email ?? "");
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: verifyEmail,
      page: () => const VerifyEmailPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: popularFood,
      page: () {
        var pageId = Get.parameters['pageId'];
        return PopularFoodDetail(pageId: int.parse(pageId ?? "0"));
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: recommendedFood,
      page: () {
        var pageId = Get.parameters['pageid'];
        return RecommendedFoodDetail(pageId: int.parse(pageId ?? "0"));
      },
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: cartPage,
      page: () => const CartPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: profilePage,
      page: () => const ProfilePage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: searchPage,
      page: () => const SearchPage(),
      transition: Transition.downToUp,
    ),
    // Delivery Pages
    GetPage(
      name: deliveryLogin,
      page: () => const DeliveryLoginPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: deliveryDashboard,
      page: () => const DeliveryDashboard(),
      transition: Transition.fade,
    ),
    GetPage(
      name: deliveryHistory,
      page: () => const DeliveryHistoryPage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: deliveryProfile,
      page: () => const DeliveryProfilePage(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: deliveryOrderDetail,
      page: () => const DeliveryOrderDetailPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: reviewDelivery,
      page: () => const ReviewDeliveryPage(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
