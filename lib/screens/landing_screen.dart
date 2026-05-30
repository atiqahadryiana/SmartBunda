import 'package:flutter/material.dart';

import 'package:smartbunda/localization/app_strings.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/screens/login_screen.dart';
import 'package:smartbunda/screens/register_screen.dart';

// Breakpoints
bool _isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const routeName = '/landing';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final baseSurface = scheme.surface;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              baseSurface,
              Color.alphaBlend(
                scheme.primary.withValues(alpha: 18),
                baseSurface,
              ),
              Color.alphaBlend(
                scheme.secondary.withValues(alpha: 10),
                baseSurface,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TopNav(
                  onSignIn: () =>
                      Navigator.of(context).pushNamed(LoginScreen.routeName),
                  onCreateAccount: () =>
                      Navigator.of(context).pushNamed(RegisterScreen.routeName),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageBand(
                  child: _HeroSection(
                    strings: strings,
                    onSignIn: () =>
                        Navigator.of(context).pushNamed(LoginScreen.routeName),
                    onCreateAccount: () => Navigator.of(context)
                        .pushNamed(RegisterScreen.routeName),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageBand(
                  child: _SurfaceSection(strings: strings),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageBand(
                  child: _WorkflowBand(strings: strings),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageBand(
                  child: _PlatformSection(strings: strings),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageBand(
                  child: _FinalCta(
                    strings: strings,
                    onSignIn: () =>
                        Navigator.of(context).pushNamed(LoginScreen.routeName),
                    onCreateAccount: () => Navigator.of(context)
                        .pushNamed(RegisterScreen.routeName),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return _PageBand(
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final brand = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkPink.withValues(alpha: 60),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smartbunda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: onSignIn,
                  child: Text(strings.t('Sign in')),
                ),
                FilledButton(
                  onPressed: onCreateAccount,
                  child: Text(strings.t('Create account')),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                brand,
                const Spacer(),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.strings,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final AppStrings strings;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 175);
    final mobile = _isMobile(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, mobile ? 20 : 34, 0, mobile ? 20 : 34),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;

          final headlineStyle = mobile
              ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: 0,
                  )
              : Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                    letterSpacing: 0,
                  );

          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(text: strings.t('AI Nutrition Tracker')),
              const SizedBox(height: 16),
              Text(
                strings.t(
                    'One nutrition platform for the clinic and the mother.'),
                style: headlineStyle,
              ),
              const SizedBox(height: 14),
              Text(
                strings.t(
                  'Smartbunda connects admin operations, care-team visibility, and daily mobile tracking in one coordinated workflow.',
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: muted,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 24),
              // On mobile — full-width stacked buttons
              if (mobile) ...[
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onPressed: onSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          strings.t('Sign in'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCreateAccount,
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(strings.t('Create account')),
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.dashboard_customize_outlined),
                      label: Text(strings.t('Open platform')),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCreateAccount,
                      icon: const Icon(Icons.phone_iphone_outlined),
                      label: Text(strings.t('Create account')),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ProofPill(label: strings.t('AI food recognition')),
                  _ProofPill(label: strings.t('Daily nutrition tracking')),
                  _ProofPill(label: strings.t('Care-team visibility')),
                ],
              ),
            ],
          );

          // On mobile — hide the complex overlay preview; show a clean stats row
          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 24),
                const _MobileHeroStats(),
              ],
            );
          }

          const preview = _HeroPreview();
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: intro),
                    const SizedBox(width: 36),
                    const Expanded(flex: 10, child: preview),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    intro,
                    const SizedBox(height: 28),
                    preview,
                  ],
                );
        },
      ),
    );
  }
}

/// Mobile-only stats row shown instead of the complex overlay preview cards.
class _MobileHeroStats extends StatelessWidget {
  const _MobileHeroStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.local_fire_department_outlined,
            value: '1,860',
            unit: 'kcal today',
            color: AppTheme.darkPink,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.water_drop_outlined,
            value: '1.6 L',
            unit: 'hydration',
            color: AppTheme.healthcareTeal,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.center_focus_strong_outlined,
            value: 'AI',
            unit: 'food scan',
            color: AppTheme.info,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 60)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1.08,
      child: Stack(
        children: [
          Positioned.fill(child: _AdminPreviewCard()),
          Positioned(
            right: 18,
            bottom: 0,
            child: SizedBox(
              width: 190,
              child: _MobilePreviewCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPreviewCard extends StatelessWidget {
  const _AdminPreviewCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final adminShell = Color.alphaBlend(
      scheme.primary.withValues(alpha: 208),
      const Color(0xFF2D1420),
    );
    final liveTone = Color.alphaBlend(
      scheme.secondary.withValues(alpha: 176),
      Colors.white,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminShell,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Approvals, access, analytics',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 180),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PreviewMetric(
                  value: '128',
                  label: 'accounts',
                  tone: liveTone,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _PreviewMetric(
                  value: '14',
                  label: 'pending reviews',
                  tone: Color(0xFFF7C97D),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _PreviewMetric(
                  value: '7',
                  label: 'high alerts',
                  tone: Color(0xFFFFA4BF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 20)),
            ),
            child: const Column(
              children: [
                _FilterChipRow(
                  items: ['Role: Patient', 'Health: Anemia', 'Sort: A-Z'],
                  inverse: true,
                ),
                SizedBox(height: 14),
                _PreviewTableRow(
                  name: 'Nur Aisyah',
                  status: 'Active',
                  detail: 'Anemia',
                  inverse: true,
                ),
                SizedBox(height: 10),
                _PreviewTableRow(
                  name: 'Klinik Sentosa',
                  status: 'Pending',
                  detail: '3 approvals',
                  inverse: true,
                ),
                SizedBox(height: 10),
                _PreviewTableRow(
                  name: 'Weekly report',
                  status: 'Ready',
                  detail: 'Generated today',
                  inverse: true,
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 185),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 40),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Operational visibility across users, approvals, and patient risk.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 170),
                ),
          ),
        ],
      ),
    );
  }
}

