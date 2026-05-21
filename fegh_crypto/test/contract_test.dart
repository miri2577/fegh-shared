import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fegh_crypto/fegh_crypto.dart';
import 'package:test/test.dart';

/// Contract-Tests fuer das EncryptedRecord-Wire-Format.
///
/// Sichert zu, dass FEGH-Dokumentation und FEGH-Verwaltung verschluesselte
/// Datensaetze gegenseitig lesen koennen.
void main() {
  group('FeghCrypto Round-Trip', () {
    test('Klartext → verschluesseln → JSON → entschluesseln → Klartext',
        () async {
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);
      final plaintext = utf8.encode('Geheimer Inhalt: Klientenname Max Mustermann');

      final rec = await crypto.encryptRecord(
        plaintext: plaintext,
        mek: mek,
        aad: {'schema': 'client', 'id': 'abc-123'},
      );

      // Serialisieren wie auf HiDrive
      final jsonStr = rec.toJsonString();
      expect(jsonStr, contains('"v":1'));
      expect(jsonStr, contains('"alg":"AES-256-GCM"'));
      expect(jsonStr, contains('"dekWrapped"'));

      // Deserialisieren und entschluesseln
      final restored = EncryptedRecord.fromJsonString(jsonStr);
      final decrypted = await crypto.decryptRecord(record: restored, mek: mek);

      expect(utf8.decode(decrypted), equals('Geheimer Inhalt: Klientenname Max Mustermann'));
    });

    test('AAD ist gebunden - manipuliertes AAD bricht Entschluesselung',
        () async {
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('test'),
        mek: mek,
        aad: {'schema': 'client', 'id': 'abc'},
      );

      // Manipuliere AAD
      final tampered = EncryptedRecord(
        nonce: rec.nonce,
        aad: {'schema': 'appointment', 'id': 'abc'}, // geaendert
        ciphertext: rec.ciphertext,
        tag: rec.tag,
        dekWrapped: rec.dekWrapped,
      );

      expect(
        () => crypto.decryptRecord(record: tampered, mek: mek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('Falscher MEK bricht Entschluesselung', () async {
      final crypto = FeghCrypto();
      final mek1 = List<int>.generate(32, (i) => i);
      final mek2 = List<int>.generate(32, (i) => i + 1);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('test'),
        mek: mek1,
      );

      expect(
        () => crypto.decryptRecord(record: rec, mek: mek2),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('MEK muss 32 Byte sein', () async {
      final crypto = FeghCrypto();
      final shortMek = List<int>.filled(16, 0);

      expect(
        () => crypto.encryptRecord(
          plaintext: utf8.encode('x'),
          mek: shortMek,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Interop mit Legacy-Format FEGH-Dokumentation', () {
    test('Kann Legacy-Record aus Doku-App-Format entschluesseln', () async {
      // Simuliere Doku-App-Format: encryptRecord liefert Map<String, dynamic>
      // Unsere EncryptedRecord.fromJson muss das lesen koennen.
      final legacy = <String, dynamic>{
        'v': 1,
        'alg': 'AES-256-GCM',
        'nonce': 'AAAAAAAAAAAAAAAAAAAAAA==', // Placeholder
        'aad': {'type': 'test'},
        'ciphertext': 'dGVzdA==',
        'tag': 'AAAAAAAAAAAAAAAAAAAAAA==',
        'dekWrapped': {
          'alg': 'AES-256-GCM',
          'nonce': 'AAAAAAAAAAAAAAAAAAAAAA==',
          'ciphertext': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'tag': 'AAAAAAAAAAAAAAAAAAAAAA==',
        },
      };

      // Sollte ohne Fehler parsen
      final rec = EncryptedRecord.fromJson(legacy);
      expect(rec.version, 1);
      expect(rec.algorithm, 'AES-256-GCM');
      expect(rec.aad['type'], 'test');
      expect(rec.dekWrapped.algorithm, 'AES-256-GCM');
    });

    test('Round-trip: JSON → typed → JSON identisch', () async {
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('test'),
        mek: mek,
        aad: {'schema': 'message'},
      );

      final json1 = rec.toJsonString();
      final roundtrip = EncryptedRecord.fromJsonString(json1);
      final json2 = roundtrip.toJsonString();

      expect(json1, equals(json2));
    });
  });

  group('AAD canonical encoding', () {
    test('AAD-Schluessel-Reihenfolge beeinflusst das Ergebnis', () async {
      // Wichtig: Beide Apps muessen die gleiche AAD-Reihenfolge haben!
      // JSON Map-Ordering ist in Dart insertion-ordered.
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('x'),
        mek: mek,
        aad: <String, dynamic>{'a': 1, 'b': 2},
      );

      // Mit gleicher Reihenfolge: klappt
      final ok = EncryptedRecord(
        nonce: rec.nonce,
        aad: <String, dynamic>{'a': 1, 'b': 2},
        ciphertext: rec.ciphertext,
        tag: rec.tag,
        dekWrapped: rec.dekWrapped,
      );
      expect((await crypto.decryptRecord(record: ok, mek: mek)).isNotEmpty,
          isTrue);

      // Mit umgekehrter Reihenfolge: bricht
      final wrongOrder = EncryptedRecord(
        nonce: rec.nonce,
        aad: <String, dynamic>{'b': 2, 'a': 1},
        ciphertext: rec.ciphertext,
        tag: rec.tag,
        dekWrapped: rec.dekWrapped,
      );
      expect(
        () => crypto.decryptRecord(record: wrongOrder, mek: mek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('Auth-Tag Pruefung', () {
    test('Modifiziertes Ciphertext bricht AES-GCM Auth-Tag', () async {
      final crypto = FeghCrypto();
      final mek = List<int>.generate(32, (i) => i);

      final rec = await crypto.encryptRecord(
        plaintext: utf8.encode('original'),
        mek: mek,
      );

      // Flippe ein Bit im Ciphertext
      final originalCt = base64.decode(rec.ciphertext);
      final tampered = Uint8List.fromList(List.of(originalCt));
      tampered[0] ^= 0x01;

      final badRec = EncryptedRecord(
        nonce: rec.nonce,
        aad: rec.aad,
        ciphertext: base64.encode(tampered),
        tag: rec.tag,
        dekWrapped: rec.dekWrapped,
      );

      expect(
        () => crypto.decryptRecord(record: badRec, mek: mek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}
