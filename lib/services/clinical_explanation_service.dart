/// SmartBunda — Clinical Explanation Service
///
/// Generates patient-friendly explanations based on triggered clinical rules.
/// Templates are predefined and based on SmartBunda Clinical Rules Engine outputs.
/// This service DOES NOT generate medical recommendations — it only explains
/// what the clinical engine has already determined.
library smartbunda.clinical_explanation_service;

import '../utils/clinical_rules.dart';

/// Generates a narrative health summary from a clinical assessment.
///
/// Takes the output of ClinicalRuleEngine.evaluate() and produces
/// patient-friendly explanation text based ONLY on triggered rules.
/// No new medical information is generated; all explanations are
/// predefined templates mapped to rule IDs.
class ClinicalExplanationService {
  // Rule ID → Patient-Friendly Explanation Template
  static const Map<String, String> _templatesByRuleId = {
    // PRE-PREGNANCY RULES
    'SB-PP-01': 'Your current weight may impact pregnancy outcomes. '
        'Discuss with your healthcare provider about achieving a healthy '
        'weight before conception to reduce pregnancy risks.',
    'SB-PP-02': 'Start folic acid supplementation (0.4mg daily) at least '
        '3 months before conception to prevent neural tube defects and support '
        'healthy fetal development.',
    'SB-PP-03': 'Due to your diabetes or epilepsy, consider higher-dose folic acid '
        'supplementation (5mg daily) before conception to reduce risks.',
    'SB-PP-04': 'Your hemoglobin level is lower than recommended. '
        'Consult your healthcare provider for assessment and possible iron '
        'supplementation to optimize blood health.',
    'SB-PP-05': 'Your blood pressure is elevated. Work with your healthcare provider '
        'to manage blood pressure before pregnancy through lifestyle changes '
        'or medication if needed.',
    'SB-PP-06': 'Chronic kidney disease increases pregnancy risks. '
        'Close coordination with your healthcare provider is essential before '
        'and during pregnancy.',
    'SB-PP-07': 'History of postpartum hemorrhage requires extra precautions. '
        'Inform your provider during preconception planning.',

    // PREGNANCY RULES
    'SB-PR-01': 'Your hemoglobin is below optimal levels during pregnancy. '
        'Iron supplementation (120mg daily) is recommended to prevent anemia '
        'and support fetal development.',
    'SB-PR-02': 'Daily caffeine intake exceeding 300mg may increase pregnancy loss risk. '
        'Gradual reduction to under 300mg daily (switch to decaf options) is advised.',
    'SB-PR-03': 'Your calcium intake is lower than recommended during pregnancy. '
        'Ensure 1000–1300mg daily through diet or supplements to support '
        'fetal bone development.',
    'SB-PR-04': 'Your weekly weight gain exceeds the recommended range. '
        'Seek immediate medical evaluation to rule out complications such as preeclampsia.',
    'SB-PR-05': 'Diabetes in pregnancy requires careful carbohydrate management. '
        'Aim for 45–60% carbohydrates, 15–20% protein, and 25–35% fat in your diet.',
    'SB-PR-06': 'Chronic kidney disease in pregnancy requires close monitoring. '
        'Calcium supplementation (1g twice daily) is recommended with medical oversight.',
    'SB-PR-07': 'Low calcium intake increases preeclampsia risk. '
        'Increase to 1.5–2.0g calcium daily through supplements or dietary sources.',
    'SB-PR-08': 'Ensure adequate iodine intake (200μg daily) to support thyroid '
        'function and fetal neurodevelopment. Use iodized salt or supplements.',
    'SB-PR-09': 'Maintain appropriate gestational weight gain per your healthcare provider\'s '
        'guidance, which varies by pre-pregnancy BMI.',

    // POSTPARTUM & LACTATION RULES
    'SB-PL-01': 'Continue iron supplementation for 3–6 months postpartum, especially '
        'given your history of postpartum hemorrhage, to replenish iron stores.',
    'SB-PL-02': 'During exclusive breastfeeding, increase calorie intake by 500 kcal/day '
        'and protein by 19g/day to support milk production.',
    'SB-PL-03': 'Maintain calcium intake (1000–1300mg daily) during breastfeeding '
        'to protect bone health while supporting infant nutrition.',
    'SB-PL-04': 'Ensure iodine intake (200μg daily) while breastfeeding to support '
        'infant thyroid and brain development.',
  };

