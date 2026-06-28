import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/data/repository/coupon_repo.dart';
import 'package:pedidosapp/models/coupon_model.dart';
import 'package:pedidosapp/models/loyalty_model.dart';
import 'package:pedidosapp/utils/app_snackbar.dart';
class CouponController extends GetxController {
  final CouponRepo couponRepo;
  CouponController({required this.couponRepo});

  // ── Coupon state ─────────────────────────────────────────────
  bool _isValidating = false;
  bool get isValidating => _isValidating;

  CouponValidationResult? _appliedCoupon;
  CouponValidationResult? get appliedCoupon => _appliedCoupon;

  String? get appliedCouponCode => _appliedCoupon?.coupon?.code;
  double get discountAmount => _appliedCoupon?.discountAmount ?? 0;
  bool get hasCouponApplied => _appliedCoupon != null;

  // ── Loyalty state ────────────────────────────────────────────
  bool _isLoadingLoyalty = false;
  bool get isLoadingLoyalty => _isLoadingLoyalty;

  LoyaltyProfile? _loyaltyProfile;
  LoyaltyProfile? get loyaltyProfile => _loyaltyProfile;

  List<LoyaltyTransaction> _transactions = [];
  List<LoyaltyTransaction> get transactions => _transactions;

  List<CouponModel> _userCoupons = [];
  List<CouponModel> get userCoupons => _userCoupons;

  bool _isLoadingCoupons = false;
  bool get isLoadingCoupons => _isLoadingCoupons;

  // ── Coupon methods ───────────────────────────────────────────
  Future<bool> validateCoupon(String code, double orderAmount, int branchId) async {
    if (code.trim().isEmpty) {
      AppSnackbar.warning('Cupón vacío', 'Ingresa un código de cupón');
      return false;
    }

    _isValidating = true;
    update();

    try {
      Response response = await couponRepo.validateCoupon(code.trim(), orderAmount, branchId).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = response.body;
        final data = body['data'] ?? body;
        final message = body['message']?.toString() ?? 'Cupón aplicado';

        _appliedCoupon = CouponValidationResult.fromJson(data, message);
        AppSnackbar.success('¡Cupón aplicado!', message);
        update();
        return true;
      } else {
        _appliedCoupon = null;
        String errorMsg = 'No se pudo validar el cupón';
        if (response.body != null && response.body is Map) {
          errorMsg = response.body['message']?.toString() ?? errorMsg;
        }
        AppSnackbar.error('Cupón inválido', errorMsg);
        update();
        return false;
      }
    } catch (e) {
      debugPrint('[CouponController] validateCoupon error: $e');
      _appliedCoupon = null;
      AppSnackbar.error('Error', 'Error de conexión al validar el cupón');
      update();
      return false;
    } finally {
      _isValidating = false;
      update();
    }
  }

  void removeCoupon({bool showSnackbar = true}) {
    _appliedCoupon = null;
    if (showSnackbar) {
      AppSnackbar.info('Cupón removido', 'Se ha removido el cupón del pedido');
    }
    update();
  }

  // ── Loyalty methods ──────────────────────────────────────────
  Future<void> getLoyaltyProfile() async {
    _isLoadingLoyalty = true;
    update();

    try {
      Response response = await couponRepo.getLoyaltyProfile().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = response.body;
        final data = body['data'] ?? body;
        _loyaltyProfile = LoyaltyProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('[CouponController] getLoyaltyProfile error: $e');
    } finally {
      _isLoadingLoyalty = false;
      update();
    }
  }

  Future<void> getLoyaltyTransactions() async {
    try {
      Response response = await couponRepo.getLoyaltyTransactions().timeout(const Duration(seconds: 8));
      debugPrint('[LOYALTY_TX] Status: ${response.statusCode}');
      debugPrint('[LOYALTY_TX] Raw body: ${response.body}');
      if (response.statusCode == 200) {
        _transactions = [];
        final body = response.body;
        final data = body['data'] ?? body;
        debugPrint('[LOYALTY_TX] data type: ${data.runtimeType}');
        // Paginated response — items may be in 'data' key inside data
        List rawList;
        if (data is Map && data.containsKey('data')) {
          rawList = data['data'] ?? [];
        } else if (data is List) {
          rawList = data;
        } else {
          rawList = [];
        }
        debugPrint('[LOYALTY_TX] rawList length: ${rawList.length}');
        for (var t in rawList) {
          debugPrint('[LOYALTY_TX] item: $t');
          _transactions.add(LoyaltyTransaction.fromJson(t));
        }
        debugPrint('[LOYALTY_TX] parsed transactions: ${_transactions.map((t) => "id=${t.id} orderId=${t.orderId} type=${t.type} desc=${t.description}").toList()}');
      }
    } catch (e) {
      debugPrint('[CouponController] getLoyaltyTransactions error: $e');
    }
    update();
  }

  Future<void> getUserCoupons() async {
    debugPrint('[COUPONS] getUserCoupons() called, setting _isLoadingCoupons=true');
    _isLoadingCoupons = true;
    update();

    try {
      Response response = await couponRepo.getUserCoupons().timeout(const Duration(seconds: 8));
      debugPrint('[COUPONS] status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        _userCoupons = [];
        final body = response.body;
        final data = body['data'] ?? body;
        List rawList;
        if (data is List) {
          rawList = data;
        } else {
          rawList = [];
        }
        for (var c in rawList) {
          _userCoupons.add(CouponModel.fromJson(c));
        }
        debugPrint('[COUPONS] parsed ${_userCoupons.length} coupons');
      }
    } catch (e) {
      debugPrint('[COUPONS] ERROR: $e');
    } finally {
      debugPrint('[COUPONS] finally: setting _isLoadingCoupons=false');
      _isLoadingCoupons = false;
      update();
    }
  }

  /// Load all loyalty data at once
  Future<void> loadLoyaltyData() async {
    await Future.wait([
      getLoyaltyProfile(),
      getLoyaltyTransactions(),
      getUserCoupons(),
    ]);
  }
}
