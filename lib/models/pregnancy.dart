enum Trimester { first, second, third }

/// Malaysian MOH colour-coded risk level for obstetric care. The colour maps
/// to a risk tier and to where/by whom the mother should be seen (PHN/JM ↔ MO
/// ↔ specialist ↔ admission). Stored as the lowercase [code] (e.g. 'green').
///
/// Tier meaning: White = No risk · Green = Low risk · Yellow = High risk ·
/// Red = Extremely high risk.
enum PregnancyRiskLevel {
  white('white', 'White', 'No Risk',
      'No risk factors — routine follow-up by PHN / JM at the clinic.'),
  green('green', 'Green', 'Low Risk',
      'Low risk — care by a Medical Officer at the clinic; shared care with nurses under MO supervision.'),
  yellow('yellow', 'Yellow', 'High Risk',
      'High risk — urgent referral to hospital with an O&G specialist / FMS; shared care possible.'),
  red('red', 'Red', 'Extremely High Risk',
      'Extremely high risk — urgent admission to hospital.');

  const PregnancyRiskLevel(this.code, this.label, this.riskLabel,
      this.description);

  /// Persisted value (lowercase colour).
  final String code;

  /// Colour name (White/Green/Yellow/Red) — used with the colour swatch.
  final String label;

  /// Clinical risk tier shown to patients (No / Low / High / Extremely High).
  final String riskLabel;

  /// MOH care-level meaning of the colour.
  final String description;

  /// Combined display: clinical tier + colour, e.g. "Low Risk (Green)".
  String get display => '$riskLabel ($label)';

  static PregnancyRiskLevel? fromCode(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    for (final level in PregnancyRiskLevel.values) {
      if (level.code == v || level.label.toLowerCase() == v) return level;
    }
    return null;
  }
}

class Pregnancy {
  Pregnancy({
    required this.id,
    required this.patientId,
    required this.gestationalWeek,
    required this.trimester,
    required this.edd,
    required this.riskLevel,
    required this.updatedAt,
    this.lmp,
  });

  final String id;
  final String patientId;
  final int gestationalWeek;
  final int trimester;
  final String edd;
  final String riskLevel;
  final DateTime? updatedAt;

  /// Last menstrual period. When set, [gestationalWeek] and [edd] are derived
  /// from it (standard obstetric dating) instead of being entered by hand.
  final DateTime? lmp;

  /// Length of a term pregnancy by Naegele's rule (LMP + 280 days).
  static const int _termDays = 280;

  /// Completed gestational weeks today for a given [lmp]. Clamped to the valid
  /// 0–42 range; returns 0 when [lmp] is null or in the future.
  static int gestationalWeekFromLmp(DateTime? lmp, {DateTime? asOf}) {
    if (lmp == null) return 0;
    final now = asOf ?? DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lmp.year, lmp.month, lmp.day))
        .inDays;
    if (days < 0) return 0;
    final weeks = days ~/ 7;
    return weeks > 42 ? 42 : weeks;
  }

  /// Estimated date of delivery from [lmp] (Naegele's rule).
  static DateTime? eddFromLmp(DateTime? lmp) =>
      lmp?.add(const Duration(days: _termDays));

  static int trimesterIndexFromWeek(int week) {
    if (week <= 0) return 0;
    if (week <= 12) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  static Trimester? trimesterFromWeek(int week) {
    if (week <= 0) return null;
    if (week <= 12) return Trimester.first;
    if (week <= 27) return Trimester.second;
    return Trimester.third;
  }

  Trimester get trimesterEnum {
    final derived = trimesterFromWeek(gestationalWeek);
    if (derived != null) return derived;
    switch (trimester) {
      case 1:
        return Trimester.first;
      case 2:
        return Trimester.second;
      case 3:
      default:
        return Trimester.third;
    }
  }

  Pregnancy copyWith({
    String? id,
    String? patientId,
    int? gestationalWeek,
    int? trimester,
    String? edd,
    String? riskLevel,
    DateTime? updatedAt,
    DateTime? lmp,
  }) {
    return Pregnancy(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gestationalWeek: gestationalWeek ?? this.gestationalWeek,
      trimester: trimester ?? this.trimester,
      edd: edd ?? this.edd,
      riskLevel: riskLevel ?? this.riskLevel,
      updatedAt: updatedAt ?? this.updatedAt,
      lmp: lmp ?? this.lmp,
    );
  }
}
