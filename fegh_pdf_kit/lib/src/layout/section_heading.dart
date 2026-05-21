import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Ueberschrift mit nummeriertem Kreis-Chip und Titel.
/// Beispiel: Kreis "I" + "Verteilung nach Taetigkeit".
pw.Widget buildSectionHeading(String number, String title) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Container(
        width: 28,
        height: 28,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfDesignTokens.primaer,
          borderRadius: pw.BorderRadius.circular(14),
        ),
        child: pw.Text(
          number,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfDesignTokens.primaer,
          ),
        ),
      ),
    ],
  );
}
