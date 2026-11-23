// Pure paint calculations for PaintEasy.
//
// No Flutter imports here — every function is a plain Dart function so it
// can be unit tested without a widget test harness.
//
// All areas are normalised to SQUARE FEET internally. Rooms entered in
// metres are converted (1 m = 3.28084 ft, 1 m^2 = 10.7639 sq ft).
// Coverage is expressed in sq ft per liter per coat.

import '../models/estimate.dart';

/// Feet in one metre.
const double feetPerMeter = 3.28084;

/// Square feet in one square metre.
const double sqFtPerSqMeter = 10.7639;

/// Default coats: 1 primer coat, 2 paint coats.
const int primerCoats = 1;
const int paintCoats = 2;

/// Pack sizes (litres) used for the pack breakdown.
const double bigPackLiters = 16;
const double smallPackLiters = 4;

double _nonNegative(double value) => value < 0 ? 0 : value;

/// Converts a length entered in [unit] ('ft' or 'm') to feet.
/// [inches] only applies when [unit] is 'ft' (0-11 extra inches).
double lengthToFeet(double length, int inches, String unit) {
  if (unit == 'm') {
    return _nonNegative(length) * feetPerMeter;
  }
  final int safeInches = inches < 0 ? 0 : (inches > 11 ? 11 : inches);
  return _nonNegative(length) + safeInches / 12;
}

/// Wall area of one room in sq ft: 2 * (L + W) * H.
/// Zero when any dimension is zero or negative (an invalid room has no
/// paintable area).
double roomWallAreaSqFt(Room room, String unit) {
  final double l = lengthToFeet(room.length, room.lengthInches, unit);
  final double w = lengthToFeet(room.width, room.widthInches, unit);
  final double h = lengthToFeet(room.height, 0, unit);
  if (l <= 0 || w <= 0 || h <= 0) {
    return 0;
  }
  return 2 * (l + w) * h;
}

/// Ceiling area of one room in sq ft: L * W.
/// Zero when any dimension is zero or negative.
double roomCeilingAreaSqFt(Room room, String unit) {
  final double l = lengthToFeet(room.length, room.lengthInches, unit);
  final double w = lengthToFeet(room.width, room.widthInches, unit);
  if (l <= 0 || w <= 0) {
    return 0;
  }
  return l * w;
}

/// Paintable area of one room in sq ft: walls (+ ceiling if included)
/// minus doors and windows at their standard sizes.
///
/// [doorAreaSqFt] and [windowAreaSqFt] are the standard deduction sizes
/// in sq ft (converted from the settings unit by the caller).
/// The result never goes below zero.
double roomPaintableAreaSqFt(
  Room room,
  String unit, {
  required double doorAreaSqFt,
  required double windowAreaSqFt,
}) {
  double area = roomWallAreaSqFt(room, unit);
  if (room.includeCeiling) {
    area += roomCeilingAreaSqFt(room, unit);
  }
  final int doors = room.doors < 0 ? 0 : room.doors;
  final int windows = room.windows < 0 ? 0 : room.windows;
  area -= doors * _nonNegative(doorAreaSqFt);
  area -= windows * _nonNegative(windowAreaSqFt);
  return _nonNegative(area);
}

/// Total paintable area of all rooms in sq ft.
double totalPaintableAreaSqFt(
  List<Room> rooms,
  String unit, {
  required double doorAreaSqFt,
  required double windowAreaSqFt,
}) {
  double total = 0;
  for (final Room room in rooms) {
    total += roomPaintableAreaSqFt(
      room,
      unit,
      doorAreaSqFt: doorAreaSqFt,
      windowAreaSqFt: windowAreaSqFt,
    );
  }
  return total;
}

/// Liters needed for [coats] coats over [areaSqFt] at
/// [coveragePerLiterSqFt] sq ft per liter per coat.
/// Returns 0 for zero / invalid inputs (never negative).
double litersForArea(
  double areaSqFt,
  double coveragePerLiterSqFt, {
  int coats = 1,
}) {
  if (areaSqFt <= 0 || coveragePerLiterSqFt <= 0 || coats <= 0) {
    return 0;
  }
  return areaSqFt * coats / coveragePerLiterSqFt;
}

/// Primer liters: 1 coat.
double primerLiters(double areaSqFt, double primerCoverageSqFt) {
  return litersForArea(areaSqFt, primerCoverageSqFt, coats: primerCoats);
}

/// Paint liters: 2 coats.
double paintLiters(double areaSqFt, double paintCoverageSqFt) {
  return litersForArea(areaSqFt, paintCoverageSqFt, coats: paintCoats);
}

