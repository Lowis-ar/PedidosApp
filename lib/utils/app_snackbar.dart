import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'colors.dart';

/// Tipos semánticos de snackbar
enum SnackType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  // ─── Colores por tipo ──────────────────────────────────────────────────────
  static Color _iconColor(SnackType type) {
    switch (type) {
      case SnackType.success:
        return AppColors.mainColor;
      case SnackType.error:
        return const Color(0xFFE53935);
      case SnackType.warning:
        return const Color(0xFFFB8C00);
      case SnackType.info:
        return const Color(0xFF1E88E5);
    }
  }

  static IconData _icon(SnackType type) {
    switch (type) {
      case SnackType.success:
        return Icons.check_circle_rounded;
      case SnackType.error:
        return Icons.cancel_rounded;
      case SnackType.warning:
        return Icons.warning_amber_rounded;
      case SnackType.info:
        return Icons.info_rounded;
    }
  }

  // ─── Método base ───────────────────────────────────────────────────────────
  static void show(
    String title,
    String message, {
    SnackType type = SnackType.info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
  }) {
    // Evitar duplicados si ya hay un snackbar visible
    if (Get.isSnackbarOpen) return;

    final color = _iconColor(type);

    Get.snackbar(
      title,
      message,
      // Fondo blanco con sombra sutil — el estilo del screenshot
      backgroundColor: Colors.white,
      colorText: const Color(0xFF2D2D2D),
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      snackPosition: position,
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 350),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
      // Borde lateral de color semántico
      barBlur: 0,
      overlayBlur: 0,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_icon(type), color: color, size: 22),
      ),
      shouldIconPulse: false,
      titleText: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF6B6B6B),
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  // ─── Accesos directos semánticos ───────────────────────────────────────────
  static void success(String title, String message, {Duration? duration}) =>
      show(title, message,
          type: SnackType.success,
          duration: duration ?? const Duration(seconds: 3));

  static void error(String title, String message, {Duration? duration}) =>
      show(title, message,
          type: SnackType.error,
          duration: duration ?? const Duration(seconds: 4));

  static void warning(String title, String message, {Duration? duration}) =>
      show(title, message,
          type: SnackType.warning,
          duration: duration ?? const Duration(seconds: 3));

  static void info(String title, String message, {Duration? duration}) =>
      show(title, message,
          type: SnackType.info,
          duration: duration ?? const Duration(seconds: 3));
}
