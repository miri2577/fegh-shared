import 'package:pdf/pdf.dart';

/// Zentrale Farb- und Layout-Konstanten fuer alle Report-PDFs.
///
/// Die Werte sind so gewaehlt, dass sie auch bei Schwarz-Weiss-Druck
/// noch gut lesbar sind (Kontrastabstand gegen Weiss).
class PdfDesignTokens {
  PdfDesignTokens._();

  static const PdfColor primaer = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor text = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor divider = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor accent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor warn = PdfColor.fromInt(0xFFB91C1C);
  static const PdfColor tableHeader = PdfColor.fromInt(0xFFF3F4F6);

  /// Warn-Zwischenton fuer Auslastungen ab 75 %.
  static const PdfColor warnSoft = PdfColor.fromInt(0xFFD97706);

  /// Standard-Seitenrand fuer A4 (LTRB).
  static const double marginLeft = 50;
  static const double marginTop = 40;
  static const double marginRight = 50;
  static const double marginBottom = 50;
}
