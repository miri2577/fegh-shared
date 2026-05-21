/// Rechnungsmodul fuer FEGH-Dokumentation und FEGH-Verwaltung.
///
/// Enthaelt die Models fuer Rechnungen (Rechnung, RechnungsPosition,
/// RechnungEmpfaenger, Kostentraeger) sowie den XRechnungService fuer
/// UBL-2.1-Export nach EN 16931 / KoSIT 3.0.
///
/// Steuerbefreite Leistungen gemaess §4 UStG (Nr. 16h EGH, Nr. 25
/// Jugendhilfe, Nr. 18 Wohlfahrt) werden korrekt mit VATEX-DE-Codes
/// ausgewiesen.
///
/// Kein App-Spezifisches: keine Persistenz (Apps nutzen eigene
/// Storage-Services), keine UI (Apps haben eigene Screens).
library;

export 'src/models/rechnung.dart';
export 'src/models/rechnung_empfaenger.dart';
export 'src/models/kostentraeger.dart';
export 'src/services/xrechnung_service.dart';