class _MobilePreviewCard extends StatelessWidget {
  const _MobilePreviewCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phoneShell = Color.alphaBlend(
      scheme.primary.withValues(alpha: 46),
      const Color(0xFF161018),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: phoneShell,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 30),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Mobile App',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meals, hydration, reminders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            const _PreviewInfoCard(
              title: 'Today',
              value: '1,860 kcal',
              subtitle: 'Protein on track',
            ),
            const SizedBox(height: 10),
            const _MiniActionRow(
              icon: Icons.center_focus_strong,
              title: 'Scan meal',
            ),
            const SizedBox(height: 8),
            const _MiniActionRow(
              icon: Icons.water_drop_outlined,
              title: 'Log hydration',
            ),
            const SizedBox(height: 8),
            const _MiniActionRow(
              icon: Icons.event_available_outlined,
              title: 'Check appointment',
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceSection extends StatelessWidget {
  const _SurfaceSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final vPad = _isMobile(context) ? 16.0 : 28.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            eyebrow: strings.t('Two connected surfaces'),
            title: strings.t(
                'Admin control for the clinic. Simple tracking for the patient.'),
            body: strings.t(
              'Smartbunda gives administrators a professional control layer while keeping the mobile experience focused on daily habits and care follow-up.',
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return wide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _SurfaceCard.admin()),
                        SizedBox(width: 16),
                        Expanded(child: _SurfaceCard.mobile()),
                      ],
                    )
                  : const Column(
                      children: [
                        _SurfaceCard.admin(),
                        SizedBox(height: 16),
                        _SurfaceCard.mobile(),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard._({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.accent,
    required this.preview,
  });

  const _SurfaceCard.admin()
      : this._(
          icon: Icons.space_dashboard_outlined,
          title: 'Admin dashboard',
          subtitle:
              'Designed for staff approvals, access control, reporting, and system oversight.',
          points: const [
            'User approvals and role management',
            'Operational filters, sorting, and review queues',
            'Reporting, analytics, and system health',
          ],
          accent: AppTheme.darkPink,
          preview: const _AdminSurfacePreview(),
        );

  const _SurfaceCard.mobile()
      : this._(
          icon: Icons.phone_iphone_outlined,
          title: 'Mobile app',
          subtitle:
              'Built for mothers to log meals, hydration, appointments, and nutrition progress quickly.',
          points: const [
            'Meal logging and image-based food scan',
            'Hydration and appointment tracking',
            'Simple summaries and care-team visibility',
          ],
          accent: AppTheme.accentPink,
          preview: const _MobileSurfacePreview(),
        );

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> points;
  final Color accent;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          preview,
          const SizedBox(height: 18),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FeatureRow(text: point, accent: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSurfacePreview extends StatelessWidget {
  const _AdminSurfacePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 50),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _FilterChipRow(
            items: ['Clinic', 'Health problem', 'A-Z'],
            inverse: false,
          ),
          SizedBox(height: 12),
          _PreviewTableRow(
            name: 'Pending staff approvals',
            status: '14',
            detail: 'Needs review',
            inverse: false,
          ),
          SizedBox(height: 10),
          _PreviewTableRow(
            name: 'Patient directory',
            status: '128',
            detail: 'Filtered by anemia',
            inverse: false,
          ),
        ],
      ),
    );
  }
}

class _MobileSurfacePreview extends StatelessWidget {
  const _MobileSurfacePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 50),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          _PreviewInfoCard(
            title: 'Breakfast log',
            value: '420 kcal',
            subtitle: 'Saved from meal scan',
          ),
          SizedBox(height: 10),
          _PreviewInfoCard(
            title: 'Hydration',
            value: '1.6 L',
            subtitle: '2 reminders left today',
          ),
        ],
      ),
    );
  }
}

