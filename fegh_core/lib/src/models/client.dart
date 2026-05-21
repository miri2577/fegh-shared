import 'bundesland.dart';

/// Lebensphasen eines Klienten (aus Verwaltungs-Sicht).
enum ClientStatus { active, inactive, pending, archived }

/// Priorisierung fuer Admin-Uebersichten.
enum ClientPriority { low, medium, high, urgent }

/// Leistungsart (Mehrfach moeglich).
enum ServiceType {
  ambulant,
  stationaer,
  beratung,
  begleitung,
  wohnen,
  arbeit,
  freizeit,
}

/// Rechtlicher Rahmen der Hilfe.
enum HilfeTyp { familienhilfe, eingliederungshilfe }

/// Abrechnungszeitraum fuer Fachleistungsstunden.
enum FachleistungsIntervall { woechentlich, monatlich, jaehrlich }

extension FachleistungsIntervallExtension on FachleistungsIntervall {
  String get displayName {
    switch (this) {
      case FachleistungsIntervall.woechentlich:
        return 'pro Woche';
      case FachleistungsIntervall.monatlich:
        return 'pro Monat';
      case FachleistungsIntervall.jaehrlich:
        return 'pro Jahr';
    }
  }

  /// Start des aktuellen Abrechnungszeitraums (bezogen auf [ref]).
  DateTime startFor(DateTime ref) {
    final tag = DateTime(ref.year, ref.month, ref.day);
    switch (this) {
      case FachleistungsIntervall.woechentlich:
        return tag.subtract(Duration(days: tag.weekday - 1));
      case FachleistungsIntervall.monatlich:
        return DateTime(ref.year, ref.month, 1);
      case FachleistungsIntervall.jaehrlich:
        return DateTime(ref.year, 1, 1);
    }
  }

  /// Ende (exklusiv) des aktuellen Abrechnungszeitraums.
  DateTime endFor(DateTime ref) {
    final s = startFor(ref);
    switch (this) {
      case FachleistungsIntervall.woechentlich:
        return s.add(const Duration(days: 7));
      case FachleistungsIntervall.monatlich:
        return DateTime(s.year, s.month + 1, 1);
      case FachleistungsIntervall.jaehrlich:
        return DateTime(s.year + 1, 1, 1);
    }
  }

  /// Legacy-Alias: frueher `startDesAktuellenZeitraums`.
  DateTime startDesAktuellenZeitraums(DateTime bezugsDatum) =>
      startFor(bezugsDatum);

  /// Legacy-Alias: frueher `endeDesAktuellenZeitraums`.
  DateTime endeDesAktuellenZeitraums(DateTime bezugsDatum) =>
      endFor(bezugsDatum);
}

extension HilfeTypExtension on HilfeTyp {
  String get wireValue {
    switch (this) {
      case HilfeTyp.familienhilfe:
        return 'familienhilfe';
      case HilfeTyp.eingliederungshilfe:
        return 'eingliederungshilfe';
    }
  }

  String get displayName {
    switch (this) {
      case HilfeTyp.familienhilfe:
        return 'Familienhilfe';
      case HilfeTyp.eingliederungshilfe:
        return 'Eingliederungshilfe';
    }
  }
}

extension ClientStatusDisplay on ClientStatus {
  String get displayName {
    switch (this) {
      case ClientStatus.active:
        return 'Aktiv';
      case ClientStatus.inactive:
        return 'Inaktiv';
      case ClientStatus.pending:
        return 'Anstehend';
      case ClientStatus.archived:
        return 'Archiviert';
    }
  }
}

extension ClientPriorityDisplay on ClientPriority {
  String get displayName {
    switch (this) {
      case ClientPriority.low:
        return 'Niedrig';
      case ClientPriority.medium:
        return 'Mittel';
      case ClientPriority.high:
        return 'Hoch';
      case ClientPriority.urgent:
        return 'Dringend';
    }
  }
}

extension ServiceTypeDisplay on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.ambulant:
        return 'Ambulant';
      case ServiceType.stationaer:
        return 'Stationaer';
      case ServiceType.beratung:
        return 'Beratung';
      case ServiceType.begleitung:
        return 'Begleitung';
      case ServiceType.wohnen:
        return 'Wohnen';
      case ServiceType.arbeit:
        return 'Arbeit';
      case ServiceType.freizeit:
        return 'Freizeit';
    }
  }
}

