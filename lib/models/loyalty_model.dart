class LoyaltyProfile {
  int loyaltyPoints;
  int lifetimePoints;
  LoyaltyMilestone? currentMilestone;
  LoyaltyMilestone? nextMilestone;

  LoyaltyProfile({
    this.loyaltyPoints = 0,
    this.lifetimePoints = 0,
    this.currentMilestone,
    this.nextMilestone,
  });

  LoyaltyProfile.fromJson(Map<String, dynamic> json)
      : loyaltyPoints = json['loyalty_points'] ?? 0,
        lifetimePoints = json['lifetime_points'] ?? 0 {
    if (json['current_milestone'] != null && json['current_milestone'] is Map) {
      currentMilestone = LoyaltyMilestone.fromJson(json['current_milestone']);
    }
    if (json['next_milestone'] != null && json['next_milestone'] is Map) {
      nextMilestone = LoyaltyMilestone.fromJson(json['next_milestone']);
    }
  }

  /// Progress percentage towards the next milestone (0.0 – 1.0)
  double get progress {
    if (nextMilestone == null) return 1.0;
    int base = currentMilestone?.pointsRequired ?? 0;
    int target = nextMilestone!.pointsRequired;
    if (target <= base) return 1.0;
    return ((lifetimePoints - base) / (target - base)).clamp(0.0, 1.0);
  }
}

class LoyaltyMilestone {
  int id;
  String name;
  int pointsRequired;

  LoyaltyMilestone({
    this.id = 0,
    this.name = '',
    this.pointsRequired = 0,
  });

  LoyaltyMilestone.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? 0,
        name = json['name'] ?? '',
        pointsRequired = json['points_required'] ?? 0;
}

class LoyaltyTransaction {
  int? id;
  String? type; // 'earn', 'spend', 'refund', etc.
  int? points;
  String? description;
  String? createdAt;
  int? orderId;

  LoyaltyTransaction({
    this.id,
    this.type,
    this.points,
    this.description,
    this.createdAt,
    this.orderId,
  });

  LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    points = json['points'];
    description = json['description'];
    createdAt = json['created_at'];
    orderId = json['order_id'];
  }

  bool get isEarned => type == 'earned' || type == 'earn' || type == 'refund' || (points != null && points! > 0);
}
