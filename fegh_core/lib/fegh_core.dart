/// Gemeinsame Domaenen-Modelle fuer FEGH-Apps (Doku und Verwaltung).
///
/// Dieses Paket beherbergt die Entitaeten, die beide Apps ueber die
/// Cloud austauschen. Ziel: **ein** Schema, keine Parallelwelten.
///
/// Enthalten:
///
/// - [Client] — Klient mit EGH-Fachtiefe und Verwaltungs-Struktur.
///   Vereint die frueheren, divergierenden Client-Modelle der beiden
///   Apps. fromJson liest auch die alten Feldnamen (`vorname`,
///   `nachname`, `name`, `geburtsdatum`, `klientenId`), toJson
///   schreibt die neuen + Doku-Aliasse fuer eine weiche Uebergangszeit.
/// - [Bundesland] + [BundeslandProfil] + [BundeslandProfile] —
///   das vollstaendige 16-Laender-Registry mit Bedarfsinstrument,
///   Rahmenvertrag, Formular-Flags und Besonderheiten je Land.
/// - Enums: [ClientStatus], [ClientPriority], [ServiceType],
///   [HilfeTyp], [FachleistungsIntervall], [Bedarfsinstrument].
///
/// Weitere Modelle (Employee, Team, Shift) folgen in Schritt 2+ des
/// Nahtlosigkeits-Sprints.
library;

export 'src/models/bundesland.dart';
export 'src/models/client.dart';
export 'src/models/employee.dart';
export 'src/models/team.dart';
export 'src/models/shift.dart';
export 'src/services/shift_ics_exporter.dart';
