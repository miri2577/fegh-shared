import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Dezent gestaltete Info-Box fuer "keine Daten im Zeitraum".
pw.Widget buildEmptyState(String message) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfDesignTokens.tableHeader,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      message,
      style: pw.TextStyle(fontSize: 11, color: PdfDesignTokens.muted),
    ),
  );
}