/// Ein Klient im FEGH-Modell.
///
/// Dieses Modell vereint die historisch getrennten Client-Definitionen
/// aus FEGH-Dokumentation (EGH-Fachtiefe) und FEGH-Verwaltung
/// (Admin-Struktur). Pflichtfelder sind bewusst minimal gehalten (id,
/// Vor-/Nachname, Anlage-Zeitpunkt) — alles weitere ist optional.
///
/// `fromJson` liest sowohl die alten Doku-Feldnamen (`vorname`,
/// `nachname`, `name`, `geburtsdatum`, `klientenId`) als auch die
/// Verwaltungs-Felder. `toJson` schreibt das neue Schema und ergaenzt
/// die Doku-Aliasse, damit beide Apps waehrend der Uebergangsphase
/// lesen koennen.
class Client {
  // ── Identitaet ────────────────────────────────────────────────────

  final String id;

  /// Aktenzeichen / interne Fallnummer (aus Doku).
  final String? klientenId;

  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;

  // ── Zuordnung und Kontakt ─────────────────────────────────────────

  final String? teamId;
  final String? email;
  final String? phone;
  final String? address;
  final String? insuranceNumber;
  final String? emergencyContact;
  final String? emergencyPhone;

  /// Verantwortliche/r Mitarbeiter:in (Hauptbetreuer).
  final String? responsibleEmployeeId;

  /// Erste Vertretung (stellvertretend zugewiesen).
  final String? deputyEmployeeId;

  /// Zweite Vertretung.
  final String? deputy2EmployeeId;

  /// Weitere zugeordnete Mitarbeiter.
  final List<String> assignedEmployees;

  /// Historisch aus Doku: Vertreter 1 (entspricht meistens deputyEmployeeId).
  final String? vertreter1Id;

  /// Historisch aus Doku: Vertreter 2.
  final String? vertreter2Id;

  // ── Status ────────────────────────────────────────────────────────

  final ClientStatus status;
  final ClientPriority priority;
  final List<ServiceType> services;

  // ── EGH-Fachfelder ────────────────────────────────────────────────

  final HilfeTyp? hilfeTyp;
  final int? fachleistungsstunden;
  final FachleistungsIntervall? fachleistungsIntervall;
  final double verbrauchteStunden;

  /// Einrichtungsuebergreifende Override-Werte.
  final double? kalkulationsfaktorOverride;
  final double? stundensatzOverride;

  /// Aktueller Kostentraeger (Freitext).
  final String? kostenuebernahme;
  final DateTime? kostenuebernahmeVon;
  final DateTime? kostenuebernahmeBis;

  /// Fallnummern pro Kostentraeger (empfaengerId → Aktenzeichen).
  final Map<String, String> kostentraegerFallnummern;

  /// Bewilligungsbescheid (haeufig auf Rechnung verlangt).
  final String? bewilligungsbescheidRef;

  /// Leistungstyp nach Landesrahmenvertrag (z. B. "B5.01").
  final String? leistungstypSchluessel;

  /// Rechtsgrundlage als Freitext (z. B. "§113 SGB IX").
  final String? rechtsgrundlage;

  /// Bundesland-Override — falls der Klient in einem anderen
  /// Bundesland betreut wird als der Traeger sitzt. Die App waehlt
  /// ueber dieses Feld das korrekte [BundeslandProfil] mit
  /// instrumentspezifischen Flags (TIB-Bereiche, BEI_NRW, ITP, ...).
  final Bundesland? bundeslandOverride;

  // ── ICF/TIB ───────────────────────────────────────────────────────

  final List<String> icfBereiche;
  final List<String> tibZiele;
  final List<String> individuelleTibZiele;
  final DateTime? betreuungSeit;

  // ── Einwilligung (Art. 9 DSGVO) ───────────────────────────────────

  final bool einwilligungVorhanden;
  final DateTime? einwilligungDatum;
  final String? einwilligungUnterschriftVon;
  final String? einwilligungWiderruflichBis;
  final String? einwilligungBemerkung;

