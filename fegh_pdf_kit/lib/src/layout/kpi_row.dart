import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Eine einzelne KPI-Kachel fuer [buildKpiRow].
class PdfKpi {
  final String label;
  final String value;
  final PdfColor color;

  /// Hero-KPIs werden etwas groesser gesetzt (die wichtigste Zahl).
  final bool hero;

  const PdfKpi({
    required this.label,
    required this.value,
    required this.color,
    this.hero = false,
  });
}

/// Reihe aus 2-4 KPIs mit vertikalem Trennstrich dazwischen.
pw.Widget buildKpiRow(List<PdfKpi> kpis) {
  final widgets = <pw.Widget>[];
  for (var i = 0; i < kpis.length; i++) {
    widgets.add(pw.Expanded(child: _kpi(kpis[i])));
    if (i < kpis.length - 1) {
      widgets.add(
        pw.Container(
          width: 1,
          height: 32,
          color: PdfDesignTokens.divider,
          margin: const pw.EdgeInsets.symmetric(horizontal: 16),
        ),
      );
    }
  }
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: pw.BoxDecoration(
      color: PdfDesignTokens.tableHeader,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: PdfDesignTokens.divider),
    ),
    child: pw.Row(children: widgets),
  );
}

pw.Widget _kpi(PdfKpi k) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        k.label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8,
          color: PdfDesignTokens.muted,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        k.value,
        style: pw.TextStyle(
          fontSize: k.hero ? 20 : 16,
          fontWeight: pw.FontWeight.bold,
          color: k.color,
        ),
      ),
    ],
  );
}
