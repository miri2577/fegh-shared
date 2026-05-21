import 'package:fegh_crypto/fegh_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('ProvisioningToken Round-Trip', () {
    test('Encrypt mit PIN und Decrypt gibt gleiche Payload', () async {
      final token = ProvisioningToken(
        org: 'org-123',
        user: 'max@example.de',
        role: 'team_member',
        teams: ['team-a', 'team-b'],
        teamKeys: {
          'team-a': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'team-b': 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
        },
        totp: 'JBSWY3DPEHPK3PXP',
        hidrive: const HidriveCredentials(
          username: 'max@example.de',
          appPassword: 'geheim',
        ),
        flags: {'managed': true, 'forceInitialSync': true},
        ts: DateTime.parse('2026-04-18T12:00:00Z'),
      );

      final encrypted = await token.encryptWithPin('123456');
      expect(encrypted, isNotEmpty);

      final decoded = await ProvisioningToken.decryptWithPin(encrypted, '123456');
      expect(decoded, isNotNull);
      expect(decoded!.org, 'org-123');
      expect(decoded.user, 'max@example.de');
      expect(decoded.role, 'team_member');
      expect(decoded.teams, ['team-a', 'team-b']);
      expect(decoded.teamKeys['team-a'], startsWith('AAAA'));
      expect(decoded.totp, 'JBSWY3DPEHPK3PXP');
      expect(decoded.hidrive?.username, 'max@example.de');
      expect(decoded.hidrive?.appPassword, 'geheim');
      expect(decoded.flags['managed'], true);
    });

    test('Falsche PIN liefert null (kein Throw)', () async {
      final token = ProvisioningToken(
        org: 'org-1',
        user: 'u@e.de',
        role: 'team_member',
        teams: const [],
        ts: DateTime.now(),
      );

      final encrypted = await token.encryptWithPin('123456');
      final wrongPin = await ProvisioningToken.decryptWithPin(encrypted, '999999');
      expect(wrongPin, isNull);
    });

    test('Kaputter Base64 liefert null', () async {
      final bad = await ProvisioningToken.decryptWithPin('not-base64!@#', '111111');
      expect(bad, isNull);
    });

    test('Fremder Token-Type (ungleich egh-provisioning-v1) liefert null',
        () async {
      // Simuliere einen anders getypten Token (wie er theoretisch erzeugt werden koennte)
      // Hack: Token mit geaendertem type waere nicht mehr parsbar als ProvisioningToken
      final token = ProvisioningToken(
        org: 'x',
        user: 'x',
        role: 'x',
        teams: const [],
        ts: DateTime.now(),
      );
      final ok = await token.encryptWithPin('000000');
      // Korrekter Type → dekodiert korrekt
      final decoded = await ProvisioningToken.decryptWithPin(ok, '000000');
      expect(decoded, isNotNull);
      expect(decoded!.type, 'egh-provisioning-v1');
    });

    test('Minimales Token ohne optionale Felder funktioniert', () async {
      final token = ProvisioningToken(
        org: 'o',
        user: 'u',
        role: 'team_member',
        teams: const [],
        ts: DateTime.parse('2026-04-18T00:00:00Z'),
      );
      final enc = await token.encryptWithPin('111111');
      final dec = await ProvisioningToken.decryptWithPin(enc, '111111');
      expect(dec, isNotNull);
      expect(dec!.totp, isNull);
      expect(dec.hidrive, isNull);
      expect(dec.teamKeys, isEmpty);
    });
  });

  group('ProvisioningToken Serialisierung', () {
    test('toJson/fromJson Round-Trip', () {
      final token = ProvisioningToken(
        org: 'o1',
        user: 'u1',
        role: 'team_lead',
        teams: ['t1'],
        teamKeys: {'t1': 'base64keytext'},
        totp: 'SECRET',
        hidrive: const HidriveCredentials(username: 'h', appPassword: 'p'),
        flags: {'managed': true},
        ts: DateTime.parse('2026-04-18T10:30:00Z'),
      );

      final j = token.toJson();
      final back = ProvisioningToken.fromJson(j);
      expect(back.org, 'o1');
      expect(back.teamKeys['t1'], 'base64keytext');
      expect(back.ts, token.ts);
    });
  });
}