/// Result of splitting a total litre quantity into 16L and 4L packs.
class PackBreakdown {
  const PackBreakdown({
    required this.packs16L,
    required this.packs4L,
    required this.totalLiters,
    required this.packedLiters,
  });

  /// Number of 16L packs.
  final int packs16L;

  /// Number of 4L packs.
  final int packs4L;

  /// Exact liters required (before rounding up to packs).
  final double totalLiters;

  /// Liters actually bought once rounded up to whole packs.
  final double packedLiters;
}

/// Splits [liters] into 16L packs first, then the remainder into 4L packs,
/// always rounding UP so the painter never runs short.
///
/// Examples: 32L -> 2 x 16L. 20L -> 1 x 16L + 1 x 4L. 17L -> 1 x 16L + 1 x 4L.
/// 3L -> 1 x 4L. 0L -> nothing.
PackBreakdown packBreakdown(double liters) {
  final double needed = _nonNegative(liters);
  if (needed == 0) {
    return const PackBreakdown(
      packs16L: 0,
      packs4L: 0,
      totalLiters: 0,
      packedLiters: 0,
    );
  }
  final int packs16 = (needed / bigPackLiters).floor();
  final double remainder = needed - packs16 * bigPackLiters;
  final int packs4 =
      remainder <= 0 ? 0 : (remainder / smallPackLiters).ceil();
  final double packed = packs16 * bigPackLiters + packs4 * smallPackLiters;
  return PackBreakdown(
    packs16L: packs16,
    packs4L: packs4,
    totalLiters: needed,
    packedLiters: packed,
  );
}

/// Labour cost = rate per sq ft x paintable area.
double labourCost(double areaSqFt, double ratePerSqFt) {
  return _nonNegative(areaSqFt) * _nonNegative(ratePerSqFt);
}

/// Putty cost = rate per sq ft x paintable area (0 when disabled).
double puttyCost(double areaSqFt, double ratePerSqFt, bool enabled) {
  if (!enabled) {
    return 0;
  }
  return _nonNegative(areaSqFt) * _nonNegative(ratePerSqFt);
}

/// Full cost breakdown for an estimate.
class EstimateResult {
  const EstimateResult({
    required this.paintableAreaSqFt,
    required this.primerLitersNeeded,
    required this.primerCost,
    required this.paintLitersNeeded,
    required this.paintCost,
    required this.paintPacks,
    required this.puttyCostAmount,
    required this.labourCostAmount,
    required this.materialCost,
    required this.grandTotal,
  });

  /// Total paintable area in sq ft.
  final double paintableAreaSqFt;

  final double primerLitersNeeded;
  final double primerCost;

  final double paintLitersNeeded;
  final double paintCost;
  final PackBreakdown paintPacks;

  final double puttyCostAmount;
  final double labourCostAmount;

  /// Material = primer + paint + putty.
  final double materialCost;

  /// Material + labour.
  final double grandTotal;
}

/// Calculates the complete estimate from an [Estimate] plus the rates that
/// apply to it.
///
/// [paintCoverageSqFt] / [primerCoverageSqFt] are sq ft per liter per coat.
/// [paintRatePerLiter] is the selected brand's rate for the selected paint
/// type. [doorAreaSqFt] / [windowAreaSqFt] are the standard deduction sizes.
EstimateResult calculateEstimate(
  Estimate estimate, {
  required double paintCoverageSqFt,
  required double primerCoverageSqFt,
  required double paintRatePerLiter,
  required double doorAreaSqFt,
  required double windowAreaSqFt,
}) {
  final double area = totalPaintableAreaSqFt(
    estimate.rooms,
    estimate.unit,
    doorAreaSqFt: doorAreaSqFt,
    windowAreaSqFt: windowAreaSqFt,
  );

  final double primerL = primerLiters(area, primerCoverageSqFt);
  final double primerC = primerL * _nonNegative(estimate.primerRatePerLiter);

  final double paintL = paintLiters(area, paintCoverageSqFt);
  final double paintC = paintL * _nonNegative(paintRatePerLiter);
  final PackBreakdown packs = packBreakdown(paintL);

  final double puttyC = puttyCost(
    area,
    estimate.puttyRatePerSqFt,
    estimate.puttyEnabled,
  );
  final double labourC = labourCost(area, estimate.labourRatePerSqFt);

  final double material = primerC + paintC + puttyC;
  return EstimateResult(
    paintableAreaSqFt: area,
    primerLitersNeeded: primerL,
    primerCost: primerC,
    paintLitersNeeded: paintL,
    paintCost: paintC,
    paintPacks: packs,
    puttyCostAmount: puttyC,
    labourCostAmount: labourC,
    materialCost: material,
    grandTotal: material + labourC,
  );
}
