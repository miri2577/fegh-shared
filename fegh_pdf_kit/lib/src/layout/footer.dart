import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Fusszeile: links Erstellungsdatum, mittig App-Name, rechts Seiten-Info.
///
/// Die Funktion liefert ein Builder-Closure, wie es
/// [pw.MultiPage.footer] erwartet.
pw.Widget Function(pw.Context) buildFooter({required String appName}) {
  return (pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfDesignTokens.divider, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Erstellt ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
          ),
          pw.Text(
            appName,
            style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
          ),
          pw.Text(
            'Seite ${ctx.pageNumber} von ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfDesignTokens.muted),
          ),
        ],
      ),
    );
  };
}
