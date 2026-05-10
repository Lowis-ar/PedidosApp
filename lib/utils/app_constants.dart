class AppConstants {
  static const String APP_NAME = "PedidosApp";
  static const int APP_VERSION = 1;

  // Cambiado para pruebas locales en Emulador de Android
  static const String BASE_URL = "http://10.0.2.2/pedidos_app/public";

  // Auth endpoints
  static const String LOGIN_URI = "/api/v1/auth/login";
  static const String REGISTER_URI = "/api/v1/auth/register";
  static const String LOGOUT_URI = "/api/v1/auth/logout";

  // Product endpoints
  static const String POPULAR_PRODUCT_URI = "/api/v1/products";
  static const String RECOMMENDED_PRODUCT_URI = "/api/v1/products";
  static const String ALL_PRODUCTS_URI = "/api/v1/products";
  static const String PRODUCT_DETAIL_URI = "/api/v1/products/";

  // Categories endpoints
  static const String CATEGORIES_URI = "/api/v1/categories";

  // Customer endpoints
  static const String CUSTOMER_INFO_URI = "/api/v1/auth/me";
  static const String UPDATE_PROFILE_URI = "/api/v1/auth/update-profile";

  // Addresses endpoints
  static const String ADDRESSES_URI = "/api/v1/addresses";

  // Zones endpoints
  static const String ZONES_URI = "/api/v1/zones";

  // Branches endpoints (NUEVO)
  static const String BRANCHES_URI = "/api/v1/branches";

  // Order endpoints
  static const String PLACE_ORDER_URI = "/api/v1/orders";
  static const String ORDER_LIST_URI = "/api/v1/orders";
  static const String CANCEL_ORDER_URI = "/api/v1/orders/";

  // Storage keys
  static const String TOKEN = "";
  static const String USER_KEY = "user_data";

  // Storage key para guardar la sucursal seleccionada (NUEVO)
  static const String BRANCH_ID_KEY = "branch_id";
}
