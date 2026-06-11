class CouponModel {
  int? id;
  String? code;
  String? description;
  String? type; // 'percent', 'fixed', 'free_delivery'
  double? value;
  double? minOrderAmount;
  String? expiresAt;

  CouponModel({
    this.id,
    this.code,
    this.description,
    this.type,
    this.value,
    this.minOrderAmount,
    this.expiresAt,
  });

  CouponModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    description = json['description'];
    type = json['type'];
    value = double.tryParse(json['value']?.toString() ?? '');
    minOrderAmount = double.tryParse(json['min_order_amount']?.toString() ?? '');
    expiresAt = json['expires_at'];
  }

  /// Human-readable label for the coupon type
  String get typeLabel {
    switch (type) {
      case 'percent':
        return '${value?.toStringAsFixed(0) ?? ''}% de descuento';
      case 'fixed':
        return '\$${value?.toStringAsFixed(2) ?? ''} de descuento';
      case 'free_delivery':
        return 'Envío gratis';
      default:
        return description ?? code ?? '';
    }
  }
}

class CouponValidationResult {
  CouponModel? coupon;
  double discountAmount;
  String discountAmountFmt;
  double estimatedTotal;
  String estimatedTotalFmt;
  String message;

  CouponValidationResult({
    this.coupon,
    this.discountAmount = 0,
    this.discountAmountFmt = '',
    this.estimatedTotal = 0,
    this.estimatedTotalFmt = '',
    this.message = '',
  });

  CouponValidationResult.fromJson(Map<String, dynamic> json, String msg)
      : discountAmount = double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0,
        discountAmountFmt = json['discount_amount_fmt']?.toString() ?? '',
        estimatedTotal = double.tryParse(json['estimated_total']?.toString() ?? '0') ?? 0,
        estimatedTotalFmt = json['estimated_total_fmt']?.toString() ?? '',
        message = msg {
    if (json['coupon'] != null && json['coupon'] is Map) {
      coupon = CouponModel.fromJson(json['coupon']);
    }
  }
}
