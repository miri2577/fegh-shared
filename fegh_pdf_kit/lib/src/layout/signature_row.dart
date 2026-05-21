import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Drei Unterschriftsfelder (Ort/Datum, Autor, Teamleitung).
pw.Widget buildSignatureRow({String? authorName}) {
  pw.Widget col(String label) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 36,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfDesignTokens.text, width: 0.6),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfDesignTokens.muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Row(
    children: [
      col('ORT, DATUM'),
      pw.SizedBox(width: 24),
      col(authorName != null && authorName.isNotEmpty
          ? 'UNTERSCHRIFT ${authorName.toUpperCase()}'
          : 'UNTERSCHRIFT MITARBEITER:IN'),
      pw.SizedBox(width: 24),
      col('UNTERSCHRIFT TEAMLEITUNG'),
    ],
  );
}
