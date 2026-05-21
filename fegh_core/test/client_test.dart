import 'package:fegh_core/fegh_core.dart';
import 'package:test/test.dart';

Client _sample() => Client(
      id: 'c-1',
      firstName: 'Anna',
      lastName: 'Schmidt',
      dateOfBirth: DateTime(1988, 7, 4),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 4, 19),
      klientenId: 'EGH-2026-12345',
      teamId: 'team-ost',
      hilfeTyp: HilfeTyp.eingliederungshilfe,
      fachleistungsstunden: 10,
      fachleistungsIntervall: FachleistungsIntervall.monatlich,
      verbrauchteStunden: 4,
      einwilligungVorhanden: true,
      einwilligungDatum: DateTime(2026, 1, 5),
      kostentraegerFallnummern: const {'empf-1': 'AZ-001'},
      bundeslandOverride: Bundesland.nordrheinWestfalen,
    );

void main() {
  group('Client — Basisfelder + Getter', () {
    test('fullName und Legacy-Alias name/vorname/nachname', () {
      final c = _sample();
      expect(c.fullName, 'Anna Schmidt');
      expect(c.name, 'Anna Schmidt');
      expect(c.vorname, 'Anna');
      expect(c.nachname, 'Schmidt');
      expect(c.vollstaendigerName, 'Anna Schmidt');
    });

    test('age berechnet aus Geburtsdatum', () {
      final c = _sample();
      expect(c.age, greaterThanOrEqualTo(37));
    });

    test('age null ohne Geburtsdatum', () {
      final c = Client(
        id: 'x',
        firstName: 'A',
        lastName: 'B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c.age, isNull);
    });
  });

  group('Client — Fachleistungsstunden-Kennzahlen', () {
    test('stundenverbrauchProzent und verfuegbareStunden', () {
      final c = _sample();
      expect(c.stundenverbrauchProzent, closeTo(40, 0.1));
      expect(c.verfuegbareStunden, 6);
    });

    test('ohne Fachleistungsstunden → 0', () {
      final c = Client(
        id: 'x',
        firstName: 'A',
        lastName: 'B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c.stundenverbrauchProzent, 0);
      expect(c.verfuegbareStunden, 0);
    });
  });

  group('Client — Kostentraeger-Fallnummern', () {
    test('fallnummerFuer liefert spezifisch, sonst klientenId', () {
      final c = _sample();
      expect(c.fallnummerFuer('empf-1'), 'AZ-001');
      expect(c.fallnummerFuer('empf-unbekannt'), 'EGH-2026-12345');
    });
  });

  group('Client — Bundesland-Integration', () {
    test('effektivesBundesland nutzt Override vor Default', () {
      final c = _sample();
      expect(c.effektivesBundesland(Bundesland.berlin),
          Bundesland.nordrheinWestfalen);
    });

    test('effektivesBundesland faellt auf Org-Bundesland zurueck', () {
      final c = Client(
        id: 'x',
        firstName: 'A',
        lastName: 'B',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(c.effektivesBundesland(Bundesland.berlin), Bundesland.berlin);
    });

    test('effektivesProfil liefert korrekte BEI_NRW-Flags', () {
      final c = _sample();
      final p = c.effektivesProfil(Bundesland.berlin);
      expect(p.bundesland, Bundesland.nordrheinWestfalen);
      expect(p.beiNrwVerfuegbar, isTrue);
      expect(p.tibBereicheVerfuegbar, isFalse);
    });
  });

  group('Client — JSON roundtrip', () {
    test('toJson/fromJson enthaelt neue und alte Feldnamen', () {
      final c = _sample();
      final j = c.toJson();
      expect(j['firstName'], 'Anna');
      expect(j['lastName'], 'Schmidt');
      expect(j['vorname'], 'Anna'); // Legacy-Alias
      expect(j['nachname'], 'Schmidt'); // Legacy-Alias
      expect(j['name'], 'Anna Schmidt'); // Legacy-Alias
      expect(j['geburtsdatum'], isA<String>()); // Legacy-Alias
      expect(j['hilfeTyp'], 'eingliederungshilfe');
      expect(j['bundeslandOverride'], 'nordrhein-westfalen');
      final restored = Client.fromJson(j);
      expect(restored.firstName, 'Anna');
      expect(restored.bundeslandOverride, Bundesland.nordrheinWestfalen);
      expect(restored.hilfeTyp, HilfeTyp.eingliederungshilfe);
      expect(restored.fachleistungsIntervall,
          FachleistungsIntervall.monatlich);
    });

    test('Legacy-Doku-JSON (nur vorname/nachname/name/geburtsdatum)', () {
      final legacy = {
        'id': 'c-legacy',
        'vorname': 'Max',
        'nachname': 'Mustermann',
        'name': 'Max Mustermann',
        'geburtsdatum': '1990-03-15T00:00:00.000',
        'klientenId': 'EGH-OLD-7',
        'einwilligungVorhanden': true,
        'createdAt': '2025-11-01T10:00:00.000',
        'updatedAt': '2026-03-20T14:00:00.000',
      };
      final c = Client.fromJson(legacy);
      expect(c.firstName, 'Max');
      expect(c.lastName, 'Mustermann');
      expect(c.klientenId, 'EGH-OLD-7');
      expect(c.einwilligungVorhanden, isTrue);
      expect(c.dateOfBirth?.year, 1990);
    });

    test('Legacy-Verwaltungs-JSON (firstName/lastName/dateOfBirth)', () {
      final legacy = {
        'id': 'c-verw',
        'firstName': 'Lisa',
        'lastName': 'Schulz',
        'dateOfBirth': '1995-06-10T00:00:00.000',
        'status': 'active',
        'priority': 'high',
        'services': ['ambulant', 'beratung'],
        'createdAt': '2026-01-10T12:00:00.000',
        'updatedAt': '2026-04-15T12:00:00.000',
      };
      final c = Client.fromJson(legacy);
      expect(c.firstName, 'Lisa');
      expect(c.status, ClientStatus.active);
      expect(c.priority, ClientPriority.high);
      expect(c.services, contains(ServiceType.ambulant));
      expect(c.services, contains(ServiceType.beratung));
    });

    test('Name-Fallback aus `name`-Feld splitten', () {
      final legacy = {
        'id': 'c-n',
        'name': 'Peter Parker',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };
      final c = Client.fromJson(legacy);
      expect(c.firstName, 'Peter');
      expect(c.lastName, 'Parker');
    });

    test('unbekannter Status/Priority → Default', () {
      final j = {
        'id': 'x',
        'firstName': 'A',
        'lastName': 'B',
        'status': 'unknown',
        'priority': 'xx',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };
      final c = Client.fromJson(j);
      expect(c.status, ClientStatus.active);
      expect(c.priority, ClientPriority.medium);
    });
  });

  group('FachleistungsIntervall', () {
    test('monatlich startet am 1. des Monats', () {
      final ref = DateTime(2026, 4, 19);
      expect(FachleistungsIntervall.monatlich.startFor(ref),
          DateTime(2026, 4, 1));
      expect(FachleistungsIntervall.monatlich.endFor(ref),
          DateTime(2026, 5, 1));
    });

    test('woechentlich startet am Montag', () {
      // 2026-04-19 ist ein Sonntag. Start: 2026-04-13 Montag.
      final ref = DateTime(2026, 4, 19);
      expect(FachleistungsIntervall.woechentlich.startFor(ref),
          DateTime(2026, 4, 13));
    });

    test('jaehrlich startet am 1.1.', () {
      final ref = DateTime(2026, 4, 19);
      expect(FachleistungsIntervall.jaehrlich.startFor(ref),
          DateTime(2026, 1, 1));
    });
  });

  group('BundeslandProfile', () {
    test('alle 16 Laender implementiert', () {
      final all = BundeslandProfile.alle();
      expect(all.length, 16);
      expect(BundeslandProfile.implementierte().length, 16);
    });

    test('Berlin → TIB + Formular 101', () {
      final p = BundeslandProfile.forLand(Bundesland.berlin);
      expect(p.bedarfsinstrument, Bedarfsinstrument.tib);
      expect(p.informationsberichtBerlin101, isTrue);
      expect(p.tibBereicheVerfuegbar, isTrue);
    });

    test('NRW → BEI_NRW', () {
      final p = BundeslandProfile.forLand(Bundesland.nordrheinWestfalen);
      expect(p.bedarfsinstrument, Bedarfsinstrument.beiNrw);
      expect(p.beiNrwVerfuegbar, isTrue);
    });

    test('bundeslandFromWire akzeptiert wireValue und enum.name', () {
      expect(bundeslandFromWire('berlin'), Bundesland.berlin);
      expect(bundeslandFromWire('nordrhein-westfalen'),
          Bundesland.nordrheinWestfalen);
      expect(bundeslandFromWire('nordrheinWestfalen'),
          Bundesland.nordrheinWestfalen); // enum.name
      expect(bundeslandFromWire(null), isNull);
      expect(bundeslandFromWire('xyz'), isNull);
    });
  });
}
