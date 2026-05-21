import 'dart:typed_data';

import 'package:fegh_backup/fegh_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupCodec', () {
    test('roundtrip: encrypt then decrypt returns original payload', () async {
      const payload = '{"clients":[{"id":"c1","name":"Alice"}],"n":42}';
      const password = 'correcthorsebatterystaple';

      final bytes = await BackupCodec.encrypt(payload, password);
      final decoded = await BackupCodec.decrypt(bytes, password);

      expect(decoded, payload);
    });

    test('wrong password throws StateError', () async {
      final bytes = await BackupCodec.encrypt('{"x":1}', 'good-password');
      expect(
        () => BackupCodec.decrypt(bytes, 'wrong-password'),
        throwsA(isA<StateError>()),
      );
    });

    test('tampered ciphertext throws StateError', () async {
      final bytes = await BackupCodec.encrypt('{"x":1}', 'pw');
      bytes[bytes.length - 1] ^= 0xFF;
      expect(
        () => BackupCodec.decrypt(bytes, 'pw'),
        throwsA(isA<StateError>()),
      );
    });

    test('truncated header throws FormatException', () async {
      expect(
        () => BackupCodec.decrypt(Uint8List.fromList([0x01, 0x02, 0x03]), 'pw'),
        throwsFormatException,
      );
    });

    test('unknown version byte throws FormatException', () async {
      final bytes = Uint8List(1 + 16 + 12 + 16 + 4);
      bytes[0] = 0xFF;
      expect(
        () => BackupCodec.decrypt(bytes, 'pw'),
        throwsFormatException,
      );
    });

    test('two encryptions with same password produce different ciphertext', () async {
      const pw = 'same-password';
      final a = await BackupCodec.encrypt('{"x":1}', pw);
      final b = await BackupCodec.encrypt('{"x":1}', pw);
      // Salt + Nonce sind zufaellig, also darf der gesamte Output
      // identisch niemals sein.
      expect(a, isNot(equals(b)));
    });
  });

  group('BackupEnvelope', () {
    test('toJson/fromJson roundtrip preserves metadata and payload', () {
      final env = BackupEnvelope(
        metadata: BackupMetadata.create(
          deviceName: 'Test',
          appVersion: '1.0.0',
          dataVersion: '2.1.0',
        ),
        payload: {
          'clients': [
            {'id': 'c1', 'name': 'Alice'}
          ],
          'count': 42,
        },
      );
      final encoded = env.encodeJson();
      final decoded = BackupEnvelope.decodeJson(encoded);

      expect(decoded.metadata.deviceName, 'Test');
      expect(decoded.metadata.appVersion, '1.0.0');
      expect(decoded.payload['count'], 42);
      expect((decoded.payload['clients'] as List).first['name'], 'Alice');
    });

    test('BackupInfo formats bytes correctly', () {
      final info = BackupInfo(
        id: '1',
        filename: 'x',
        createdAt: DateTime.now(),
        deviceName: 'x',
        isEncrypted: true,
        fileSizeBytes: 2048,
      );
      expect(info.formattedFileSize, '2.0 KB');
    });
  });

  group('RecoveryService', () {
    test('generateRecoveryKey returns 12 space-separated words', () {
      final key = RecoveryService.generateRecoveryKey();
      expect(key.split(' ').length, 12);
    });

    test('two consecutive keys differ (entropy)', () {
      final a = RecoveryService.generateRecoveryKey();
      final b = RecoveryService.generateRecoveryKey();
      expect(a, isNot(equals(b)));
    });

    test('MEK roundtrip with recovery phrase', () async {
      final phrase = RecoveryService.generateRecoveryKey();
      final mek = Uint8List.fromList(List<int>.generate(32, (i) => i));

      final enc = await RecoveryService.encryptMekWithRecoveryKey(mek, phrase);
      final dec = await RecoveryService.decryptMekWithRecoveryKey(enc, phrase);

      expect(dec, isNotNull);
      expect(dec!.length, 32);
      expect(dec, mek);
    });

    test('MEK roundtrip fails with wrong phrase', () async {
      final phrase = RecoveryService.generateRecoveryKey();
      final otherPhrase = RecoveryService.generateRecoveryKey();
      final mek = Uint8List.fromList(List<int>.generate(32, (i) => i));

      final enc = await RecoveryService.encryptMekWithRecoveryKey(mek, phrase);
      final dec =
          await RecoveryService.decryptMekWithRecoveryKey(enc, otherPhrase);

      expect(dec, isNull);
    });

    test('recovery token roundtrip within expiry', () async {
      final token = await RecoveryService.generateRecoveryToken(
        employeeId: 'emp-42',
        pin: '123456',
      );
      final decoded =
          await RecoveryService.decryptRecoveryToken(token, '123456');

      expect(decoded, isNotNull);
      expect(decoded!['employeeId'], 'emp-42');
      expect(decoded['type'], 'egh-recovery-v1');
    });

    test('expired recovery token returns null', () async {
      final token = await RecoveryService.generateRecoveryToken(
        employeeId: 'emp-99',
        pin: '000000',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final decoded =
          await RecoveryService.decryptRecoveryToken(token, '000000');

      expect(decoded, isNull);
    });

    test('wrong PIN returns null', () async {
      final token = await RecoveryService.generateRecoveryToken(
        employeeId: 'emp-1',
        pin: '111111',
      );
      final decoded =
          await RecoveryService.decryptRecoveryToken(token, '222222');

      expect(decoded, isNull);
    });
  });
}
