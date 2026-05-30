/// SmartBunda — Reusable informational page (Privacy, Terms, Help, About).
///
/// Renders a simple, scrollable Material Design 3 page from a title and a list
/// of sections. Used by the Settings "Additional Settings" entries.
library smartbunda.info_page_screen;

import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../theme/app_theme.dart';

/// A titled block of body text within an [InfoPageScreen].
class InfoSection {
  const InfoSection({this.heading, required this.body});

  final String? heading;
  final String body;
}

class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.title,
    required this.sections,
    this.headerIcon = Icons.info_outline,
    this.footer,
  });

  final String title;
  final List<InfoSection> sections;
  final IconData headerIcon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.blushGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(headerIcon, color: AppTheme.darkPink, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            if (section.heading != null) ...[
              Text(
                section.heading!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              section.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Factory helpers building the four standard info pages with placeholder
/// healthcare-appropriate copy.
class SmartBundaInfoPages {
  const SmartBundaInfoPages._();

  static Widget privacyPolicy(AppStrings strings) => InfoPageScreen(
        title: strings.t('Privacy Policy'),
        headerIcon: Icons.privacy_tip_outlined,
        sections: [
          InfoSection(
            body: strings.t(
              'SmartBunda is committed to protecting the privacy of mothers and '
              'healthcare professionals who use this application.',
            ),
          ),
          InfoSection(
            heading: strings.t('Information We Collect'),
            body: strings.t(
              'We collect the health and nutrition information you provide, '
              'including profile details, food logs, and assessment answers, to '
              'deliver personalised guidance and clinical screening.',
            ),
          ),
          InfoSection(
            heading: strings.t('How We Use Your Data'),
            body: strings.t(
              'Your data is used solely to power nutrition tracking, risk '
              'assessment, and consultation features. It is never sold to third '
              'parties.',
            ),
          ),
          InfoSection(
            heading: strings.t('Data Security'),
            body: strings.t(
              'Data is stored securely in Firebase and access is restricted by '
              'role. Contact your healthcare provider for any data requests.',
            ),
          ),
        ],
      );

  static Widget termsAndConditions(AppStrings strings) => InfoPageScreen(
        title: strings.t('Terms & Conditions'),
        headerIcon: Icons.description_outlined,
        sections: [
          InfoSection(
            body: strings.t(
              'By using SmartBunda you agree to the following terms.',
            ),
          ),
          InfoSection(
            heading: strings.t('Not a Substitute for Medical Care'),
            body: strings.t(
              'SmartBunda provides nutrition guidance and screening based on '
              'Malaysian MOH guidelines. It does not replace professional medical '
              'advice, diagnosis, or treatment.',
            ),
          ),
          InfoSection(
            heading: strings.t('Acceptable Use'),
            body: strings.t(
              'You agree to provide accurate information and to use the app only '
              'for its intended maternal-health purpose.',
            ),
          ),
          InfoSection(
            heading: strings.t('Limitation of Liability'),
            body: strings.t(
              'SmartBunda and its providers are not liable for decisions made '
              'solely on the basis of in-app information.',
            ),
          ),
        ],
      );

  static Widget helpAndSupport(AppStrings strings) => InfoPageScreen(
        title: strings.t('Help & Support'),
        headerIcon: Icons.support_agent_outlined,
        sections: [
          InfoSection(
            heading: strings.t('Getting Started'),
            body: strings.t(
              'Use the Home tab to view your dashboard, the Scan tab to log meals '
              'with the camera, and the History tab to review your records.',
            ),
          ),
          InfoSection(
            heading: strings.t('Frequently Asked Questions'),
            body: strings.t(
              'For questions about nutrition targets, assessments, or '
              'appointments, speak to your assigned healthcare professional.',
            ),
          ),
          InfoSection(
            heading: strings.t('Contact Us'),
            body: strings.t(
              'For technical support, contact your clinic administrator or email '
              'support@smartbunda.app.',
            ),
          ),
        ],
      );

  static Widget about(AppStrings strings, {required String version}) =>
      InfoPageScreen(
        title: strings.t('About SmartBunda'),
        headerIcon: Icons.favorite_outline,
        sections: [
          InfoSection(
            body: strings.t(
              'SmartBunda is a maternal healthcare and nutrition monitoring '
              'application designed for pregnant mothers and the healthcare '
              'professionals who care for them.',
            ),
          ),
          InfoSection(
            heading: strings.t('Our Mission'),
            body: strings.t(
              'To make evidence-based maternal nutrition guidance accessible, '
              'using the Malaysian Food Composition Database and MOH clinical '
              'guidelines.',
            ),
          ),
        ],
        footer: Text(
          '${strings.t('Version')} $version',
          style: const TextStyle(color: AppTheme.secondaryText),
        ),
      );
}
