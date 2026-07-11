/// SmartBunda — Digital Assessment engine (generic, data-driven).
///
/// An [Assessment] is a list of weighted [AssessmentQuestion]s. Each answer
/// contributes points; the total is mapped to a [RiskBand] via the
/// assessment's [bands]. One runner screen serves every assessment defined in
/// [AssessmentCatalog].
///
/// These are **screening questionnaires**, not diagnoses — every result screen
/// shows a medical disclaimer. Scoring thresholds are intentionally simple and
/// transparent so they can be reviewed/tuned by a clinician.
library;

import 'package:flutter/material.dart';

/// Risk category shown on results. Colours follow the spec
/// (green / orange / red) and are accessibility-compliant; meaning is always
/// paired with a label + icon, never colour alone.
enum RiskBand { low, moderate, high }

extension RiskBandX on RiskBand {
  String get label => switch (this) {
        RiskBand.low => 'Low Risk',
        RiskBand.moderate => 'Moderate Risk',
        RiskBand.high => 'High Risk',
      };

  IconData get icon => switch (this) {
        RiskBand.low => Icons.check_circle_rounded,
        RiskBand.moderate => Icons.warning_amber_rounded,
        RiskBand.high => Icons.error_rounded,
      };

  /// Stable key for persistence.
  String get key => name;

  static RiskBand fromKey(String? key) => switch (key) {
        'moderate' => RiskBand.moderate,
        'high' => RiskBand.high,
        _ => RiskBand.low,
      };
}

/// A single answer option with its point contribution.
class AssessmentOption {
  const AssessmentOption(this.label, this.points);

  final String label;
  final int points;
}

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final String text;
  final List<AssessmentOption> options;
}

/// A score range and the [RiskBand] / summary / recommendations it maps to.
class RiskBandRule {
  const RiskBandRule({
    required this.band,
    required this.minScore,
    required this.summary,
    required this.recommendations,
  });

  final RiskBand band;

  /// Inclusive lower bound; a rule applies when score >= minScore and no
  /// higher-min rule also applies.
  final int minScore;
  final String summary;
  final List<String> recommendations;
}

