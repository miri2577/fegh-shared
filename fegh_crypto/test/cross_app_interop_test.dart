import 'dart:convert';

import 'package:fegh_crypto/fegh_crypto.dart';
import 'package:test/test.dart';

/// Simuliert den Cross-App-Flow:
/// Verwaltung erzeugt einen Token / Record, Doku liest ihn - und umgekehrt.
///
/// Beide Apps nutzen dieses Package, daher sind die Tests Proxy fuer das
/// echte Zusammenspiel. Wenn hier etwas bricht, ist die Integration kaputt.
void main() {
  group('Provisioning-Token: Verwaltung → Doku', () {
    test('Verwaltung erzeugt Token mit PIN, Doku liest mit gleicher PIN',
        () async {
      // 1. Verwaltung erzeugt Token (Desktop-Admin)
      final erzeugtVonVerwaltung = ProvisioningToken(
        org: 'org-berlin-mitte',
        user: 'neuer.mitarbeiter@traeger.de',
        role: 'team_member',
        teams: ['team-lichtenberg'],
        teamKeys: {
          'team-lichtenberg': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        },
        hidrive: const HidriveCredentials(
          username: 'hidrive-user@firma.de',
          appPassword: 'app-secret-2026',
        ),
        flags: const {
          'managed': true,
          'hideCredentials': true,
          'forceInitialSync': true,
        },
        ts: DateTime.parse('2026-04-18T14:30:00Z'),
      );

      const pin = '123456';
      final qrPayload = await erzeugtVonVerwaltung.encryptWithPin(pin);

      // 2. Doku-App scannt QR und gibt PIN ein
      final empfangenVonDoku =
          await ProvisioningToken.decryptWithPin(qrPayload, pin);

      expect(empfangenVonDoku, isNotNull,
          reason: 'Doku muss Verwaltungs-QR mit korrekter PIN entschluesseln koennen');

      // 3. Alle Felder kommen korrekt an
      expect(empfangenVonDoku!.org, 'org-berlin-mitte');
      expect(empfangenVonDoku.user, 'neuer.mitarbeiter@traeger.de');
      expect(empfangenVonDoku.role, 'team_member');
      expect(empfangenVonDoku.teams, ['team-lichtenberg']);
      expect(empfangenVonDoku.teamKeys['team-lichtenberg'],
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
      expect(empfangenVonDoku.hidrive?.username, 'hidrive-user@firma.de');
      expect(empfangenVonDoku.hidrive?.appPassword, 'app-secret-2026');
      expect(empfangenVonDoku.flags['managed'], true);
      expect(empfangenVonDoku.ts, DateTime.parse('2026-04-18T14:30:00Z'));
    });

    test('Falsche PIN in Doku → null (keine Exception)', () async {
      final verwaltung = ProvisioningToken(
        org: 'x',
        user: 'y',
        role: 'z',
        teams: const [],
        ts: DateTime.now(),
      );
      final qr = await verwaltung.encryptWithPin('111111');
      final doku = await ProvisioningToken.decryptWithPin(qr, '222222');
      expect(doku, isNull);
    });

    test('Manipulierter QR-String → null', () async {
      final verwaltung = ProvisioningToken(
        org: 'x',
        user: 'y',
        role: 'z',
        teams: const [],
        ts: DateTime.now(),
      );
      final qr = await verwaltung.encryptWithPin('111111');
      // Ein Zeichen im Base64 veraendern
      final manipulated = '${qr.substring(0, 20)}X${qr.substring(21)}';
      final doku = await ProvisioningToken.decryptWithPin(manipulated, '111111');
      expect(doku, isNull);
    });
  });

  group('EncryptedRecord: HiDrive-Austausch in beide Richtungen', () {
    test('Verwaltung verschluesselt Klientendaten, Doku liest sie', () async {
      final crypto = FeghCrypto();
      final sharedMek = List<int>.generate(32, (i) => (i * 17) % 256);

      // Verwaltung hat Klientendaten angelegt und uploaded zu HiDrive
      final klientPlain = {
        'id': 'client-123',
        'name': 'Maria Musterfrau',
        'kostenuebernahme': 'Bezirksamt Mitte',
        'fachleistungsstunden': 8,
        'fachleistungsIntervall': 'woechentlich',
      };

      final recordFromVerwaltung = await crypto.encryptRecord(
        plaintext: utf8.encode(json.encode(klientPlain)),
        mek: sharedMek,
        aad: {'schema': 'client', 'clientId': 'client-123'},
      );
      final hidriveBlob = recordFromVerwaltung.toJsonString();

      // Doku-App laedt von HiDrive und entschluesselt
      final recordInDoku = EncryptedRecord.fromJsonString(hidriveBlob);
      final plainInDoku =
          await crypto.decryptRecord(record: recordInDoku, mek: sharedMek);
      final klientInDoku = json.decode(utf8.decode(plainInDoku));

      expect(klientInDoku['id'], 'client-123');
      expect(klientInDoku['name'], 'Maria Musterfrau');
      expect(klientInDoku['fachleistungsstunden'], 8);
    });

    test('Doku verschluesselt Termine, Verwaltung liest sie', () async {
      final crypto = FeghCrypto();
      final sharedMek = List<int>.generate(32, (i) => i);

      // Doku-Mitarbeiter erfasst Termin
      final terminPlain = {
        'id': 'apt-456',
        'clientId': 'client-123',
        'date': '2026-04-18',
        'fachleistungsstunden': 2.5,
        'terminArt': 'kliententermin',
      };

      final recordFromDoku = await crypto.encryptRecord(
        plaintext: utf8.encode(json.encode(terminPlain)),
        mek: sharedMek,
        aad: {'schema': 'appointment', 'id': 'apt-456'},
      );
      final blob = recordFromDoku.toJsonString();

      // Verwaltung laedt und schaut rein (z.B. fuer Reporting)
      final recordInVerwaltung = EncryptedRecord.fromJsonString(blob);
      final plainInVerwaltung = await crypto.decryptRecord(
        record: recordInVerwaltung,
        mek: sharedMek,
      );
      final terminInVerwaltung = json.decode(utf8.decode(plainInVerwaltung));

      expect(terminInVerwaltung['clientId'], 'client-123');
      expect(terminInVerwaltung['fachleistungsstunden'], 2.5);
      expect(terminInVerwaltung['terminArt'], 'kliententermin');
    });

    test('Unterschiedliche MEKs (Team A vs Team B) brechen Austausch', () async {
      final crypto = FeghCrypto();
      final teamAMek = List<int>.generate(32, (i) => i);
      final teamBMek = List<int>.generate(32, (i) => 255 - i);

      // Verwaltung (Admin) verschluesselt mit Team-A-Key
      final record = await crypto.encryptRecord(
        plaintext: utf8.encode('vertraulich'),
        mek: teamAMek,
      );

      // Team-B-Mitarbeiter sollte NICHT lesen koennen
      expect(
        () => crypto.decryptRecord(record: record, mek: teamBMek),
        throwsA(anything),
      );
    });
  });

  group('Wire-Format Stabilitaet', () {
    test('Ein Record, einmal serialisiert, bleibt dekodierbar', () async {
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('stabiltest'),
        mek: mek,
        aad: {'t': 1},
      );

      // Simuliere: Record wird als Bytes ueber Netz geschickt, wieder zurueck
      final jsonBytes = utf8.encode(rec.toJsonString());
      final wiederGeparsed = EncryptedRecord.fromJsonString(utf8.decode(jsonBytes));

      final plain = await crypto.decryptRecord(record: wiederGeparsed, mek: mek);
      expect(utf8.decode(plain), 'stabiltest');
    });
  });
}
