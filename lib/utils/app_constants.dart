// ignore_for_file: constant_identifier_names

class AppConstants {
  static const String APP_NAME = "PedidosApp";
  static const int APP_VERSION = 1;

  // Production API behind Cloudflare tunnel
  static const String BASE_URL = "https://publication-missed-introduce-communist.trycloudflare.com";

  // Auth endpoints
  static const String LOGIN_URI = "/api/v1/auth/login";
  static const String REGISTER_URI = "/api/v1/auth/register";
  static const String FORGOT_PASSWORD_URI = "/api/v1/auth/forgot-password";
  static const String RESET_PASSWORD_URI = "/api/v1/auth/reset-password";
  static const String VERIFY_EMAIL_URI = "/api/v1/auth/verify-email";

  // Product endpoints
  static const String POPULAR_PRODUCT_URI = "/api/v1/products?popular=true";
  static const String RECOMMENDED_PRODUCT_URI = "/api/v1/products?recommended=true";
  static const String ALL_PRODUCTS_URI = "/api/v1/products";
  static const String PRODUCT_DETAIL_URI = "/api/v1/products/";
  static const String PRODUCT_REVIEWS_URI = "/api/v1/products/"; // append: {id}/reviews

  // Customer endpoints
  static const String CUSTOMER_INFO_URI = "/api/v1/auth/me";
  static const String UPDATE_PROFILE_URI = "/api/v1/auth/update-profile";
  static const String CHANGE_PASSWORD_URI = "/api/v1/auth/change-password";

  // Addresses endpoints
  static const String ADDRESSES_URI = "/api/v1/addresses";
  static const String ZONES_URI = "/api/v1/zones";

  // Order endpoints
  static const String PLACE_ORDER_URI = "/api/v1/orders";
  static const String ORDER_LIST_URI = "/api/v1/orders";
  static const String ORDER_DETAIL_URI = "/api/v1/orders/";
  static const String CANCEL_ORDER_URI = "/api/v1/orders/";

  // Delivery endpoints
  static const String DELIVERY_LOGIN_URI = "/api/v1/delivery/auth/login";
  static const String DELIVERY_LOGOUT_URI = "/api/v1/delivery/auth/logout";
  static const String DELIVERY_PROFILE_URI = "/api/v1/delivery/auth/me";
  static const String DELIVERY_UPDATE_PROFILE_URI = "/api/v1/delivery/auth/update-profile";
  
  static const String DELIVERY_AVAILABLE_ORDERS_URI = "/api/v1/delivery/orders/available";
  static const String DELIVERY_ACCEPT_ORDER_URI = "/api/v1/delivery/orders/"; // {order_id}/accept
  static const String DELIVERY_ACTIVE_ORDERS_URI = "/api/v1/delivery/orders/active";
  static const String DELIVERY_ORDER_STATUS_UPDATE_URI = "/api/v1/delivery/orders/"; // {order_id}/status
  static const String DELIVERY_VERIFY_OTP_URI = "/api/v1/delivery/orders/"; // {order_id}/verify-otp
  static const String DELIVERY_HISTORY_ORDERS_URI = "/api/v1/delivery/orders/history";
  static const String DELIVERY_ORDER_LIST_URI = "/api/v1/delivery/orders";

  // Storage keys
  static const String TOKEN = "token";
  static const String USER_KEY = "user_data";
  static const String DELIVERY_USER_KEY = "delivery_user_data";
  static const String DELIVERY_TOKEN = "delivery_token";

  // Branches - not in new API docs, keep for future use
  static const String BRANCHES_URI = "/api/v1/branches";
  static const String BRANCH_ID_KEY = "branch_id";
  static const String CATEGORIES_URI = "/api/v1/categories";
}
