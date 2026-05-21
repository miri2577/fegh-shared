/// Gemeinsame Compliance-Services fuer FEGH-Dokumentation und
/// FEGH-Verwaltung.
///
/// Aktuell enthalten:
/// - **AuditLogger**: persistentes JSON-Lines Log fuer DSGVO-
///   Rechenschaftspflicht (Art. 5 Abs. 2) mit Rotation (Standard
///   1095 Tage = 3 Jahre). Vordefinierte Aktionen fuer Klienten,
///   Auth, Teams, Rollen, Rechnungen.
///
/// In Planung:
/// - DsgvoExportService: Art. 20-konformer Datenexport
/// - RetentionService: automatische Loeschfristen-Ueberwachung
library;

export 'src/audit_logger.dart';
export 'src/siem_exporter.dart';