class Assessment {
  const Assessment({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.instructions,
    required this.questions,
    required this.bands,
    this.version = 1,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String instructions;
  final List<AssessmentQuestion> questions;

  /// Banding rules, ordered low → high by [RiskBandRule.minScore].
  final List<RiskBandRule> bands;
  final int version;

  int get maxScore {
    var total = 0;
    for (final q in questions) {
      total += q.options
          .map((o) => o.points)
          .fold<int>(0, (a, b) => a > b ? a : b);
    }
    return total;
  }

  /// Map a raw score onto its band rule (highest matching min wins).
  RiskBandRule bandFor(int score) {
    RiskBandRule match = bands.first;
    for (final rule in bands) {
      if (score >= rule.minScore) match = rule;
    }
    return match;
  }
}

/// All assessments offered in the Digital Assessment module.
abstract final class AssessmentCatalog {
  static const List<Assessment> all = [
    _gestationalDiabetes,
    _nutritionRisk,
    _pregnancyHealth,
    _mentalWellbeing,
    _hydration,
    _lifestyle,
  ];

  static Assessment? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ── Common option sets ────────────────────────────────────────────────────
  static const _yesNo = [
    AssessmentOption('No', 0),
    AssessmentOption('Yes', 2),
  ];
  static const _freq = [
    AssessmentOption('Never', 0),
    AssessmentOption('Sometimes', 1),
    AssessmentOption('Often', 2),
    AssessmentOption('Almost always', 3),
  ];

  // ── 1. Gestational Diabetes Risk ──────────────────────────────────────────
  static const _gestationalDiabetes = Assessment(
    id: 'gdm_risk',
    title: 'Gestational Diabetes Risk',
    subtitle: 'Screen for risk factors of diabetes in pregnancy',
    icon: Icons.bloodtype_outlined,
    instructions:
        'Answer based on your history and current pregnancy. This is a '
        'screening tool — only a blood test (OGTT) ordered by your clinician '
        'can confirm gestational diabetes.',
    questions: [
      AssessmentQuestion(
        id: 'age',
        text: 'What is your age group?',
        options: [
          AssessmentOption('Under 25', 0),
          AssessmentOption('25–34', 1),
          AssessmentOption('35 or older', 2),
        ],
      ),
      AssessmentQuestion(
        id: 'family',
        text: 'Does a parent or sibling have diabetes?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'prior_gdm',
        text: 'Did you have gestational diabetes in a previous pregnancy?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'big_baby',
        text: 'Have you previously had a baby weighing 4 kg or more?',
        options: _yesNo,
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary:
            'Your answers suggest a low risk of gestational diabetes. Keep '
            'up balanced meals and regular activity.',
        recommendations: [
          'Maintain a balanced, fibre-rich diet.',
          'Stay active with safe pregnancy exercise.',
          'Attend your scheduled antenatal checkups.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 3,
        summary:
            'You have some risk factors for gestational diabetes. Discuss '
            'screening timing with your clinician.',
        recommendations: [
          'Ask your clinician about an OGTT glucose test.',
          'Limit sugary drinks and refined carbohydrates.',
          'Monitor weight gain against antenatal targets.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 6,
        summary:
            'You have several risk factors for gestational diabetes. Early '
            'glucose screening is strongly recommended.',
        recommendations: [
          'Request an early OGTT glucose tolerance test.',
          'Ask for a referral to a dietitian.',
          'Track blood glucose if advised by your clinician.',
        ],
      ),
    ],
  );

  // ── 2. Maternal Nutrition Risk ────────────────────────────────────────────
  static const _nutritionRisk = Assessment(
    id: 'nutrition_risk',
    title: 'Maternal Nutrition Risk',
    subtitle: 'Check whether your diet meets pregnancy needs',
    icon: Icons.restaurant_outlined,
    instructions:
        'Think about a typical week. There are no wrong answers — this helps '
        'identify where small diet changes could help you and your baby.',
    questions: [
      AssessmentQuestion(
        id: 'fruit_veg',
        text: 'How often do you eat fruits and vegetables?',
        options: [
          AssessmentOption('Most meals', 0),
          AssessmentOption('Once a day', 1),
          AssessmentOption('A few times a week', 2),
          AssessmentOption('Rarely', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'protein',
        text: 'How often do you eat protein (fish, eggs, beans, meat)?',
        options: [
          AssessmentOption('Every day', 0),
          AssessmentOption('Most days', 1),
          AssessmentOption('Occasionally', 2),
          AssessmentOption('Rarely', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'supplements',
        text: 'Are you taking prenatal supplements (folate / iron)?',
        options: [
          AssessmentOption('Yes, daily', 0),
          AssessmentOption('Sometimes', 2),
          AssessmentOption('No', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'skipping',
        text: 'How often do you skip meals?',
        options: _freq,
      ),
      AssessmentQuestion(
        id: 'processed',
        text: 'How often do you eat fried or heavily processed food?',
        options: _freq,
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary:
            'Your diet looks well balanced for pregnancy. Keep it up and '
            'continue your supplements.',
        recommendations: [
          'Continue daily prenatal supplements.',
          'Keep a variety of colours on your plate.',
          'Stay hydrated through the day.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 5,
        summary:
            'There is room to strengthen your diet. A few changes can improve '
            'nutrient intake for you and your baby.',
        recommendations: [
          'Add a fruit or vegetable to each meal.',
          'Avoid skipping meals — try small frequent meals.',
          'Take prenatal supplements consistently.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 10,
        summary:
            'Your diet may be missing key pregnancy nutrients. A dietitian '
            'review is recommended.',
        recommendations: [
          'Ask for a referral to a dietitian.',
          'Prioritise protein, iron and folate-rich foods.',
          'Reduce fried and processed foods.',
        ],
      ),
    ],
  );

  // ── 3. Pregnancy Health Risk ──────────────────────────────────────────────
  static const _pregnancyHealth = Assessment(
    id: 'pregnancy_health',
    title: 'Pregnancy Health Risk',
    subtitle: 'General wellbeing and warning-sign check',
    icon: Icons.pregnant_woman_outlined,
    instructions:
        'This checks for symptoms that sometimes need medical attention. If '
        'you have severe symptoms now, contact your clinic immediately rather '
        'than waiting for this result.',
    questions: [
      AssessmentQuestion(
        id: 'bp',
        text: 'Have you been told you have high blood pressure?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'swelling',
        text: 'Do you have sudden swelling of face or hands?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'headache',
        text: 'Do you have severe or persistent headaches?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'bleeding',
        text: 'Have you had any vaginal bleeding?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'movement',
        text: 'Have you noticed reduced baby movements (if applicable)?',
        options: [
          AssessmentOption('No / not applicable', 0),
          AssessmentOption('Yes', 3),
        ],
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary:
            'No major warning signs reported. Continue your routine antenatal '
            'care.',
        recommendations: [
          'Keep attending scheduled checkups.',
          'Monitor baby movements daily in later pregnancy.',
          'Note any new symptoms for your next visit.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 2,
        summary:
            'You reported a symptom worth monitoring. Mention it at your next '
            'antenatal visit.',
        recommendations: [
          'Discuss these symptoms with your clinician soon.',
          'Monitor blood pressure if you have a cuff.',
          'Rest and stay hydrated.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 5,
        summary:
            'Some symptoms you reported can be serious in pregnancy. Seek '
            'medical advice promptly.',
        recommendations: [
          'Contact your clinic or hospital today.',
          'Do not ignore bleeding, severe headache or reduced movements.',
          'Have someone accompany you if you feel unwell.',
        ],
      ),
    ],
  );

  // ── 4. Mental Wellbeing (EPDS-style screening) ────────────────────────────
  static const _mentalWellbeing = Assessment(
    id: 'mental_wellbeing',
    title: 'Mental Wellbeing',
    subtitle: 'How you have been feeling lately',
    icon: Icons.favorite_outline,
    instructions:
        'Answer how you have felt in the past 7 days, not just today. This is '
        'a wellbeing check, not a diagnosis. If you ever have thoughts of '
        'harming yourself, please reach out to someone you trust or a crisis '
        'line right away.',
    questions: [
      AssessmentQuestion(
        id: 'enjoy',
        text: 'I have been able to laugh and enjoy things.',
        options: [
          AssessmentOption('As much as always', 0),
          AssessmentOption('A little less', 1),
          AssessmentOption('Much less', 2),
          AssessmentOption('Not at all', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'anxious',
        text: 'I have felt worried or anxious for no good reason.',
        options: _freq,
      ),
      AssessmentQuestion(
        id: 'overwhelmed',
        text: 'Things have been getting on top of me / felt overwhelming.',
        options: _freq,
      ),
      AssessmentQuestion(
        id: 'sleep',
        text: 'I have had trouble sleeping due to unhappiness.',
        options: _freq,
      ),
      AssessmentQuestion(
        id: 'sad',
        text: 'I have felt sad or tearful.',
        options: _freq,
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary:
            'Your responses suggest your mood is generally okay. Keep looking '
            'after yourself.',
        recommendations: [
          'Maintain rest, light activity and social connection.',
          'Talk to loved ones about how you feel.',
          'Re-check in a couple of weeks.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 5,
        summary:
            'You may be experiencing some low mood or anxiety. Support can '
            'really help during pregnancy.',
        recommendations: [
          'Share how you feel with your clinician or midwife.',
          'Lean on trusted family or friends.',
          'Prioritise rest and gentle routines.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 10,
        summary:
            'Your responses suggest you may be struggling. Please talk to a '
            'healthcare professional soon — you deserve support.',
        recommendations: [
          'Contact your clinician about how you have been feeling.',
          'Reach out to someone you trust today.',
          'If you have thoughts of self-harm, seek urgent help immediately.',
        ],
      ),
    ],
  );

  // ── 5. Hydration ──────────────────────────────────────────────────────────
  static const _hydration = Assessment(
    id: 'hydration',
    title: 'Hydration Check',
    subtitle: 'Are you drinking enough during pregnancy?',
    icon: Icons.water_drop_outlined,
    instructions:
        'Pregnancy increases your fluid needs. Answer about a typical day.',
    questions: [
      AssessmentQuestion(
        id: 'glasses',
        text: 'How many glasses of water do you drink per day?',
        options: [
          AssessmentOption('8 or more', 0),
          AssessmentOption('5–7', 1),
          AssessmentOption('2–4', 2),
          AssessmentOption('Fewer than 2', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'urine',
        text: 'What colour is your urine, usually?',
        options: [
          AssessmentOption('Pale / clear', 0),
          AssessmentOption('Light yellow', 1),
          AssessmentOption('Dark yellow', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'thirst',
        text: 'How often do you feel very thirsty or have a dry mouth?',
        options: _freq,
      ),
      AssessmentQuestion(
        id: 'dizzy',
        text: 'Do you feel dizzy or get headaches from dehydration?',
        options: _yesNo,
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary: 'Your hydration looks good. Keep it up!',
        recommendations: [
          'Continue drinking water regularly through the day.',
          'Drink more during hot weather or activity.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 3,
        summary:
            'You could be drinking a bit more. Aim for steady fluids across '
            'the day.',
        recommendations: [
          'Keep a water bottle with you as a reminder.',
          'Aim for around 8 glasses (2 litres) a day.',
          'Use the SmartBunda hydration tracker.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 7,
        summary:
            'You show signs of low fluid intake. Increasing water matters '
            'during pregnancy.',
        recommendations: [
          'Increase water intake gradually today.',
          'Watch for dark urine, dizziness and dry mouth.',
          'Tell your clinician if symptoms persist.',
        ],
      ),
    ],
  );

  // ── 6. Lifestyle ──────────────────────────────────────────────────────────
  static const _lifestyle = Assessment(
    id: 'lifestyle',
    title: 'Lifestyle Assessment',
    subtitle: 'Daily habits that affect your pregnancy',
    icon: Icons.self_improvement_outlined,
    instructions:
        'A quick look at habits that influence a healthy pregnancy. Honest '
        'answers help you get the most useful guidance.',
    questions: [
      AssessmentQuestion(
        id: 'smoking',
        text: 'Are you exposed to smoking (active or passive)?',
        options: [
          AssessmentOption('No', 0),
          AssessmentOption('Passive only', 2),
          AssessmentOption('I smoke', 3),
        ],
      ),
      AssessmentQuestion(
        id: 'alcohol',
        text: 'Do you drink any alcohol?',
        options: _yesNo,
      ),
      AssessmentQuestion(
        id: 'activity',
        text: 'How active are you on a typical day?',
        options: [
          AssessmentOption('Active / regular exercise', 0),
          AssessmentOption('Moderately active', 1),
          AssessmentOption('Mostly sedentary', 2),
        ],
      ),
      AssessmentQuestion(
        id: 'caffeine',
        text: 'How much caffeine (coffee/tea/cola) do you have daily?',
        options: [
          AssessmentOption('Little or none', 0),
          AssessmentOption('1–2 cups', 1),
          AssessmentOption('3 or more cups', 2),
        ],
      ),
      AssessmentQuestion(
        id: 'sleep',
        text: 'How well do you sleep?',
        options: [
          AssessmentOption('Well most nights', 0),
          AssessmentOption('Sometimes poorly', 1),
          AssessmentOption('Poorly most nights', 2),
        ],
      ),
    ],
    bands: [
      RiskBandRule(
        band: RiskBand.low,
        minScore: 0,
        summary:
            'Your lifestyle supports a healthy pregnancy. Keep up the good '
            'habits.',
        recommendations: [
          'Maintain regular gentle activity.',
          'Keep caffeine within recommended limits.',
          'Protect your sleep routine.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.moderate,
        minScore: 4,
        summary:
            'A few habits could be improved to support your pregnancy.',
        recommendations: [
          'Reduce caffeine to under 200 mg/day.',
          'Add short daily walks if cleared by your clinician.',
          'Improve your wind-down routine for better sleep.',
        ],
      ),
      RiskBandRule(
        band: RiskBand.high,
        minScore: 8,
        summary:
            'Some habits may be affecting your pregnancy. Support is available '
            'to help you change them.',
        recommendations: [
          'Seek help to stop smoking and avoid alcohol.',
          'Discuss a safe activity plan with your clinician.',
          'Ask about sleep and stress support.',
        ],
      ),
    ],
  );
}
