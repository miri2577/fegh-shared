/// Kanonische Cloud-Ordnerstruktur fuer FEGH-Apps.
///
/// Doku und Verwaltung schreiben und lesen in genau dieselben Pfade,
/// damit ein Record, der von der Verwaltung angelegt wird, auch von
/// der Doku gelesen werden kann (und umgekehrt). Die Struktur orientiert
/// sich an der bereits gewachsenen Doku-Struktur:
///
/// ```
/// <root>/organizations/<orgId>/
///   ├── administration/
///   │   ├── users/roles.json
///   │   ├── clients-index.bin
///   │   ├── teams.bin
///   │   └── organization.bin
///   ├── employees/<employeeId>.bin
///   ├── teams/<teamId>/
///   │   ├── team-key.bin
///   │   ├── clients/<clientId>.bin
///   │   ├── schedules/<shiftId>.bin       (Dienstplan, Verwaltung)
///   │   ├── worktime/<employeeId>/<yyyy-mm>.bin  (Arbeitszeit)
///   │   └── reports/<reportId>.bin
///   └── shared/
///       ├── calendar-sync/
///       └── messages/
/// ```
///
/// Der Root-Praefix ist per Default `eingliederungshilfe/`, laesst sich
/// aber fuer Test-/Legacy-Szenarien ueberschreiben.
class FeghPaths {
  /// Root-Praefix aller FEGH-Daten in der Cloud.
  final String root;

  /// Organizations-ID der Mandanten-Ebene.
  final String orgId;

  const FeghPaths({
    required this.orgId,
    this.root = 'eingliederungshilfe',
  });

  // ── Basis ─────────────────────────────────────────────────────────

  /// `<root>/organizations/<orgId>`
  String get organization => '$root/organizations/$orgId';

  // ── Administration ────────────────────────────────────────────────

  /// `<root>/organizations/<orgId>/administration`
  String get administration => '$organization/administration';

  /// `<root>/organizations/<orgId>/administration/organization.bin`
  String get organizationRecord => '$administration/organization.bin';

  /// `<root>/organizations/<orgId>/administration/users/roles.json`
  String get rolesJson => '$administration/users/roles.json';

  /// `<root>/organizations/<orgId>/administration/teams.bin`
  /// (Verzeichnis aller Teams als verschluesselter Record.)
  String get teamsIndex => '$administration/teams.bin';

  /// `<root>/organizations/<orgId>/administration/clients-index.bin`
  String get clientsIndex => '$administration/clients-index.bin';

  // ── Employees ─────────────────────────────────────────────────────

  /// `<root>/organizations/<orgId>/employees`
  String get employees => '$organization/employees';

  /// `<root>/organizations/<orgId>/employees/<employeeId>.bin`
  String employeeRecord(String employeeId) =>
      '$employees/$employeeId.bin';

  // ── Teams ─────────────────────────────────────────────────────────

  /// `<root>/organizations/<orgId>/teams`
  String get teams => '$organization/teams';

  /// `<root>/organizations/<orgId>/teams/<teamId>`
  String teamRoot(String teamId) => '$teams/$teamId';

  /// `<root>/organizations/<orgId>/teams/<teamId>/team-key.bin`
  String teamKey(String teamId) => '${teamRoot(teamId)}/team-key.bin';

  /// `<root>/organizations/<orgId>/teams/<teamId>/clients`
  String teamClientsDir(String teamId) => '${teamRoot(teamId)}/clients';

  /// `<root>/organizations/<orgId>/teams/<teamId>/clients/<clientId>.bin`
  String teamClientRecord(String teamId, String clientId) =>
      '${teamClientsDir(teamId)}/$clientId.bin';

  /// `<root>/organizations/<orgId>/teams/<teamId>/schedules`
  String teamSchedulesDir(String teamId) => '${teamRoot(teamId)}/schedules';

  /// `<root>/organizations/<orgId>/teams/<teamId>/schedules/<shiftId>.bin`
  String teamShiftRecord(String teamId, String shiftId) =>
      '${teamSchedulesDir(teamId)}/$shiftId.bin';

  /// `<root>/organizations/<orgId>/teams/<teamId>/worktime`
  String teamWorktimeDir(String teamId) => '${teamRoot(teamId)}/worktime';

  /// `<root>/organizations/<orgId>/teams/<teamId>/worktime/<employeeId>/<yyyy-mm>.bin`
  String teamWorktimeRecord(String teamId, String employeeId, DateTime month) {
    final ym =
        '${month.year.toString().padLeft(4, "0")}-${month.month.toString().padLeft(2, "0")}';
    return '${teamWorktimeDir(teamId)}/$employeeId/$ym.bin';
  }

  /// `<root>/organizations/<orgId>/teams/<teamId>/reports`
  String teamReportsDir(String teamId) => '${teamRoot(teamId)}/reports';

  /// `<root>/organizations/<orgId>/teams/<teamId>/reports/<reportId>.bin`
  String teamReportRecord(String teamId, String reportId) =>
      '${teamReportsDir(teamId)}/$reportId.bin';

  // ── Shared (org-weite Kommunikations-/Sync-Daten) ─────────────────

  /// `<root>/organizations/<orgId>/shared`
  String get shared => '$organization/shared';

  /// `<root>/organizations/<orgId>/shared/calendar-sync`
  String get calendarSync => '$shared/calendar-sync';

  /// `<root>/organizations/<orgId>/shared/messages`
  String get messagesDir => '$shared/messages';

  // ── Hilfsfunktionen ──────────────────────────────────────────────

  /// Verzeichnisse (ohne Datei), die beim Org-Setup angelegt werden sollten.
  ///
  /// Nuetzlich fuer `mkcol`-Schleifen nach der ersten Anmeldung eines
  /// Admins: jede App ruft die gleiche Liste ab und legt sie an.
  List<String> bootstrapDirectories() => [
        root,
        '$root/organizations',
        organization,
        administration,
        '$administration/users',
        employees,
        teams,
        shared,
        calendarSync,
        messagesDir,
      ];
}
