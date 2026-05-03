class AppConstants {
  static const String APP_NAME = "PedidosApp";
  static const int APP_VERSION = 1;

  static const String BASE_URL = "https://crop-universities-bicycle-eating.trycloudflare.com";

  // Auth endpoints
  static const String LOGIN_URI = "/api/v1/auth/login";
  static const String REGISTER_URI = "/api/v1/auth/register";

  // Product endpoints
  static const String POPULAR_PRODUCT_URI = "/api/v1/products/popular";
  static const String RECOMMENDED_PRODUCT_URI = "/api/v1/products/all?type_id=3";
  static const String ALL_PRODUCTS_URI = "/api/v1/products/all";
  static const String PRODUCT_DETAIL_URI = "/api/v1/products/";

  // Customer endpoints
  static const String CUSTOMER_INFO_URI = "/api/v1/customer/info";
  static const String UPDATE_PROFILE_URI = "/api/v1/customer/update-profile";

  // Order endpoints
  static const String PLACE_ORDER_URI = "/api/v1/order/place";
  static const String ORDER_LIST_URI = "/api/v1/order/list";

  // Storage keys
  static const String TOKEN = "";
  static const String USER_KEY = "user_data";
}