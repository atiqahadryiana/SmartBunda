import 'package:flutter_test/flutter_test.dart';
import 'package:smartbunda/models/pregnancy.dart';
import 'package:smartbunda/utils/nutrition_guides.dart';

void main() {
  test('recommendedFor returns trimester-specific targets', () {
    final first = recommendedFor(Pregnancy(
      id: 'P1',
      patientId: '1',
      gestationalWeek: 8,
      trimester: 1,
      edd: '2026-05-20',
      riskLevel: 'LOW',
      updatedAt: null,
    ));
    final third = recommendedFor(Pregnancy(
      id: 'P2',
      patientId: '1',
      gestationalWeek: 30,
      trimester: 3,
      edd: '2026-05-20',
      riskLevel: 'LOW',
      updatedAt: null,
    ));

    expect(first.calories, lessThan(third.calories));
    expect(first.protein, lessThan(third.protein));
  });
}
