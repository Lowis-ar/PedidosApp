class PaymentCardModel {
  int? id;
  String? cardHolder;
  String? cardNumber;
  String? expiryDate;
  String? cardType;
  String? lastFour;

  PaymentCardModel({
    this.id,
    this.cardHolder,
    this.cardNumber,
    this.expiryDate,
    this.cardType,
    this.lastFour,
  });

  PaymentCardModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardHolder = json['card_holder'];
    cardNumber = json['card_number'];
    expiryDate = json['expiry_date'];
    cardType = json['card_type'];
    lastFour = json['last_four'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (cardHolder != null) data['card_holder'] = cardHolder;
    if (cardNumber != null) data['card_number'] = cardNumber;
    if (expiryDate != null) data['expiry_date'] = expiryDate;
    if (cardType != null) data['card_type'] = cardType;
    if (lastFour != null) data['last_four'] = lastFour;
    return data;
  }
}
