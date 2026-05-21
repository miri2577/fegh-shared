import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Lazy-Loader fuer die Roboto-Schrift, die beide Apps im Bundle
/// mitliefern. Die Schrift wird pro Prozess genau einmal geladen.
///
/// Die App bestimmt, in welchem Asset-Pfad die TTFs liegen.
/// Default: `assets/fonts/Roboto-Regular.ttf` und
/// `assets/fonts/Roboto-Bold.ttf` (beide Apps nutzen bereits dieses
/// Schema).
class PdfFontCache {
  PdfFontCache._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Laedt (falls noch nicht geschehen) Roboto-Regular und Roboto-Bold
  /// und gibt ein `pw.ThemeData` zurueck, das beide Schnitte als
  /// Basisschrift verwendet.
  ///
  /// [bundle] kann in Tests ueberschrieben werden. Default: `rootBundle`.
  static Future<pw.ThemeData> theme({
    String regularAsset = 'assets/fonts/Roboto-Regular.ttf',
    String boldAsset = 'assets/fonts/Roboto-Bold.ttf',
    AssetBundle? bundle,
  }) async {
    final b = bundle ?? rootBundle;
    _regular ??= pw.Font.ttf(await b.load(regularAsset));
    _bold ??= pw.Font.ttf(await b.load(boldAsset));
    return pw.ThemeData.withFont(base: _regular!, bold: _bold!);
  }

  /// Setzt den Cache zurueck (fuer Tests).
  static void resetForTests() {
    _regular = null;
    _bold = null;
  }
}
