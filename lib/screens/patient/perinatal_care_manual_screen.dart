import 'package:flutter/material.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/widgets/screen_header.dart';

class PerinatalCareManualScreen extends StatelessWidget {
  const PerinatalCareManualScreen({super.key});

  static const _sections = <_CareSection>[
    _CareSection(
      title: 'Pre-pregnancy care workflow',
      icon: Icons.account_tree_outlined,
      points: [
        'Identify clients from outpatient, maternal and child health, specialist, inpatient, ambulatory, private, or community entry points.',
        'Assess history, physical examination, laboratory results, pregnancy intention, and suitability for pregnancy.',
        'Optimise medical and biopsychosocial risk, give healthy lifestyle advice, offer family planning, and start folic acid when appropriate.',
        'Refer or share care with relevant specialties when pregnancy safety depends on condition control.',
        'Reassess risk and pregnancy intention at follow-up until the patient is ready or pregnancy is deferred.',
      ],
    ),
    _CareSection(
      title: 'First assessment checklist',
      icon: Icons.fact_check_outlined,
      points: [
        'Record obstetric and gynaecological history, vaccination status, contraception, medications, and psychosocial risks.',
        'Screen for diabetes, hypertension, asthma, cardiovascular disease, mental illness, and other chronic conditions.',
        'Measure height, weight, BMI, blood pressure, pulse, pallor, cardiovascular, respiratory, and thyroid findings.',
        'Include haemoglobin, Pap smear status when relevant, and other indicated investigations.',
        'Document pregnancy intention, pregnancy suitability, care plan, referral needs, and follow-up.',
      ],
    ),
    _CareSection(
      title: 'Risk factors to flag',
      icon: Icons.flag_outlined,
      points: [
        'Age under 18 or over 40, obesity, underweight, smoking, alcohol, substance use, high-risk sexual behaviour, or unsafe exposures.',
        'Chronic conditions such as hypertension, heart disease, diabetes, thyroid disease, epilepsy, asthma, SLE, renal disease, blood disorders, malignancy, transplant history, or mental illness.',
        'Infectious disease risks such as HIV, active tuberculosis, hepatitis B, hepatitis C, or other sexually transmitted infections.',
        'Family history of congenital structural or genetic disorders, previous unexplained fetal loss, or consanguinity.',
        'Social risks including domestic violence, limited support, marginalisation, or single motherhood.',
      ],
    ),
    _CareSection(
      title: 'Condition-specific SOP focus',
      icon: Icons.medical_services_outlined,
      points: [
        'Diabetes: optimise glycaemic control, screen complications, review medicines, counsel pregnancy risks, and use multidisciplinary care.',
        'Hypertension and cardiac disease: assess severity, end-organ effects, medication safety, pregnancy contraindications, and specialist shared care.',
        'Thyroid disease, epilepsy, asthma, SLE, renal disease, thalassaemia, malignancy, HIV, transplant history, mental illness, and substance use require targeted assessment and referral based on stability and risk.',
        'Medication review should remove or replace known teratogenic agents before conception whenever clinically possible.',
        'Folic acid supplementation and appropriate contraception are recurring care-plan items until pregnancy is suitable.',
      ],
    ),
    _CareSection(
      title: 'Health education and counselling',
      icon: Icons.school_outlined,
      points: [
        'Promote balanced meals, adequate fluids, supportive relationships, regular activity, healthy sleep, and avoidance of smoking, alcohol, and substance use.',
        'Counsel genetic risks when there is consanguinity, family history, previous affected child, male X-linked disorder, or unexplained fetal loss.',
        'Encourage pregnancy planning, effective contraception while conditions are not optimised, and early antenatal booking before 12 weeks.',
        'Review vaccination status for rubella, hepatitis B, varicella, and COVID-19 before pregnancy when indicated.',
        'Explain how social behaviour, medication, nutrition status, and medical history can affect pregnancy outcomes.',
      ],
    ),
  ];

  static const _visits = <_AntenatalVisit>[
    _AntenatalVisit(
        'Before 12 weeks', 'Physical', 'Primigravida and multigravida'),
    _AntenatalVisit('16-20 weeks', 'Physical', 'Primigravida and multigravida'),
    _AntenatalVisit(
        '24-26 weeks', 'Physical or virtual', 'Primigravida and multigravida'),
    _AntenatalVisit('28-30 weeks', 'Physical', 'Primigravida and multigravida'),
    _AntenatalVisit(
        '32-34 weeks', 'Physical or virtual', 'Primigravida and multigravida'),
    _AntenatalVisit('35-36 weeks', 'Physical', 'Primigravida and multigravida'),
    _AntenatalVisit('37 weeks', 'Physical', 'Primigravida'),
    _AntenatalVisit('38 weeks', 'Physical', 'Primigravida and multigravida'),
    _AntenatalVisit('39 weeks', 'Physical', 'Primigravida'),
    _AntenatalVisit('40 weeks', 'Physical', 'Primigravida and multigravida'),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('Perinatal care manual'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScreenHeader(
            title: strings.t('Perinatal care manual'),
            subtitle: strings.t(
              'Structured guidance from pages 29-79 for pre-pregnancy and early antenatal care.',
            ),
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 16),
          ..._sections.map((section) => _CareSectionCard(section: section)),
          const SizedBox(height: 8),
          Text(
            strings.t('Antenatal visit schedule'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _visits
                  .map(
                    (visit) => ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: Text(visit.gestation),
                      subtitle: Text('${visit.mode} | ${visit.appliesTo}'),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t(
                'Use this as care-team reference material, not as a replacement for clinician judgement.'),
            style:
                TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CareSectionCard extends StatelessWidget {
  const _CareSectionCard({required this.section});

  final _CareSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(section.icon),
        title: Text(section.title),
        children: section.points
            .map(
              (point) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(point),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CareSection {
  const _CareSection({
    required this.title,
    required this.icon,
    required this.points,
  });

  final String title;
  final IconData icon;
  final List<String> points;
}

class _AntenatalVisit {
  const _AntenatalVisit(this.gestation, this.mode, this.appliesTo);

  final String gestation;
  final String mode;
  final String appliesTo;
}
