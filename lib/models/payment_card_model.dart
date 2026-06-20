class PaymentCardModel {
  int? id;
  String? cardType;
  String? lastFour;
  String? providerToken;

  PaymentCardModel({
    this.id,
    this.cardType,
    this.lastFour,
    this.providerToken,
  });

  PaymentCardModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardType = json['card_type'];
    lastFour = json['last_four'];
    providerToken = json['provider_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (cardType != null) data['card_type'] = cardType;
    if (lastFour != null) data['last_four'] = lastFour;
    if (providerToken != null) data['provider_token'] = providerToken;
    return data;
  }
}
