/// Gemeinsames PDF-Toolkit fuer FEGH-Apps (Doku + Verwaltung).
///
/// Bietet ein einheitliches Design-System (Farben, Typografie, Abstaende),
/// Lazy-Font-Loading sowie wiederverwendbare Layout-Bausteine fuer
/// Report-PDFs.
///
/// Konkret enthalten:
///
/// - [PdfDesignTokens] - Farb- und Stilkonstanten (primaer, text, muted,
///   divider, accent, warn, tableHeader)
/// - [PdfFontCache] - laedt `Roboto-Regular.ttf` und `Roboto-Bold.ttf`
///   genau einmal aus einem Asset-Bundle und baut daraus das
///   `pw.ThemeData` fuer alle Dokumente.
/// - Layout-Bausteine: `buildHeader`, `buildFooter`, `buildHero`,
///   `buildKpiRow`, `buildSectionHeading`, `buildSignatureRow`.
/// - Widget-Bausteine: `buildStandardTable`, `buildHorizontalBarList`,
///   `buildEmptyState`.
/// - [PdfPreviewScreen] - generischer Vorschau-Screen mit Druck- und
///   Speicher-Funktionen (auf Basis von `package:printing`).
library;

export 'src/design_tokens.dart';
export 'src/font_cache.dart';
export 'src/layout/header.dart';
export 'src/layout/footer.dart';
export 'src/layout/hero.dart';
export 'src/layout/kpi_row.dart';
export 'src/layout/section_heading.dart';
export 'src/layout/signature_row.dart';
export 'src/widgets/table_builder.dart';
export 'src/widgets/bar_chart.dart';
export 'src/widgets/empty_state.dart';
export 'src/preview_screen.dart';
