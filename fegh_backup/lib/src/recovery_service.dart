import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as aes;
import 'package:flutter/foundation.dart';

/// Deutsche Wortliste (128 Eintraege) fuer 12-Wort Recovery-Keys.
///
/// Bewusst nicht die offizielle BIP39-Liste: deutsche Worte sind fuer
/// die Zielgruppe (Admins/Teamleitung) leichter zu lesen und zu
/// notieren.
const _recoveryWords = [
  'Adler', 'Baum', 'Blume', 'Bruecke', 'Dach', 'Erde', 'Falke', 'Garten',
  'Hafen', 'Insel', 'Jagd', 'Krone', 'Lampe', 'Mond', 'Nacht', 'Ozean',
  'Pfad', 'Quelle', 'Regen', 'Stern', 'Turm', 'Ufer', 'Vogel', 'Wald',
  'Anker', 'Berg', 'Dolch', 'Eiche', 'Flamme', 'Gold', 'Herbst', 'Juwel',
  'Kette', 'Licht', 'Mauer', 'Nebel', 'Opal', 'Perle', 'Ring', 'Schild',
  'Tiger', 'Uhr', 'Welle', 'Zeder', 'Amber', 'Birke', 'Donner', 'Ernte',
  'Feder', 'Glut', 'Honig', 'Jade', 'Kliff', 'Lilie', 'Muschel', 'Nordsee',
  'Olive', 'Pinie', 'Rubin', 'Saphir', 'Taube', 'Ulme', 'Weide', 'Zinne',
  'Ahorn', 'Basalt', 'Distel', 'Efeu', 'Fichte', 'Granit', 'Heide', 'Jasmin',
  'Koralle', 'Lavendel', 'Marmor', 'Nelke', 'Orchidee', 'Palme', 'Raute', 'Silber',
  'Tanne', 'Veilchen', 'Wacholder', 'Zitrone', 'Akazie', 'Buche', 'Dahlie', 'Eisvogel',
  'Flieder', 'Ginster', 'Holunder', 'Iris', 'Kastanie', 'Lorbeer', 'Magnolie', 'Narzisse',
  'Oleander', 'Primel', 'Quitte', 'Rose', 'Salbei', 'Thymian', 'Ulmbaum', 'Veilchenblau',
  'Wolfsmilch', 'Ysop', 'Anis', 'Borretsch', 'Dill', 'Estragon', 'Fenchel', 'Glocke',
  'Hasel', 'Immergruen', 'Kamille', 'Linde', 'Minze', 'Nuss', 'Oregano', 'Petersilie',
  'Rosmarin', 'Safran', 'Tulpe', 'Vanille', 'Wermut', 'Zimt', 'Aloe', 'Bambus',
];

/// Service fuer Admin-Recovery (Master-Encryption-Key) und einfache
/// Mitarbeiter-Recovery-Token (z. B. durch Teamleitung).
class RecoveryService {
  RecoveryService._();

  /// Generiert einen 12-Wort Recovery-Key.
  ///
  /// Wird i. d. R. beim Org-Setup erzeugt, einmal angezeigt und vom
  /// Admin an einem sicheren Ort aufbewahrt (z. B. Tresor).
  static String generateRecoveryKey() {
    final random = Random.secure();
    final words = <String>[];
    for (var i = 0; i < 12; i++) {
      words.add(_recoveryWords[random.nextInt(_recoveryWords.length)]);
    }
    return words.join(' ');
  }

