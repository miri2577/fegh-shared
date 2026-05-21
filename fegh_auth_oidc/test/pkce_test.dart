import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fegh_auth_oidc/fegh_auth_oidc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PkcePair', () {
    test('Verifier hat erlaubte Laenge (RFC 7636)', () {
      final p = PkcePair.generate();
      expect(p.verifier.length, inInclusiveRange(43, 128));
    });

    test('Verifier nutzt nur RFC-7636-Zeichen', () {
      final p = PkcePair.generate(length: 128);
      expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(p.verifier), isTrue);
    });

    test('Challenge = base64url(sha256(verifier)) ohne Padding', () {
      final p = PkcePair.generate();
      final expected = base64Url
          .encode(sha256.convert(utf8.encode(p.verifier)).bytes)
          .replaceAll('=', '');
      expect(p.challenge, expected);
    });

    test('generate() lehnt ungueltige Laengen ab', () {
      expect(() => PkcePair.generate(length: 42), throwsArgumentError);
      expect(() => PkcePair.generate(length: 129), throwsArgumentError);
    });

    test('zwei Paare sind unterschiedlich (randomness)', () {
      final a = PkcePair.generate();
      final b = PkcePair.generate();
      expect(a.verifier, isNot(b.verifier));
      expect(a.challenge, isNot(b.challenge));
    });
  });

  group('randomState', () {
    test('erzeugt base64url-kompatible Strings ohne Padding', () {
      final s = randomState();
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(s), isTrue);
      expect(s.contains('='), isFalse);
    });

    test('ist bei mehreren Aufrufen unterschiedlich', () {
      expect(randomState(), isNot(randomState()));
    });
  });
}
