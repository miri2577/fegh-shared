import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Kopfzeile fuer Standard-Reportabellen (grauer Hintergrund,
/// primaer-farbener Text, erweitertes Letter-Spacing).
///
/// [alignRight] steuert pro Spalte die horizontale Ausrichtung.
pw.TableRow buildTableHeader(
  List<String> cells, {
  List<bool>? alignRight,
}) {
  final right = alignRight ?? List<bool>.filled(cells.length, false);
  return pw.TableRow(
    decoration: pw.BoxDecoration(color: PdfDesignTokens.tableHeader),
    children: List.generate(cells.length, (i) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        alignment: right[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          cells[i].toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfDesignTokens.primaer,
            letterSpacing: 1,
          ),
        ),
      );
    }),
  );
}

/// Datenzeile fuer Standard-Reportabellen mit feinem Trennstrich unten.
///
/// [warnIdx] markiert eine Zelle rot+fett (z. B. Ueberschreitungen).
/// Enthaelt eine rechtsbuendige Zelle die Zeichenkette `h` (Stunden),
/// wird sie fett gesetzt.
pw.TableRow buildTableRow(
  List<String> cells, {
  List<bool>? alignRight,
  int? warnIdx,
}) {
  final right = alignRight ?? List<bool>.filled(cells.length, false);
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfDesignTokens.divider, width: 0.5),
      ),
    ),
    children: List.generate(cells.length, (i) {
      final color = (warnIdx != null && i == warnIdx)
          ? PdfDesignTokens.warn
          : PdfDesignTokens.text;
      final bold = (warnIdx != null && i == warnIdx) ||
          (right[i] && cells[i].contains('h'));
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        alignment: right[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          cells[i],
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }),
  );
}

/// Convenience: komplette Tabelle mit Header und Zeilen in einem Aufruf.
pw.Widget buildStandardTable({
  required List<String> headers,
  required List<List<String>> rows,
  List<bool>? alignRight,
  Map<int, pw.TableColumnWidth>? columnWidths,
}) {
  return pw.Table(
    columnWidths: columnWidths,
    children: [
      buildTableHeader(headers, alignRight: alignRight),
      ...rows.map((r) => buildTableRow(r, alignRight: alignRight)),
    ],
  );
}