  /// Leitet einen 32-Byte Key aus einer Recovery-Phrase ab.
  ///
  /// Nutzt 50 000 Runden HMAC-SHA-256 mit konstantem Salt
  /// (`egh-recovery-key-v1`). Die Iterationszahl ist an
  /// Notebook-Geschwindigkeit kalibriert.
  static Future<Uint8List> deriveKeyFromRecoveryPhrase(String phrase) async {
    final salt = utf8.encode('egh-recovery-key-v1');
    List<int> key = utf8.encode(phrase.trim().toLowerCase());
    for (var i = 0; i < 50000; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  /// Verschluesselt den MEK mit der Recovery-Phrase.
  /// Rueckgabe: Base64-kodierter verschluesselter MEK (inkl. Nonce+Tag).
  static Future<String> encryptMekWithRecoveryKey(
    Uint8List mek,
    String recoveryPhrase,
  ) async {
    final recoveryKey = await deriveKeyFromRecoveryPhrase(recoveryPhrase);
    final cipher = aes.AesGcm.with256bits();
    final nonce = _randomBytes(12);
    final secretKey = aes.SecretKey(recoveryKey);
    final box = await cipher.encrypt(mek, secretKey: secretKey, nonce: nonce);
    final payload = {
      'v': 1,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  /// Entschluesselt einen MEK aus einem [encryptedMekB64] mit der
  /// passenden Recovery-Phrase. Gibt `null` zurueck bei falscher
  /// Phrase oder kaputtem Payload.
  static Future<Uint8List?> decryptMekWithRecoveryKey(
    String encryptedMekB64,
    String recoveryPhrase,
  ) async {
    try {
      final recoveryKey = await deriveKeyFromRecoveryPhrase(recoveryPhrase);
      final payload = jsonDecode(utf8.decode(base64Decode(encryptedMekB64)));
      final cipher = aes.AesGcm.with256bits();
      final secretKey = aes.SecretKey(recoveryKey);
      final box = aes.SecretBox(
        base64Decode(payload['ciphertext']),
        nonce: base64Decode(payload['nonce']),
        mac: aes.Mac(base64Decode(payload['tag'])),
      );
      final clearBytes = await cipher.decrypt(box, secretKey: secretKey);
      return Uint8List.fromList(clearBytes);
    } catch (e) {
      debugPrint('[RECOVERY] decryptMek failed: $e');
      return null;
    }
  }

  /// Generiert einen Recovery-Token (Teamleitung -> Mitarbeiter).
  ///
  /// Einfacher als Provisioning-Token: kein Key-Material, nur ein
  /// kurzes Freigabe-Ticket (Passwort-Reset). PIN ist 6-stellig,
  /// [expiresAt] default 24 h.
  static Future<String> generateRecoveryToken({
    required String employeeId,
    required String pin,
    DateTime? expiresAt,
  }) async {
    final payload = {
      'type': 'egh-recovery-v1',
      'employeeId': employeeId,
      'expiresAt': (expiresAt ?? DateTime.now().add(const Duration(hours: 24)))
          .toIso8601String(),
      'ts': DateTime.now().toIso8601String(),
    };
    final payloadBytes = utf8.encode(jsonEncode(payload));
    final pinKey = await _deriveKeyFromPin(pin);
    final encrypted = await _encryptWithKey(payloadBytes, pinKey);
    return base64Encode(utf8.encode(jsonEncode(encrypted)));
  }

  /// Validiert und entschluesselt einen Recovery-Token.
  /// Gibt `null` bei falscher PIN, abgelaufen oder falschem Type.
  static Future<Map<String, dynamic>?> decryptRecoveryToken(
    String tokenB64,
    String pin,
  ) async {
    try {
      final tokenJson = jsonDecode(utf8.decode(base64Decode(tokenB64)));
      final pinKey = await _deriveKeyFromPin(pin);
      final clearBytes = await _decryptWithKey(tokenJson, pinKey);
      final payload = jsonDecode(utf8.decode(clearBytes));

      if (payload['type'] != 'egh-recovery-v1') return null;
      final expiresAt = DateTime.parse(payload['expiresAt']);
      if (DateTime.now().isAfter(expiresAt)) return null;
      return payload as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[RECOVERY] decryptRecoveryToken failed: $e');
      return null;
    }
  }

  // ── Hilfsfunktionen ────────────────────────────────────────────

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<Uint8List> _deriveKeyFromPin(String pin) async {
    final salt = utf8.encode('egh-recovery-pin-v1');
    List<int> key = utf8.encode(pin);
    for (var i = 0; i < 10000; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  static Future<Map<String, dynamic>> _encryptWithKey(
    List<int> plaintext,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final nonce = _randomBytes(12);
    final secretKey = aes.SecretKey(key);
    final box = await cipher.encrypt(plaintext, secretKey: secretKey, nonce: nonce);
    return {
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
  }

  static Future<Uint8List> _decryptWithKey(
    Map<String, dynamic> record,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final secretKey = aes.SecretKey(key);
    final box = aes.SecretBox(
      base64Decode(record['ciphertext']),
      nonce: base64Decode(record['nonce']),
      mac: aes.Mac(base64Decode(record['tag'])),
    );
    final clearBytes = await cipher.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(clearBytes);
  }
}
