// Data models for PaintEasy.
//
// Pure Dart — no Flutter imports — so models can be unit tested and
// reused by the calculator, storage and PDF builder.

/// One room of a house / building.
class Room {
  Room({
    required this.name,
    required this.length,
    required this.width,
    required this.height,
    this.lengthInches = 0,
    this.widthInches = 0,
    this.includeCeiling = false,
    this.doors = 0,
    this.windows = 0,
  });

  /// Room name, e.g. "Living Room".
  final String name;

  /// Length in the estimate's unit (feet, or metres when unit == 'm').
  final double length;

  /// Width in the estimate's unit.
  final double width;

  /// Height in the estimate's unit.
  final double height;

  /// Extra inches for the length (feet mode only, 0-11).
  final int lengthInches;

  /// Extra inches for the width (feet mode only, 0-11).
  final int widthInches;

  /// Whether the ceiling (L x W) is also painted.
  final bool includeCeiling;

  /// Number of doors in this room (deducted at the standard door size).
  final int doors;

  /// Number of windows in this room (deducted at the standard window size).
  final int windows;

  Room copyWith({
    String? name,
    double? length,
    double? width,
    double? height,
    int? lengthInches,
    int? widthInches,
    bool? includeCeiling,
    int? doors,
    int? windows,
  }) {
    return Room(
      name: name ?? this.name,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      lengthInches: lengthInches ?? this.lengthInches,
      widthInches: widthInches ?? this.widthInches,
      includeCeiling: includeCeiling ?? this.includeCeiling,
      doors: doors ?? this.doors,
      windows: windows ?? this.windows,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'length': length,
        'width': width,
        'height': height,
        'lengthInches': lengthInches,
        'widthInches': widthInches,
        'includeCeiling': includeCeiling,
        'doors': doors,
        'windows': windows,
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      name: json['name'] as String? ?? 'Room',
      length: (json['length'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      lengthInches: (json['lengthInches'] as num?)?.toInt() ?? 0,
      widthInches: (json['widthInches'] as num?)?.toInt() ?? 0,
      includeCeiling: json['includeCeiling'] as bool? ?? false,
      doors: (json['doors'] as num?)?.toInt() ?? 0,
      windows: (json['windows'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Rate + coverage for one paint brand.
class BrandRate {
  BrandRate({
    required this.brand,
    required this.ratePerLiter,
    required this.coveragePerLiterSqFt,
  });

  final String brand;

  /// Price per liter in the selected currency.
  final double ratePerLiter;

  /// Practical coverage in sq ft per liter per coat.
  final double coveragePerLiterSqFt;

  BrandRate copyWith({
    String? brand,
    double? ratePerLiter,
    double? coveragePerLiterSqFt,
  }) {
    return BrandRate(
      brand: brand ?? this.brand,
      ratePerLiter: ratePerLiter ?? this.ratePerLiter,
      coveragePerLiterSqFt:
          coveragePerLiterSqFt ?? this.coveragePerLiterSqFt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'brand': brand,
        'ratePerLiter': ratePerLiter,
        'coveragePerLiterSqFt': coveragePerLiterSqFt,
      };

  factory BrandRate.fromJson(Map<String, dynamic> json) {
    return BrandRate(
      brand: json['brand'] as String? ?? '',
      ratePerLiter: (json['ratePerLiter'] as num?)?.toDouble() ?? 0,
      coveragePerLiterSqFt:
          (json['coveragePerLiterSqFt'] as num?)?.toDouble() ?? 100,
    );
  }
}

/// A saved paint estimate.
class Estimate {
  Estimate({
    required this.id,
    required this.title,
    required this.createdAt,
    this.unit = 'ft',
    this.currency = 'PKR',
    this.brand = 'Berger',
    this.paintType = 'emulsion',
    this.rooms = const <Room>[],
    this.labourRatePerSqFt = 25,
    this.puttyEnabled = true,
    this.puttyRatePerSqFt = 5,
    this.primerRatePerLiter = 450,
    this.painterName = '',
    this.painterPhone = '',
    this.customerName = '',
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime createdAt;

  /// 'ft' (feet + inch) or 'm' (metre).
  final String unit;

  /// Currency code: PKR, USD, INR, AED, GBP, EUR.
  final String currency;

  final String brand;

  /// 'emulsion' or 'distemper'.
  final String paintType;

  final List<Room> rooms;
  final double labourRatePerSqFt;
  final bool puttyEnabled;
  final double puttyRatePerSqFt;
  final double primerRatePerLiter;

  final String painterName;
  final String painterPhone;
  final String customerName;
  final String notes;

  Estimate copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? unit,
    String? currency,
    String? brand,
    String? paintType,
    List<Room>? rooms,
    double? labourRatePerSqFt,
    bool? puttyEnabled,
    double? puttyRatePerSqFt,
    double? primerRatePerLiter,
    String? painterName,
    String? painterPhone,
    String? customerName,
    String? notes,
  }) {
    return Estimate(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      unit: unit ?? this.unit,
      currency: currency ?? this.currency,
      brand: brand ?? this.brand,
      paintType: paintType ?? this.paintType,
      rooms: rooms ?? this.rooms,
      labourRatePerSqFt: labourRatePerSqFt ?? this.labourRatePerSqFt,
      puttyEnabled: puttyEnabled ?? this.puttyEnabled,
      puttyRatePerSqFt: puttyRatePerSqFt ?? this.puttyRatePerSqFt,
      primerRatePerLiter: primerRatePerLiter ?? this.primerRatePerLiter,
      painterName: painterName ?? this.painterName,
      painterPhone: painterPhone ?? this.painterPhone,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'unit': unit,
        'currency': currency,
        'brand': brand,
        'paintType': paintType,
        'rooms': rooms.map((Room r) => r.toJson()).toList(),
        'labourRatePerSqFt': labourRatePerSqFt,
        'puttyEnabled': puttyEnabled,
        'puttyRatePerSqFt': puttyRatePerSqFt,
        'primerRatePerLiter': primerRatePerLiter,
        'painterName': painterName,
        'painterPhone': painterPhone,
        'customerName': customerName,
        'notes': notes,
      };

  factory Estimate.fromJson(Map<String, dynamic> json) {
    final List<dynamic> roomsJson =
        json['rooms'] as List<dynamic>? ?? <dynamic>[];
    return Estimate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      unit: json['unit'] as String? ?? 'ft',
      currency: json['currency'] as String? ?? 'PKR',
      brand: json['brand'] as String? ?? 'Berger',
      paintType: json['paintType'] as String? ?? 'emulsion',
      rooms: roomsJson
          .map((dynamic e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
      labourRatePerSqFt:
          (json['labourRatePerSqFt'] as num?)?.toDouble() ?? 25,
      puttyEnabled: json['puttyEnabled'] as bool? ?? true,
      puttyRatePerSqFt: (json['puttyRatePerSqFt'] as num?)?.toDouble() ?? 5,
      primerRatePerLiter:
          (json['primerRatePerLiter'] as num?)?.toDouble() ?? 450,
      painterName: json['painterName'] as String? ?? '',
      painterPhone: json['painterPhone'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