  /// Generate a patient-friendly health summary from a clinical assessment.
  ///
  /// Takes a [ClinicalAssessment] from the clinical rule engine and produces
  /// a single narrative paragraph explaining the key findings in plain language.
  ///
  /// Example output:
  /// "Your assessment shows low risk. Continue with a balanced diet and prenatal
  /// vitamins. Ensure adequate folic acid (0.4mg daily) and monitor hemoglobin
  /// levels regularly..."
  static String generateHealthSummary(ClinicalAssessment assessment) {
    final buffer = StringBuffer();

    // Overall status
    final riskLabel = _riskLabel(assessment.overallRisk);
    buffer.write('Your health assessment shows $riskLabel risk. ');

    // Recommendations summary
    if (assessment.recommendations.isEmpty) {
      buffer.write('Continue with your current healthy lifestyle practices. ');
    } else {
      buffer.write('Key recommendations: ');
      final topRecommendations =
          assessment.recommendations.take(3).map((r) => r.recommendation).toList();
      buffer.write(topRecommendations.join(' '));
      if (assessment.recommendations.length > 3) {
        buffer.write(' (and ${assessment.recommendations.length - 3} more recommendations). ');
      } else {
        buffer.write('. ');
      }
    }

    // Explanation of triggered rules
    if (assessment.risks.isNotEmpty) {
      buffer.write('Specific findings: ');
      final explanations = assessment.risks
          .map((risk) => _getExplanationForRule(risk.ruleId))
          .where((e) => e.isNotEmpty)
          .take(2)
          .toList();
      if (explanations.isNotEmpty) {
        buffer.write(explanations.join(' '));
      }
      buffer.write(' ');
    }

    // Nutritional guidance
    if (assessment.nutritionalRequirements.energyKcal > 0) {
      buffer.write('Daily nutrition targets: ${assessment.nutritionalRequirements.energyKcal} kcal, '
          '${assessment.nutritionalRequirements.proteinG.toStringAsFixed(0)}g protein, '
          '${assessment.nutritionalRequirements.calciumMg}mg calcium, '
          '${assessment.nutritionalRequirements.ironMg.toStringAsFixed(1)}mg iron. ');
    }

    // Closing message
    buffer.write('Please consult your healthcare provider for personalized guidance.');

    return buffer.toString();
  }

  /// Get explanation text for a specific rule ID.
  ///
  /// Returns the predefined template if the rule exists, or an empty string.
  static String _getExplanationForRule(String ruleId) {
    return _templatesByRuleId[ruleId] ?? '';
  }

  /// Convert risk severity to patient-friendly label.
  static String _riskLabel(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 'low';
      case RiskSeverity.moderate:
        return 'moderate';
      case RiskSeverity.high:
        return 'high';
      case RiskSeverity.critical:
        return 'critical';
    }
  }

  /// Get a short explanation for display in risk cards.
  ///
  /// Returns a brief, single-sentence explanation suitable for use
  /// in risk finding cards or recommendation cards.
  static String getShortExplanation(String ruleId) {
    final fullText = _templatesByRuleId[ruleId] ?? '';
    if (fullText.isEmpty) return '';
    // Return first sentence only
    final sentences = fullText.split('. ');
    return sentences.isNotEmpty ? sentences[0] : '';
  }

  /// Get all triggered rules with their explanations.
  ///
  /// Returns a map of rule ID → explanation for easy reference.
  static Map<String, String> getExplanations(ClinicalAssessment assessment) {
    return {
      for (final risk in assessment.risks)
        risk.ruleId: _getExplanationForRule(risk.ruleId),
    };
  }
}
