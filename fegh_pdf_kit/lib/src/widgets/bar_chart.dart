import 'package:pdf/widgets.dart' as pw;

import '../design_tokens.dart';

/// Horizontale Balkenliste mit Name links, Balken mittig, Wert und
/// Prozentanteil rechts. Sortiert absteigend nach Wert.
///
/// [unit] ist die Masseinheit, die hinter dem Wert erscheint (z. B. "h").
/// [total] wird fuer die Prozentanteile genutzt; ist er 0, werden keine
/// Prozente berechnet.
pw.Widget buildHorizontalBarList(
  Map<String, double> data, {
  required double total,
  String unit = 'h',
}) {
  if (data.isEmpty) return pw.SizedBox();
  final sorted = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final max = sorted.first.value;

  return pw.Column(
    children: sorted.map((e) {
      final anteil = total > 0 ? e.value / total * 100 : 0;
      final barWidth = max > 0 ? (e.value / max) * 240.0 : 0.0;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(
                e.key,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(fontSize: 10, color: PdfDesignTokens.text),
              ),
            ),
            pw.SizedBox(
              width: 250,
              child: pw.Stack(children: [
                pw.Container(
                  height: 8,
                  width: 240,
                  decoration: pw.BoxDecoration(
                    color: PdfDesignTokens.tableHeader,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.Container(
                  height: 8,
                  width: barWidth,
                  decoration: pw.BoxDecoration(
                    color: PdfDesignTokens.primaer,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
              ]),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 60,
              child: pw.Text(
                '${e.value.toStringAsFixed(1)} $unit',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfDesignTokens.text,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 50,
              child: pw.Text(
                '${anteil.toStringAsFixed(0)} %',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: 10, color: PdfDesignTokens.muted),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