class _WorkflowBand extends StatelessWidget {
  const _WorkflowBand({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = _isMobile(context);
    final vPad = mobile ? 16.0 : 28.0;
    final inner = mobile ? 18.0 : 26.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Container(
        padding: EdgeInsets.all(inner),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkPink.withValues(alpha: 50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(
              text: strings.t('Shared workflow'),
              inverse: true,
            ),
            const SizedBox(height: 16),
            Text(
              strings.t('From patient action to admin visibility in one loop.'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.t(
                'Daily intake and patient activity stay visible to the clinic, while admin teams keep access, approvals, and reporting organized.',
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 210),
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                final steps = [
                  _WorkflowStep(
                    index: '01',
                    title: strings.t('Patient logs meals'),
                    body: strings.t(
                      'The mobile app captures food, hydration, and appointment activity.',
                    ),
                  ),
                  _WorkflowStep(
                    index: '02',
                    title: strings.t('Care data becomes visible'),
                    body: strings.t(
                      'Nutrition and monitoring workflows share a consistent patient record.',
                    ),
                  ),
                  _WorkflowStep(
                    index: '03',
                    title: strings.t('Admin teams stay in control'),
                    body: strings.t(
                      'Approvals, user policies, and reports remain manageable from the dashboard.',
                    ),
                  ),
                ];
                return wide
                    ? Row(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            Expanded(child: steps[i]),
                            if (i < steps.length - 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color:
                                      scheme.onPrimary.withValues(alpha: 170),
                                ),
                              ),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            steps[i],
                            if (i < steps.length - 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color:
                                      scheme.onPrimary.withValues(alpha: 170),
                                ),
                              ),
                          ],
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  const _PlatformSection({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final vPad = _isMobile(context) ? 16.0 : 28.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            eyebrow: strings.t('Platform coverage'),
            title: strings
                .t('Built for real clinic operations and daily mobile use.'),
            body: strings.t(
              'The web-style admin experience gives staff a broader operational view, while the mobile flow stays quick enough for repeat daily logging.',
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 2.6 : 1.28,
                children: [
                  _RoleCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: strings.t('Admin operations'),
                    body: strings.t(
                      'Approvals, account control, patient directory review, and reporting.',
                    ),
                  ),
                  _RoleCard(
                    icon: Icons.medical_services_outlined,
                    title: strings.t('Care teams'),
                    body: strings.t(
                      'Patient profiles, nutrition analysis, monitoring, and plans.',
                    ),
                  ),
                  _RoleCard(
                    icon: Icons.phone_android_outlined,
                    title: strings.t('Mobile tracking'),
                    body: strings.t(
                      'Meal scan, hydration logging, appointments, and daily summaries.',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta({
    required this.strings,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final AppStrings strings;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 56),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t(
                      'Launch the dashboard. Keep the mobile experience close.'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.t(
                    'Use one Smartbunda workspace to coordinate admin teams, care teams, and patient habits.',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 170),
                        height: 1.5,
                      ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: onSignIn,
                  child: Text(strings.t('Sign in')),
                ),
                FilledButton(
                  onPressed: onCreateAccount,
                  child: Text(strings.t('Create account')),
                ),
              ],
            );
            return wide
                ? Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 18),
                      actions,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 18),
                      actions,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _PageBand extends StatelessWidget {
  const _PageBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({
    required this.text,
    this.inverse = false,
  });

  final String text;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: inverse
            ? scheme.onPrimary.withValues(alpha: 28)
            : scheme.primary.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: inverse ? scheme.onPrimary : scheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: eyebrow),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 170),
                  height: 1.55,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProofPill extends StatelessWidget {
  const _ProofPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: scheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.value,
    required this.label,
    required this.tone,
  });

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 180),
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.items,
    required this.inverse,
  });

  final List<String> items;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: inverse
                    ? Colors.white.withValues(alpha: 12)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: inverse
                      ? Colors.white.withValues(alpha: 18)
                      : scheme.outlineVariant,
                ),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: inverse ? Colors.white : scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewTableRow extends StatelessWidget {
  const _PreviewTableRow({
    required this.name,
    required this.status,
    required this.detail,
    required this.inverse,
  });

  final String name;
  final String status;
  final String detail;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusTone = inverse
        ? Color.alphaBlend(scheme.secondary.withValues(alpha: 188), Colors.white)
        : scheme.primary;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: inverse ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: inverse
                ? Colors.white.withValues(alpha: 12)
                : scheme.primary.withValues(alpha: 12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusTone,
                  fontWeight: FontWeight.w800,
                ),
            ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(
            detail,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inverse
                      ? Colors.white.withValues(alpha: 170)
                      : scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _PreviewInfoCard extends StatelessWidget {
  const _PreviewInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 70),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionRow extends StatelessWidget {
  const _MiniActionRow({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 180),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 205),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.text,
    required this.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.check, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 165),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
