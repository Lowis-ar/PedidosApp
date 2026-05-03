import 'package:get/get.dart';

class Dimensions {
  static double get screenHeight => Get.context != null && Get.context!.height > 0 ? Get.context!.height : 844.0;
  static double get screenWidth => Get.context != null && Get.context!.width > 0 ? Get.context!.width : 390.0;

  static double get pageViewContainer => screenHeight / 3.84;
  static double get pageViewTextContainer => screenHeight / 7.03;
  static double get pageView => screenHeight / 2.64;

  //height dinamico para padding y margen
  static double get height10 => screenHeight / 84.4;
  static double get height15 => screenHeight / 56.27;
  static double get height20 => screenHeight / 42.2;
  static double get height30 => screenHeight / 28.13;
  static double get height45 => screenHeight / 18.76;

  //width dinamico para padding y margen
  static double get width10 => screenHeight / 84.4;
  static double get width15 => screenHeight / 56.27;
  static double get width20 => screenHeight / 42.2;
  static double get width30 => screenHeight / 28.13;

  //tamaño letra
  static double get font20 => screenHeight / 42.2;
  static double get font26 => screenHeight / 32.46;
  static double get font16 => screenHeight / 52.75;
  static double get font18 => screenHeight / 41.28;

  static double get radius20 => screenHeight / 42.2;
  static double get radius30 => screenHeight / 28.13;
  static double get radius15 => screenHeight / 56.27;

  //size de iconos
  static double get iconSize24 => screenHeight / 35.17;
  static double get iconSize16 => screenHeight / 52.75;
  static double get iconSize26 => screenHeight / 39.04;

  //listView
  static double get listViewImgSize => screenWidth / 3.25;
  static double get listViewTextContSize => screenWidth / 3.9;

  //popular food
  static double get popularFoodImgSize => screenHeight / 2.41;

  //botones
  static double get bottomHeightBar => screenHeight / 7.03;
}

