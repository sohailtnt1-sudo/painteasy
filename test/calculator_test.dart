import 'package:flutter_test/flutter_test.dart';
import 'package:painteasy/models/estimate.dart';
import 'package:painteasy/services/calculator.dart';

Room _room({
  String name = 'Living Room',
  double length = 12,
  double width = 10,
  double height = 10,
  int lengthInches = 0,
  int widthInches = 0,
  bool includeCeiling = false,
  int doors = 0,
  int windows = 0,
}) {
  return Room(
    name: name,
    length: length,
    width: width,
    height: height,
    lengthInches: lengthInches,
    widthInches: widthInches,
    includeCeiling: includeCeiling,
    doors: doors,
    windows: windows,
  );
}

Estimate _estimate({
  List<Room> rooms = const <Room>[],
  String unit = 'ft',
  double labourRate = 25,
  bool puttyEnabled = true,
  double puttyRate = 5,
  double primerRate = 450,
}) {
  return Estimate(
    id: 'test-1',
    title: 'Test',
    createdAt: DateTime(2026, 11, 23),
    unit: unit,
    rooms: rooms,
    labourRatePerSqFt: labourRate,
    puttyEnabled: puttyEnabled,
    puttyRatePerSqFt: puttyRate,
    primerRatePerLiter: primerRate,
  );
}

