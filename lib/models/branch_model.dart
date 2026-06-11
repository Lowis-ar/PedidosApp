class Branch {
  final int id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpenNow;
  final BranchSchedule? schedule;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isOpenNow = true,
    this.schedule,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      isOpenNow: json['is_open_now'] ?? true,
      schedule: json['schedule'] != null ? BranchSchedule.fromJson(json['schedule']) : null,
    );
  }
}

class BranchScheduleDay {
  final int day;
  final String dayName;
  final bool isClosed;
  final List<BranchShift> shifts;

  BranchScheduleDay({required this.day, required this.dayName, required this.isClosed, required this.shifts});

  factory BranchScheduleDay.fromJson(Map<String, dynamic> json) {
    return BranchScheduleDay(
      day: json['day'] ?? 0,
      dayName: json['day_name'] ?? '',
      isClosed: json['is_closed'] ?? false,
      shifts: (json['shifts'] as List? ?? []).map((s) => BranchShift.fromJson(s)).toList(),
    );
  }
}

class BranchShift {
  final String? openTime;
  final String? closeTime;

  BranchShift({this.openTime, this.closeTime});

  factory BranchShift.fromJson(Map<String, dynamic> json) {
    return BranchShift(
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }
}

class BranchSpecialDay {
  final String date;
  final String? label;
  final bool isClosed;
  final List<BranchShift> shifts;

  BranchSpecialDay({required this.date, this.label, required this.isClosed, required this.shifts});

  factory BranchSpecialDay.fromJson(Map<String, dynamic> json) {
    return BranchSpecialDay(
      date: json['date'] ?? '',
      label: json['label'],
      isClosed: json['is_closed'] ?? false,
      shifts: (json['shifts'] as List? ?? []).map((s) => BranchShift.fromJson(s)).toList(),
    );
  }
}

class BranchSchedule {
  final List<BranchScheduleDay> regular;
  final List<BranchSpecialDay> special;

  BranchSchedule({required this.regular, required this.special});

  factory BranchSchedule.fromJson(Map<String, dynamic> json) {
    return BranchSchedule(
      regular: (json['regular'] as List? ?? []).map((r) => BranchScheduleDay.fromJson(r)).toList(),
      special: (json['special'] as List? ?? []).map((s) => BranchSpecialDay.fromJson(s)).toList(),
    );
  }
}
