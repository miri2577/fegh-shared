import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Kopfzeile im behoerdlichen Stil: linker App-Name + Untertitel,
/// rechts der Report-Titel (gesperrt) und optional ein Aktenzeichen.
///
/// [appName] z. B. "FEGH-Dokumentation" oder "FEGH-Verwaltung".
/// [appTagline] ist die kleine Zeile darunter, z. B. "Eingliederungshilfe
/// nach SGB IX".
pw.Widget buildHeader({
  required String title,
  required String appName,
  required String appTagline,
  String? aktenzeichen,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfDesignTokens.primaer, width: 2),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              appName,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfDesignTokens.primaer,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              appTagline,
              style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfDesignTokens.muted,
                letterSpacing: 2,
              ),
            ),
            if (aktenzeichen != null && aktenzeichen.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'AZ: $aktenzeichen',
                style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
