/// SmartBunda — Report Preview Widget
///
/// Modular components for displaying medical reports with proper typography,
/// metadata cards, and PDF preview sections. Designed for healthcare compliance
/// and Material Design 3 aesthetic.
library smartbunda.report_preview_widget;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Report Title Section ──────────────────────────────────────────────────────

class ReportTitleSection extends StatelessWidget {
  const ReportTitleSection({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryText,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ── Report Metadata Grid ──────────────────────────────────────────────────────

class ReportMetadataGrid extends StatelessWidget {
  const ReportMetadataGrid({
    super.key,
    required this.category,
    required this.status,
    required this.preparedBy,
    required this.date,
  });

  final String category;
  final String status;
  final String preparedBy;
  final String date;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final crossAxisCount = isWide ? 4 : 2;
        final childAspectRatio = isWide ? 1.2 : 1.0;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            ReportMetadataItem(
              label: 'Category',
              value: category,
              icon: Icons.assignment_outlined,
            ),
            ReportMetadataItem(
              label: 'Status',
              value: status,
              icon: Icons.check_circle_outlined,
            ),
            ReportMetadataItem(
              label: 'Prepared By',
              value: preparedBy,
              icon: Icons.person_outline,
            ),
            ReportMetadataItem(
              label: 'Date',
              value: date,
              icon: Icons.calendar_today_outlined,
            ),
          ],
        );
      },
    );
  }
}

// ── Report Metadata Item ──────────────────────────────────────────────────────

class ReportMetadataItem extends StatelessWidget {
  const ReportMetadataItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.darkPink,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PDF Preview Section ───────────────────────────────────────────────────────

class PDFPreviewSection extends StatelessWidget {
  const PDFPreviewSection({
    super.key,
    this.pdfUrl,
    this.onOpen,
    this.onDownload,
    this.onShare,
  });

  final String? pdfUrl;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final hasPdf = pdfUrl != null && pdfUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPink.withValues(alpha: 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Document',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          // PDF Placeholder
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasPdf ? Icons.description_outlined : Icons.file_present,
                    size: 48,
                    color: hasPdf ? AppTheme.darkPink : AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasPdf ? 'PDF Report Ready' : 'No PDF Available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.open_in_new,
                  label: 'Open',
                  enabled: hasPdf,
                  onPressed: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  enabled: hasPdf,
                  onPressed: onDownload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  enabled: hasPdf,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? AppTheme.darkPink : Colors.grey[300]!,
        ),
        foregroundColor: enabled ? AppTheme.darkPink : Colors.grey[400],
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ── Report Summary Card ───────────────────────────────────────────────────────

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF8BBD0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Medical Disclaimer Banner ─────────────────────────────────────────────────

class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({
    super.key,
    this.text,
  });

  final String? text;

  @override
  Widget build(BuildContext context) {
    final disclaimerText = text ??
        'This assessment is generated using SmartBunda clinical screening rules and AI-assisted explanations. It does not replace professional medical advice. Please consult with your healthcare provider for personalized guidance.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0).withValues(alpha: 200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB74D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outlined,
            color: Color(0xFFE65100),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              disclaimerText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFBF360C),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