void main() {
  group('wall area', () {
    test('feet: 12 x 10 x 10 ft room = 440 sq ft', () {
      expect(roomWallAreaSqFt(_room(), 'ft'), 440);
    });

    test('feet + inches: 12ft 6in x 10ft x 10ft = 450 sq ft', () {
      expect(
        roomWallAreaSqFt(_room(lengthInches: 6), 'ft'),
        450,
      );
    });

    test('width inches also count: 12 x 10ft 6in x 10ft = 450 sq ft', () {
      expect(
        roomWallAreaSqFt(_room(widthInches: 6), 'ft'),
        450,
      );
    });

    test('meters: 4m x 3m x 3m converts to sq ft', () {
      // 4m=13.12336ft, 3m=9.84252ft -> 2*(13.12336+9.84252)*9.84252
      final double expected =
          2 * (4 * feetPerMeter + 3 * feetPerMeter) * (3 * feetPerMeter);
      expect(roomWallAreaSqFt(_room(length: 4, width: 3, height: 3), 'm'),
          closeTo(expected, 0.01));
    });

    test('zero dimensions give zero area', () {
      expect(roomWallAreaSqFt(_room(length: 0, width: 0, height: 0), 'ft'), 0);
    });

    test('negative dimensions are clamped to zero', () {
      expect(roomWallAreaSqFt(_room(length: -5), 'ft'), 0);
      expect(roomWallAreaSqFt(_room(height: -2), 'ft'), 0);
    });
  });

  group('ceiling', () {
    test('ceiling area is L x W', () {
      expect(roomCeilingAreaSqFt(_room(), 'ft'), 120);
    });

    test('ceiling included in paintable area', () {
      final double area = roomPaintableAreaSqFt(
        _room(includeCeiling: true),
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      expect(area, 440 + 120);
    });

    test('ceiling excluded by default', () {
      final double area = roomPaintableAreaSqFt(
        _room(),
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      expect(area, 440);
    });
  });

  group('door / window deductions', () {
    test('1 door + 1 window deducted at standard sizes', () {
      final double area = roomPaintableAreaSqFt(
        _room(doors: 1, windows: 1),
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      expect(area, 440 - 21 - 16);
    });

    test('multiple doors and windows', () {
      final double area = roomPaintableAreaSqFt(
        _room(doors: 2, windows: 3),
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      expect(area, 440 - 42 - 48);
    });

    test('deductions never push area below zero', () {
      final double area = roomPaintableAreaSqFt(
        _room(length: 2, width: 2, height: 2, doors: 5, windows: 5),
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      expect(area, 0);
    });

    test('metric deduction sizes work', () {
      final double area = roomPaintableAreaSqFt(
        _room(length: 4, width: 3, height: 3, doors: 1, windows: 1),
        'm',
        doorAreaSqFt: 1.89 * sqFtPerSqMeter,
        windowAreaSqFt: 1.44 * sqFtPerSqMeter,
      );
      final double wall =
          2 * (4 * feetPerMeter + 3 * feetPerMeter) * (3 * feetPerMeter);
      expect(area, closeTo(wall - (1.89 + 1.44) * sqFtPerSqMeter, 0.01));
    });
  });

  group('total area', () {
    test('sums all rooms', () {
      final double total = totalPaintableAreaSqFt(
        <Room>[_room(), _room(length: 10, width: 10, height: 9)],
        'ft',
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      // Room 2: 2*(10+10)*9 = 360.
      expect(total, 440 + 360);
    });

    test('empty rooms list gives zero', () {
      expect(
        totalPaintableAreaSqFt(<Room>[], 'ft',
            doorAreaSqFt: 21, windowAreaSqFt: 16),
        0,
      );
    });
  });

  group('liters', () {
    test('primer: 1 coat at 120 sq ft/L', () {
      expect(primerLiters(440, 120), closeTo(440 / 120, 0.0001));
    });

    test('paint: 2 coats at 100 sq ft/L', () {
      expect(paintLiters(440, 100), 8.8);
    });

    test('zero area needs zero liters', () {
      expect(primerLiters(0, 120), 0);
      expect(paintLiters(0, 100), 0);
    });

    test('zero or negative coverage is safe (0 liters)', () {
      expect(litersForArea(440, 0), 0);
      expect(litersForArea(440, -10), 0);
      expect(litersForArea(-50, 100), 0);
    });
  });

  group('pack breakdown', () {
    test('exact multiple of 16L', () {
      final PackBreakdown b = packBreakdown(32);
      expect(b.packs16L, 2);
      expect(b.packs4L, 0);
      expect(b.packedLiters, 32);
    });

    test('16L exactly is one big pack', () {
      final PackBreakdown b = packBreakdown(16);
      expect(b.packs16L, 1);
      expect(b.packs4L, 0);
    });

    test('20L = 1x16L + 1x4L', () {
      final PackBreakdown b = packBreakdown(20);
      expect(b.packs16L, 1);
      expect(b.packs4L, 1);
      expect(b.packedLiters, 20);
    });

    test('17L rounds up: 1x16L + 1x4L = 20L bought', () {
      final PackBreakdown b = packBreakdown(17);
      expect(b.packs16L, 1);
      expect(b.packs4L, 1);
      expect(b.packedLiters, 20);
    });

    test('small quantity 3L = 1x4L', () {
      final PackBreakdown b = packBreakdown(3);
      expect(b.packs16L, 0);
      expect(b.packs4L, 1);
      expect(b.packedLiters, 4);
    });

    test('8.8L = 3x4L (12L bought)', () {
      final PackBreakdown b = packBreakdown(8.8);
      expect(b.packs16L, 0);
      expect(b.packs4L, 3);
      expect(b.packedLiters, 12);
    });

    test('zero liters = no packs', () {
      final PackBreakdown b = packBreakdown(0);
      expect(b.packs16L, 0);
      expect(b.packs4L, 0);
      expect(b.packedLiters, 0);
    });

    test('negative liters = no packs', () {
      expect(packBreakdown(-5).packs4L, 0);
    });
  });

  group('labour and putty', () {
    test('labour = rate x area', () {
      expect(labourCost(440, 25), 11000);
    });

    test('putty on: rate x area', () {
      expect(puttyCost(440, 5, true), 2200);
    });

    test('putty off: zero', () {
      expect(puttyCost(440, 5, false), 0);
    });

    test('labour zero area = zero', () {
      expect(labourCost(0, 25), 0);
    });
  });

  group('full estimate', () {
    EstimateResult calculate({bool putty = true, List<Room>? rooms}) {
      return calculateEstimate(
        _estimate(
          rooms: rooms ?? <Room>[_room(doors: 1, windows: 1)],
          puttyEnabled: putty,
        ),
        paintCoverageSqFt: 100,
        primerCoverageSqFt: 120,
        paintRatePerLiter: 900,
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
    }

    test('paintable area 403 sq ft after deductions', () {
      expect(calculate().paintableAreaSqFt, 403);
    });

    test('primer liters and cost', () {
      final EstimateResult r = calculate();
      expect(r.primerLitersNeeded, closeTo(403 / 120, 0.0001));
      expect(r.primerCost, closeTo(403 / 120 * 450, 0.01));
    });

    test('paint liters, cost and packs', () {
      final EstimateResult r = calculate();
      expect(r.paintLitersNeeded, closeTo(8.06, 0.0001));
      expect(r.paintCost, closeTo(8.06 * 900, 0.01));
      // 8.06L -> 3 x 4L packs.
      expect(r.paintPacks.packs16L, 0);
      expect(r.paintPacks.packs4L, 3);
    });

    test('grand total = material + labour', () {
      final EstimateResult r = calculate();
      final double material =
          (403 / 120 * 450) + (8.06 * 900) + (403 * 5);
      final double labour = 403 * 25;
      expect(r.materialCost, closeTo(material, 0.01));
      expect(r.labourCostAmount, labour);
      expect(r.grandTotal, closeTo(material + labour, 0.01));
    });

    test('putty off removes putty from material and total', () {
      final EstimateResult withPutty = calculate(putty: true);
      final EstimateResult withoutPutty = calculate(putty: false);
      expect(withoutPutty.puttyCostAmount, 0);
      expect(
        withPutty.grandTotal - withoutPutty.grandTotal,
        closeTo(403 * 5, 0.01),
      );
    });

    test('empty estimate: everything zero', () {
      final EstimateResult r = calculate(rooms: <Room>[]);
      expect(r.paintableAreaSqFt, 0);
      expect(r.primerLitersNeeded, 0);
      expect(r.paintLitersNeeded, 0);
      expect(r.primerCost, 0);
      expect(r.paintCost, 0);
      expect(r.puttyCostAmount, 0);
      expect(r.labourCostAmount, 0);
      expect(r.grandTotal, 0);
      expect(r.paintPacks.packs16L, 0);
      expect(r.paintPacks.packs4L, 0);
    });

    test('meter estimate converts correctly', () {
      final EstimateResult r = calculateEstimate(
        _estimate(
          unit: 'm',
          rooms: <Room>[_room(length: 4, width: 3, height: 3)],
        ),
        paintCoverageSqFt: 100,
        primerCoverageSqFt: 120,
        paintRatePerLiter: 900,
        doorAreaSqFt: 21,
        windowAreaSqFt: 16,
      );
      final double expectedArea =
          2 * (4 * feetPerMeter + 3 * feetPerMeter) * (3 * feetPerMeter);
      expect(r.paintableAreaSqFt, closeTo(expectedArea, 0.01));
      expect(r.grandTotal, greaterThan(0));
    });
  });
}
