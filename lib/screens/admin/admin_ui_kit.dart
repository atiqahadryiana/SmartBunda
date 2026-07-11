/// SmartBunda — Admin Dashboard shared UI kit
///
/// Theme-aware building blocks (page scaffold, header, panels, KPI cards,
/// status pills, data tables, empty states) used across every admin section.
/// All colors resolve from [AppTheme] / the active [ColorScheme] so the
/// dashboard re-themes correctly in light and dark mode.
library smartbunda.admin_ui_kit;

import 'package:flutter/material.dart';

import 'package:smartbunda/theme/app_theme.dart';

/// Soft border color used for cards/tables (resolves per brightness).
Color adminBorder(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? const Color(0xFF2A3942) : const Color(0xFFF3D6E1);
}

/// Card surface color (resolves per brightness).
Color adminSurface(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark ? AppTheme.darkElevated : Colors.white;
}

// ── Page scaffold ─────────────────────────────────────────────────────────────

/// Standard scrolling page with a header and a list of section children.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 24, 32),
      children: [
        AdminPageHeader(title: title, subtitle: subtitle, actions: actions),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        if (actions == null || actions!.isEmpty) return titleBlock;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions!),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions!),
          ],
        );
      },
    );
  }
}

// ── Panel ─────────────────────────────────────────────────────────────────────

/// A titled card container.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adminBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPink.withValues(alpha: 0.047),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

// ── KPI metric grid + card ────────────────────────────────────────────────────

class AdminMetric {
  const AdminMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color? color;
}

class AdminMetricGrid extends StatelessWidget {
  const AdminMetricGrid({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1280
            ? 6
            : width >= 1000
                ? 3
                : width >= 640
                    ? 2
                    : 1;
        const spacing = 14.0;
        final cardWidth =
            (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth.clamp(140.0, width),
                child: AdminMetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({super.key, required this.metric});

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = metric.color ?? AppTheme.darkPink;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: adminBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (metric.detail != null) ...[
            const SizedBox(height: 6),
            Text(
              metric.detail!,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SmartBundaColors>()!;
    IconData icon = Icons.circle;
    
    // Determine icon based on color similarity to semantic colors
    if (_isSimilarColor(color, semantic.success)) {
      icon = Icons.check_circle;
    } else if (_isSimilarColor(color, semantic.warning)) {
      icon = Icons.warning;
    } else if (_isSimilarColor(color, semantic.info)) {
      icon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.353)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isSimilarColor(Color a, Color b) {
    const tolerance = 30;
    return ((a.r * 255.0).round() - (b.r * 255.0).round()).abs() < tolerance &&
           ((a.g * 255.0).round() - (b.g * 255.0).round()).abs() < tolerance &&
           ((a.b * 255.0).round() - (b.b * 255.0).round()).abs() < tolerance;
  }
}

/// Maps a status string to a SmartBunda status color.
Color adminStatusColor(String status) {
  switch (status.toLowerCase().replaceAll(RegExp(r'[\s_]'), '')) {
    case 'active':
    case 'completed':
    case 'confirmed':
      return AppTheme.success;
    case 'scheduled':
    case 'pending':
      return AppTheme.warning;
    case 'cancelled':
    case 'rejected':
    case 'inactive':
    case 'noshow':
      return AppTheme.errorColor;
    default:
      return AppTheme.info;
  }
}

// ── Responsive data table ─────────────────────────────────────────────────────

/// Wraps a [DataTable] in a themed card with horizontal scroll on narrow widths
/// and a sticky-looking header row.
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 720,
  });

  final List<String> columns;
  final List<DataRow> rows;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adminBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = DataTable(
            headingRowColor: WidgetStatePropertyAll(
              AppTheme.primaryPink.withValues(alpha: 0.102),
            ),
            headingTextStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            dividerThickness: 0.6,
            columns: [
              for (final c in columns) DataColumn(label: Text(c)),
            ],
            rows: rows,
          );
          if (constraints.maxWidth >= minWidth) {
            return SizedBox(width: double.infinity, child: table);
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: table,
            ),
          );
        },
      ),
    );
  }
}

/// Identity cell: avatar initials + name + sub-label.
class AdminIdentityCell extends StatelessWidget {
  const AdminIdentityCell({
    super.key,
    required this.name,
    required this.subtitle,
    this.color,
  });

  final String name;
  final String subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppTheme.darkPink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: c.withValues(alpha: 0.141),
          child: Text(
            _initials(name),
            style: TextStyle(
                color: c, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'[\s@.]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor: adminSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: adminBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: adminBorder(context)),
        ),
      ),
    );
  }
}

// ── Empty / coming-soon state ─────────────────────────────────────────────────

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.pending = false,
  });

  final IconData icon;
  final String title;
  final String message;

  /// When true, shows a "Data pending" badge (feature awaiting backing data).
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: adminSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: adminBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.blushGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.darkPink, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (pending) ...[
            const SizedBox(height: 14),
            const AdminStatusPill(label: 'Data pending', color: AppTheme.info),
          ],
        ],
      ),
    );
  }
}

// ── Two-column responsive layout helper ───────────────────────────────────────

/// Places [left] and [right] side by side above [breakpoint], stacked below.
class AdminTwoColumn extends StatelessWidget {
  const AdminTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 1100,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.spacing = 16,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final int leftFlex;
  final int rightFlex;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [left, SizedBox(height: spacing), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class AdminSoftButton extends StatelessWidget {
  const AdminSoftButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
