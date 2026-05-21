import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Hero-Bereich: grosser Titel mit kleiner Label-Zeile darueber
/// (z. B. "ZEITRAUM") und Untertitel darunter.
pw.Widget buildHero({
  required String label,
  required String title,
  required String subtitle,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfDesignTokens.muted,
          letterSpacing: 2,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 30,
          fontWeight: pw.FontWeight.bold,
          color: PdfDesignTokens.primaer,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        subtitle,
        style: pw.TextStyle(fontSize: 11, color: PdfDesignTokens.muted),
      ),
    ],
  );
}
