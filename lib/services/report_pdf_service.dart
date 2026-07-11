/// SmartBunda — Report PDF Service
///
/// Generates professional healthcare nutrition reports as PDF documents.
/// Uses the `pdf` package to create multi-page layouts with tables, charts,
/// and medical compliance headers/footers.
library smartbunda.report_pdf_service;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:smartbunda/models/food_entry.dart';

/// Data needed to generate a nutrition report PDF.
class ReportPdfData {
  const ReportPdfData({
    required this.patientName,
    required this.reportDate,
    required this.avgCalories,
    required this.calorieTarget,
    required this.avgProtein,
    required this.proteinTarget,
    required this.recentEntries,
  });

  final String patientName;
  final String reportDate;
  final int avgCalories;
  final int calorieTarget;
  final int avgProtein;
  final int proteinTarget;
  final List<FoodEntry> recentEntries;
}

/// Service for generating PDF reports from nutrition data.
class ReportPdfService {
  // Colors matching SmartBunda theme
  static const darkPink = PdfColor.fromInt(0xFFEC407A);
  static const primaryPink = PdfColor.fromInt(0xFFF48FB1);
  static const accentPink = PdfColor.fromInt(0xFFFF5C8A);
  static const lightPink = PdfColor.fromInt(0xFFFFF5F8);
  static const darkText = PdfColor.fromInt(0xFF333333);
  static const secondaryText = PdfColor.fromInt(0xFF757575);

  /// Generate a complete PDF report and return as bytes.
  static Future<List<int>> generateReportPdf(ReportPdfData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(data.reportDate),
        build: (context) => [
          _buildTitle(),
          pw.SizedBox(height: 20),
          _buildMetadataSection(data),
          pw.SizedBox(height: 20),
          _buildSummarySection(data),
          pw.SizedBox(height: 20),
          _buildRecentEntriesSection(data.recentEntries),
          pw.SizedBox(height: 20),
          _buildDisclaimerSection(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryPink, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SmartBunda',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: darkPink,
            ),
          ),
          pw.Text(
            'Nutrition Report',
            style: const pw.TextStyle(
              fontSize: 12,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String reportDate) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: primaryPink, width: 1),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: $reportDate',
            style: const pw.TextStyle(fontSize: 9, color: secondaryText),
          ),
          pw.Text(
            'Page #PAGENUM of #TOTALPAGES',
            style: const pw.TextStyle(fontSize: 9, color: secondaryText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weekly Nutrition Report',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: darkText,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Personal nutrition summary for the last 7 days',
          style: const pw.TextStyle(
            fontSize: 12,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetadataSection(ReportPdfData data) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryPink, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Metadata',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: darkPink,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: lightPink),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: lightPink),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Category',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Medical Report',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Status',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Completed',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: lightPink),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Prepared By',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('SmartBunda Care Team',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(data.reportDate,
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(ReportPdfData data) {
    final calorieProgress =
        (data.avgCalories / data.calorieTarget * 100).toStringAsFixed(0);
    final proteinProgress =
        (data.avgProtein / data.proteinTarget * 100).toStringAsFixed(0);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Nutrition Summary',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: darkPink,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryCard(
              label: 'Average Calories',
              value: '${data.avgCalories} kcal',
              target: '${data.calorieTarget} kcal',
              progress: calorieProgress,
            ),
            _buildSummaryCard(
              label: 'Average Protein',
              value: '${data.avgProtein}g',
              target: '${data.proteinTarget}g',
              progress: proteinProgress,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard({
    required String label,
    required String value,
    required String target,
    required String progress,
  }) {
    return pw.Container(
      width: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryPink),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: secondaryText),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: darkPink,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Target: $target',
            style: const pw.TextStyle(fontSize: 9, color: secondaryText),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Progress: $progress%',
            style: const pw.TextStyle(fontSize: 9, color: darkPink),
          ),
          pw.SizedBox(height: 8),
          _buildProgressBar(double.parse(progress) / 100),
        ],
      ),
    );
  }

  static pw.Widget _buildProgressBar(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return pw.Container(
      height: 8,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryPink),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Container(
        width: clampedProgress * 176,
        decoration: pw.BoxDecoration(
          color: clampedProgress > 1.0 ? accentPink : darkPink,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
      ),
    );
  }

  static pw.Widget _buildRecentEntriesSection(List<FoodEntry> entries) {
    final recentEntries = entries.take(7).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Food Entries (Last 7 Days)',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: darkPink,
          ),
        ),
        pw.SizedBox(height: 10),
        if (recentEntries.isEmpty)
          pw.Text(
            'No food entries logged.',
            style: const pw.TextStyle(fontSize: 10, color: secondaryText),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: primaryPink, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: lightPink),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Food',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Quantity',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Calories',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Protein',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ),
              ...recentEntries.map((entry) {
                final dateStr =
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}';
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(entry.meal,
                          style: const pw.TextStyle(fontSize: 9),
                          maxLines: 2),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(dateStr,
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${entry.quantity.toStringAsFixed(0)}g',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${entry.calories}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${entry.protein}g',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildDisclaimerSection() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accentPink),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '⚠ Medical Disclaimer',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: accentPink,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This nutrition report is generated using SmartBunda clinical screening rules and AI-assisted explanations. '
            'The values are estimates based on the Malaysian Food Composition Database (MyFCD) and may vary by preparation method and ingredients. '
            'This report does not replace professional medical or nutritional advice. '
            'Please consult your healthcare provider for personalized guidance.',
            style: const pw.TextStyle(fontSize: 9, color: secondaryText),
          ),
        ],
      ),
    );
  }
}