  // ── Sonstiges ─────────────────────────────────────────────────────

  final String? berufsgruppe;
  final String? eingliederung;
  final String? caseManager;
  final String? notes;

  /// Benutzerdefinierte Kalender-/Listen-Farbe (Hex "FF1976D2").
  final String? customColor;

  /// Freies Feld fuer App-spezifische Daten (wird unveraendert
  /// durchgereicht, die andere App kann es ignorieren).
  final Map<String, dynamic> customFields;

  // ── Zeitstempel ───────────────────────────────────────────────────

  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    required this.updatedAt,
    this.klientenId,
    this.dateOfBirth,
    this.teamId,
    this.email,
    this.phone,
    this.address,
    this.insuranceNumber,
    this.emergencyContact,
    this.emergencyPhone,
    this.responsibleEmployeeId,
    this.deputyEmployeeId,
    this.deputy2EmployeeId,
    this.assignedEmployees = const [],
    this.vertreter1Id,
    this.vertreter2Id,
    this.status = ClientStatus.active,
    this.priority = ClientPriority.medium,
    this.services = const [],
    this.hilfeTyp,
    this.fachleistungsstunden,
    this.fachleistungsIntervall,
    this.verbrauchteStunden = 0,
    this.kalkulationsfaktorOverride,
    this.stundensatzOverride,
    this.kostenuebernahme,
    this.kostenuebernahmeVon,
    this.kostenuebernahmeBis,
    this.kostentraegerFallnummern = const {},
    this.bewilligungsbescheidRef,
    this.leistungstypSchluessel,
    this.rechtsgrundlage,
    this.bundeslandOverride,
    this.icfBereiche = const [],
    this.tibZiele = const [],
    this.individuelleTibZiele = const [],
    this.betreuungSeit,
    this.einwilligungVorhanden = false,
    this.einwilligungDatum,
    this.einwilligungUnterschriftVon,
    this.einwilligungWiderruflichBis,
    this.einwilligungBemerkung,
    this.berufsgruppe,
    this.eingliederung,
    this.caseManager,
    this.notes,
    this.customColor,
    this.customFields = const {},
  });

  /// Factory mit auto-generierter ID und Zeitstempeln. Akzeptiert sowohl
  /// die neuen Feldnamen (`firstName`, `lastName`, `dateOfBirth`) als auch
  /// die alten Doku-Bezeichnungen (`name`, `vorname`, `nachname`,
  /// `geburtsdatum`) — migrations-freundlich.
  factory Client.create({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    // Legacy-Aliase (Doku-API)
    String? name,
    String? vorname,
    String? nachname,
    DateTime? geburtsdatum,
    // Alle weiteren Felder
    String? klientenId,
    String? teamId,
    String? email,
    String? phone,
    String? address,
    String? insuranceNumber,
    String? emergencyContact,
    String? emergencyPhone,
    String? responsibleEmployeeId,
    String? deputyEmployeeId,
    String? deputy2EmployeeId,
    List<String> assignedEmployees = const [],
    String? vertreter1Id,
    String? vertreter2Id,
    ClientStatus status = ClientStatus.active,
    ClientPriority priority = ClientPriority.medium,
    List<ServiceType> services = const [],
    HilfeTyp? hilfeTyp,
    int? fachleistungsstunden,
    FachleistungsIntervall? fachleistungsIntervall,
    double verbrauchteStunden = 0,
    double? kalkulationsfaktorOverride,
    double? stundensatzOverride,
    String? kostenuebernahme,
    DateTime? kostenuebernahmeVon,
    DateTime? kostenuebernahmeBis,
    Map<String, String> kostentraegerFallnummern = const {},
    String? bewilligungsbescheidRef,
    String? leistungstypSchluessel,
    String? rechtsgrundlage,
    Bundesland? bundeslandOverride,
    List<String>? icfBereiche,
    List<String>? tibZiele,
    List<String>? individuelleTibZiele,
    DateTime? betreuungSeit,
    bool einwilligungVorhanden = false,
    DateTime? einwilligungDatum,
    String? einwilligungUnterschriftVon,
    String? einwilligungWiderruflichBis,
    String? einwilligungBemerkung,
    String? berufsgruppe,
    String? eingliederung,
    String? caseManager,
    String? notes,
    String? customColor,
    Map<String, dynamic> customFields = const {},
  }) {
    // Name aufloesen: bevorzugt firstName/lastName, fallback vorname/nachname,
    // fallback split aus name.
    var f = firstName ?? vorname ?? '';
    var l = lastName ?? nachname ?? '';
    if (f.isEmpty && l.isEmpty && name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        f = parts.first;
        l = parts.sublist(1).join(' ');
      } else {
        l = name;
      }
    }
    final now = DateTime.now();
    return Client(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: f,
      lastName: l,
      dateOfBirth: dateOfBirth ?? geburtsdatum,
      createdAt: now,
      updatedAt: now,
      klientenId: klientenId,
      teamId: teamId,
      email: email,
      phone: phone,
      address: address,
      insuranceNumber: insuranceNumber,
      emergencyContact: emergencyContact,
      emergencyPhone: emergencyPhone,
      responsibleEmployeeId: responsibleEmployeeId,
      deputyEmployeeId: deputyEmployeeId,
      deputy2EmployeeId: deputy2EmployeeId,
      assignedEmployees: assignedEmployees,
      vertreter1Id: vertreter1Id,
      vertreter2Id: vertreter2Id,
      status: status,
      priority: priority,
      services: services,
      hilfeTyp: hilfeTyp,
      fachleistungsstunden: fachleistungsstunden,
      fachleistungsIntervall: fachleistungsIntervall,
      verbrauchteStunden: verbrauchteStunden,
      kalkulationsfaktorOverride: kalkulationsfaktorOverride,
      stundensatzOverride: stundensatzOverride,
      kostenuebernahme: kostenuebernahme,
      kostenuebernahmeVon: kostenuebernahmeVon,
      kostenuebernahmeBis: kostenuebernahmeBis,
      kostentraegerFallnummern: kostentraegerFallnummern,
      bewilligungsbescheidRef: bewilligungsbescheidRef,
      leistungstypSchluessel: leistungstypSchluessel,
      rechtsgrundlage: rechtsgrundlage,
      bundeslandOverride: bundeslandOverride,
      icfBereiche: icfBereiche ?? const [],
      tibZiele: tibZiele ?? const [],
      individuelleTibZiele: individuelleTibZiele ?? const [],
      betreuungSeit: betreuungSeit,
      einwilligungVorhanden: einwilligungVorhanden,
      einwilligungDatum: einwilligungDatum,
      einwilligungUnterschriftVon: einwilligungUnterschriftVon,
      einwilligungWiderruflichBis: einwilligungWiderruflichBis,
      einwilligungBemerkung: einwilligungBemerkung,
      berufsgruppe: berufsgruppe,
      eingliederung: eingliederung,
      caseManager: caseManager,
      notes: notes,
      customColor: customColor,
      customFields: customFields,
    );
  }

  // ── Hilfsmethoden ─────────────────────────────────────────────────

  /// "Vorname Nachname".
  String get fullName => '$firstName $lastName'.trim();

  /// Kompatibilitaet mit alter Doku-API (`c.name`).
  String get name => fullName;

  /// Kompatibilitaet mit alter Doku-API (`c.vorname`).
  String get vorname => firstName;

  /// Kompatibilitaet mit alter Doku-API (`c.nachname`).
  String get nachname => lastName;

  /// Kompatibilitaet mit alter Doku-API (`c.geburtsdatum`).
  DateTime? get geburtsdatum => dateOfBirth;

  /// Kompatibilitaet mit alter Doku-API (`c.vollstaendigerName`).
  String get vollstaendigerName => fullName;

  /// Alter in Jahren oder `null`, falls kein Geburtsdatum gesetzt.
  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  /// Prozentualer Verbrauch der bewilligten Fachleistungsstunden.
  double get stundenverbrauchProzent {
    final soll = fachleistungsstunden;
    if (soll == null || soll == 0) return 0;
    return (verbrauchteStunden / soll) * 100;
  }

  /// Verbleibende Stunden im aktuellen Bewilligungszeitraum.
  double get verfuegbareStunden {
    final soll = fachleistungsstunden;
    if (soll == null) return 0;
    return soll.toDouble() - verbrauchteStunden;
  }

  /// Aktenzeichen fuer einen bestimmten Kostentraeger. Fallback: [klientenId].
  String? fallnummerFuer(String empfaengerId) =>
      kostentraegerFallnummern[empfaengerId] ?? klientenId;

  /// Das effektive Bundesland fuer diesen Klienten: [bundeslandOverride]
  /// falls gesetzt, sonst das vom Aufrufer uebergebene Organisations-
  /// Bundesland (meist aus den App-Einstellungen).
  Bundesland effektivesBundesland(Bundesland orgBundesland) =>
      bundeslandOverride ?? orgBundesland;

  /// Liefert das [BundeslandProfil] fuer den aktuellen Klienten (gegen
  /// das Organisations-Bundesland als Fallback).
  BundeslandProfil effektivesProfil(Bundesland orgBundesland) =>
      BundeslandProfile.forLand(effektivesBundesland(orgBundesland));

  /// Anzeigename des Status (z. B. „Aktiv").
  String get statusDisplayName => status.displayName;

  /// Anzeigename der Prioritaet (z. B. „Hoch").
  String get priorityDisplayName => priority.displayName;

  /// Anzeigename des Hilfe-Typs (z. B. „Eingliederungshilfe") oder leer.
  String get hilfeTypDisplay => hilfeTyp?.displayName ?? '';

  /// Anzeigetext des Fachleistungs-Intervalls (z. B. „pro Monat").
  String get fachleistungsIntervallDisplay =>
      fachleistungsIntervall?.displayName ?? '';

  /// Liste der Leistungs-Anzeigenamen in Render-Reihenfolge.
  List<String> get serviceDisplayNames =>
      services.map((s) => s.displayName).toList();

  // ── (De)Serialisierung ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (klientenId != null) 'klientenId': klientenId,
        if (teamId != null) 'teamId': teamId,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (insuranceNumber != null) 'insuranceNumber': insuranceNumber,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
        if (responsibleEmployeeId != null)
          'responsibleEmployeeId': responsibleEmployeeId,
        if (deputyEmployeeId != null) 'deputyEmployeeId': deputyEmployeeId,
        if (deputy2EmployeeId != null) 'deputy2EmployeeId': deputy2EmployeeId,
        'assignedEmployees': assignedEmployees,
        if (vertreter1Id != null) 'vertreter1Id': vertreter1Id,
        if (vertreter2Id != null) 'vertreter2Id': vertreter2Id,
        'status': status.name,
        'priority': priority.name,
        'services': services.map((s) => s.name).toList(),
        if (hilfeTyp != null) 'hilfeTyp': hilfeTyp!.wireValue,
        if (fachleistungsstunden != null)
          'fachleistungsstunden': fachleistungsstunden,
        if (fachleistungsIntervall != null)
          'fachleistungsIntervall': fachleistungsIntervall!.name,
        'verbrauchteStunden': verbrauchteStunden,
        if (kalkulationsfaktorOverride != null)
          'kalkulationsfaktorOverride': kalkulationsfaktorOverride,
        if (stundensatzOverride != null)
          'stundensatzOverride': stundensatzOverride,
        if (kostenuebernahme != null) 'kostenuebernahme': kostenuebernahme,
        if (kostenuebernahmeVon != null)
          'kostenuebernahmeVon': kostenuebernahmeVon!.toIso8601String(),
        if (kostenuebernahmeBis != null)
          'kostenuebernahmeBis': kostenuebernahmeBis!.toIso8601String(),
        if (kostentraegerFallnummern.isNotEmpty)
          'kostentraegerFallnummern': kostentraegerFallnummern,
        if (bewilligungsbescheidRef != null)
          'bewilligungsbescheidRef': bewilligungsbescheidRef,
        if (leistungstypSchluessel != null)
          'leistungstypSchluessel': leistungstypSchluessel,
        if (rechtsgrundlage != null) 'rechtsgrundlage': rechtsgrundlage,
        if (bundeslandOverride != null)
          'bundeslandOverride': bundeslandOverride!.wireValue,
        if (icfBereiche.isNotEmpty) 'icfBereiche': icfBereiche,
        if (tibZiele.isNotEmpty) 'tibZiele': tibZiele,
        if (individuelleTibZiele.isNotEmpty)
          'individuelleTibZiele': individuelleTibZiele,
        if (betreuungSeit != null)
          'betreuungSeit': betreuungSeit!.toIso8601String(),
        'einwilligungVorhanden': einwilligungVorhanden,
        if (einwilligungDatum != null)
          'einwilligungDatum': einwilligungDatum!.toIso8601String(),
        if (einwilligungUnterschriftVon != null)
          'einwilligungUnterschriftVon': einwilligungUnterschriftVon,
        if (einwilligungWiderruflichBis != null)
          'einwilligungWiderruflichBis': einwilligungWiderruflichBis,
        if (einwilligungBemerkung != null)
          'einwilligungBemerkung': einwilligungBemerkung,
        if (berufsgruppe != null) 'berufsgruppe': berufsgruppe,
        if (eingliederung != null) 'eingliederung': eingliederung,
        if (caseManager != null) 'caseManager': caseManager,
        if (notes != null) 'notes': notes,
        if (customColor != null) 'customColor': customColor,
        if (customFields.isNotEmpty) 'customFields': customFields,
        // Doku-Legacy-Aliasse (bidirektional lesbar).
        'vorname': firstName,
        'nachname': lastName,
        'name': fullName,
        if (dateOfBirth != null)
          'geburtsdatum': dateOfBirth!.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) {
    // Name: bevorzugt firstName/lastName, fallback vorname/nachname, fallback name-split
    String first = (json['firstName'] as String?) ??
        (json['vorname'] as String?) ??
        '';
    String last = (json['lastName'] as String?) ??
        (json['nachname'] as String?) ??
        '';
    if (first.isEmpty && last.isEmpty && json['name'] is String) {
      final parts = (json['name'] as String).split(' ');
      if (parts.length >= 2) {
        first = parts.first;
        last = parts.sublist(1).join(' ');
      } else {
        last = json['name'] as String;
      }
    }

    DateTime? dob;
    final dobRaw = json['dateOfBirth'] ?? json['geburtsdatum'];
    if (dobRaw is String && dobRaw.isNotEmpty) {
      dob = DateTime.parse(dobRaw);
    }

    final now = DateTime.now();
    return Client(
      id: json['id'] as String,
      firstName: first,
      lastName: last,
      dateOfBirth: dob,
      createdAt: _parseDate(json['createdAt']) ?? now,
      updatedAt: _parseDate(json['updatedAt']) ?? now,
      klientenId: json['klientenId'] as String?,
      teamId: json['teamId'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      insuranceNumber: json['insuranceNumber'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      responsibleEmployeeId: json['responsibleEmployeeId'] as String?,
      deputyEmployeeId: json['deputyEmployeeId'] as String?,
      deputy2EmployeeId: json['deputy2EmployeeId'] as String?,
      assignedEmployees:
          _parseStringList(json['assignedEmployees']) ?? const [],
      vertreter1Id: json['vertreter1Id'] as String?,
      vertreter2Id: json['vertreter2Id'] as String?,
      status: _parseEnum(json['status'], ClientStatus.values,
          ClientStatus.active),
      priority: _parseEnum(json['priority'], ClientPriority.values,
          ClientPriority.medium),
      services: (json['services'] as List?)
              ?.map((s) =>
                  _parseEnum(s, ServiceType.values, ServiceType.ambulant))
              .toList() ??
          const [],
      hilfeTyp: _parseHilfeTyp(json['hilfeTyp']),
      fachleistungsstunden: _asInt(json['fachleistungsstunden']),
      fachleistungsIntervall:
          _parseIntervall(json['fachleistungsIntervall']),
      verbrauchteStunden:
          (json['verbrauchteStunden'] as num?)?.toDouble() ?? 0,
      kalkulationsfaktorOverride:
          (json['kalkulationsfaktorOverride'] as num?)?.toDouble(),
      stundensatzOverride: (json['stundensatzOverride'] as num?)?.toDouble(),
      kostenuebernahme: json['kostenuebernahme'] as String?,
      kostenuebernahmeVon: _parseDate(json['kostenuebernahmeVon']),
      kostenuebernahmeBis: _parseDate(json['kostenuebernahmeBis']),
      kostentraegerFallnummern: ((json['kostentraegerFallnummern'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString()))) ??
          const {},
      bewilligungsbescheidRef: json['bewilligungsbescheidRef'] as String?,
      leistungstypSchluessel: json['leistungstypSchluessel'] as String?,
      rechtsgrundlage: json['rechtsgrundlage'] as String?,
      bundeslandOverride:
          bundeslandFromWire(json['bundeslandOverride'] as String?),
      icfBereiche: _parseStringList(json['icfBereiche']) ?? const [],
      tibZiele: _parseStringList(json['tibZiele']) ?? const [],
      individuelleTibZiele:
          _parseStringList(json['individuelleTibZiele']) ?? const [],
      betreuungSeit: _parseDate(json['betreuungSeit']),
      einwilligungVorhanden: json['einwilligungVorhanden'] as bool? ?? false,
      einwilligungDatum: _parseDate(json['einwilligungDatum']),
      einwilligungUnterschriftVon:
          json['einwilligungUnterschriftVon'] as String?,
      einwilligungWiderruflichBis:
          json['einwilligungWiderruflichBis'] as String?,
      einwilligungBemerkung: json['einwilligungBemerkung'] as String?,
      berufsgruppe: json['berufsgruppe'] as String?,
      eingliederung: json['eingliederung'] as String?,
      caseManager: json['caseManager'] as String?,
      notes: json['notes'] as String?,
      customColor: json['customColor'] as String?,
      customFields: (json['customFields'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v)) ??
          const {},
    );
  }

  // ── Parser-Helfer ─────────────────────────────────────────────────

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static List<String>? _parseStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  static T _parseEnum<T extends Enum>(
    dynamic raw,
    List<T> values,
    T fallback,
  ) {
    if (raw is String) {
      for (final e in values) {
        if (e.name == raw) return e;
      }
    }
    return fallback;
  }

  static HilfeTyp? _parseHilfeTyp(dynamic raw) {
    if (raw is String) {
      for (final t in HilfeTyp.values) {
        if (t.wireValue == raw || t.name == raw) return t;
      }
    }
    return null;
  }

  static FachleistungsIntervall? _parseIntervall(dynamic raw) {
    if (raw is String) {
      for (final i in FachleistungsIntervall.values) {
        if (i.name == raw) return i;
      }
    }
    return null;
  }

  // ── copyWith (vollstaendig, inkl. Legacy-Alias) ──────────────────

  Client copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    // Legacy-Aliase (werden durchgereicht, falls firstName/lastName/dateOfBirth nicht gesetzt)
    String? name,
    String? vorname,
    String? nachname,
    DateTime? geburtsdatum,
    // Rest
    String? klientenId,
    String? teamId,
    String? email,
    String? phone,
    String? address,
    String? insuranceNumber,
    String? emergencyContact,
    String? emergencyPhone,
    String? responsibleEmployeeId,
    String? deputyEmployeeId,
    String? deputy2EmployeeId,
    List<String>? assignedEmployees,
    String? vertreter1Id,
    String? vertreter2Id,
    ClientStatus? status,
    ClientPriority? priority,
    List<ServiceType>? services,
    HilfeTyp? hilfeTyp,
    int? fachleistungsstunden,
    FachleistungsIntervall? fachleistungsIntervall,
    double? verbrauchteStunden,
    double? kalkulationsfaktorOverride,
    double? stundensatzOverride,
    String? kostenuebernahme,
    DateTime? kostenuebernahmeVon,
    DateTime? kostenuebernahmeBis,
    Map<String, String>? kostentraegerFallnummern,
    String? bewilligungsbescheidRef,
    String? leistungstypSchluessel,
    String? rechtsgrundlage,
    Bundesland? bundeslandOverride,
    List<String>? icfBereiche,
    List<String>? tibZiele,
    List<String>? individuelleTibZiele,
    DateTime? betreuungSeit,
    bool? einwilligungVorhanden,
    DateTime? einwilligungDatum,
    String? einwilligungUnterschriftVon,
    String? einwilligungWiderruflichBis,
    String? einwilligungBemerkung,
    String? berufsgruppe,
    String? eingliederung,
    String? caseManager,
    String? notes,
    String? customColor,
    bool clearCustomColor = false,
    DateTime? updatedAt,
    Map<String, dynamic>? customFields,
  }) {
    // Name-Fallback via Legacy-Parameter
    String resolvedFirst = firstName ?? vorname ?? this.firstName;
    String resolvedLast = lastName ?? nachname ?? this.lastName;
    if (firstName == null &&
        lastName == null &&
        vorname == null &&
        nachname == null &&
        name != null &&
        name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        resolvedFirst = parts.first;
        resolvedLast = parts.sublist(1).join(' ');
      } else {
        resolvedLast = name;
      }
    }

    return Client(
      id: id,
      firstName: resolvedFirst,
      lastName: resolvedLast,
      dateOfBirth: dateOfBirth ?? geburtsdatum ?? this.dateOfBirth,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      klientenId: klientenId ?? this.klientenId,
      teamId: teamId ?? this.teamId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      responsibleEmployeeId:
          responsibleEmployeeId ?? this.responsibleEmployeeId,
      deputyEmployeeId: deputyEmployeeId ?? this.deputyEmployeeId,
      deputy2EmployeeId: deputy2EmployeeId ?? this.deputy2EmployeeId,
      assignedEmployees: assignedEmployees ?? this.assignedEmployees,
      vertreter1Id: vertreter1Id ?? this.vertreter1Id,
      vertreter2Id: vertreter2Id ?? this.vertreter2Id,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      services: services ?? this.services,
      hilfeTyp: hilfeTyp ?? this.hilfeTyp,
      fachleistungsstunden: fachleistungsstunden ?? this.fachleistungsstunden,
      fachleistungsIntervall:
          fachleistungsIntervall ?? this.fachleistungsIntervall,
      verbrauchteStunden: verbrauchteStunden ?? this.verbrauchteStunden,
      kalkulationsfaktorOverride:
          kalkulationsfaktorOverride ?? this.kalkulationsfaktorOverride,
      stundensatzOverride: stundensatzOverride ?? this.stundensatzOverride,
      kostenuebernahme: kostenuebernahme ?? this.kostenuebernahme,
      kostenuebernahmeVon: kostenuebernahmeVon ?? this.kostenuebernahmeVon,
      kostenuebernahmeBis: kostenuebernahmeBis ?? this.kostenuebernahmeBis,
      kostentraegerFallnummern:
          kostentraegerFallnummern ?? this.kostentraegerFallnummern,
      bewilligungsbescheidRef:
          bewilligungsbescheidRef ?? this.bewilligungsbescheidRef,
      leistungstypSchluessel:
          leistungstypSchluessel ?? this.leistungstypSchluessel,
      rechtsgrundlage: rechtsgrundlage ?? this.rechtsgrundlage,
      bundeslandOverride: bundeslandOverride ?? this.bundeslandOverride,
      icfBereiche: icfBereiche ?? this.icfBereiche,
      tibZiele: tibZiele ?? this.tibZiele,
      individuelleTibZiele: individuelleTibZiele ?? this.individuelleTibZiele,
      betreuungSeit: betreuungSeit ?? this.betreuungSeit,
      einwilligungVorhanden:
          einwilligungVorhanden ?? this.einwilligungVorhanden,
      einwilligungDatum: einwilligungDatum ?? this.einwilligungDatum,
      einwilligungUnterschriftVon:
          einwilligungUnterschriftVon ?? this.einwilligungUnterschriftVon,
      einwilligungWiderruflichBis:
          einwilligungWiderruflichBis ?? this.einwilligungWiderruflichBis,
      einwilligungBemerkung:
          einwilligungBemerkung ?? this.einwilligungBemerkung,
      berufsgruppe: berufsgruppe ?? this.berufsgruppe,
      eingliederung: eingliederung ?? this.eingliederung,
      caseManager: caseManager ?? this.caseManager,
      notes: notes ?? this.notes,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),
      customFields: customFields ?? this.customFields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Client && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Client(id: $id, name: $fullName, status: ${status.name})';
}
