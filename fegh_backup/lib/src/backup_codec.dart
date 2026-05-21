import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as aes;

/// Passwort-basierte AES-256-GCM Ver-/Entschluesselung fuer Backup-Dateien.
///
/// Dateiformat (Bytes):
///
/// ```
/// [ 1 Byte Version (0x01) ]
/// [ 16 Byte Salt          ]
/// [ 12 Byte Nonce         ]
/// [ 16 Byte GCM-MAC       ]
/// [ n Bytes Ciphertext    ]
/// ```
///
/// Das Salt wird zufaellig erzeugt (nicht aus dem Passwort abgeleitet),
/// so dass zwei Backups mit demselben Passwort unterschiedliche Keys
/// produzieren. PBKDF2 (HMAC-SHA-256, 100 000 Runden) leitet den
/// 32-Byte-Key ab.
class BackupCodec {
  BackupCodec._();

  static const int _version = 0x01;
  static const int _saltLen = 16;
  static const int _nonceLen = 12;
  static const int _macLen = 16;
  static const int _pbkdf2Iterations = 100000;

  /// Verschluesselt [plaintextJson] (UTF-8 JSON-String) mit [password].
  static Future<Uint8List> encrypt(String plaintextJson, String password) async {
    final salt = _randomBytes(_saltLen);
    final nonce = _randomBytes(_nonceLen);
    final key = await _deriveKey(password, salt);
    final cipher = aes.AesGcm.with256bits();
    final box = await cipher.encrypt(
      utf8.encode(plaintextJson),
      secretKey: aes.SecretKey(key),
      nonce: nonce,
    );
    final builder = BytesBuilder()
      ..addByte(_version)
      ..add(salt)
      ..add(nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return builder.toBytes();
  }

  /// Entschluesselt Backup-Bytes. Wirft [FormatException] bei
  /// ungueltigem Header und [StateError] bei falschem Passwort.
  static Future<String> decrypt(Uint8List data, String password) async {
    if (data.length < 1 + _saltLen + _nonceLen + _macLen) {
      throw const FormatException('Backup-Datei zu kurz');
    }
    if (data[0] != _version) {
      throw FormatException('Unbekannte Backup-Version: ${data[0]}');
    }
    var offset = 1;
    final salt = data.sublist(offset, offset + _saltLen);
    offset += _saltLen;
    final nonce = data.sublist(offset, offset + _nonceLen);
    offset += _nonceLen;
    final mac = data.sublist(offset, offset + _macLen);
    offset += _macLen;
    final ciphertext = data.sublist(offset);

    final key = await _deriveKey(password, salt);
    final cipher = aes.AesGcm.with256bits();
    try {
      final clear = await cipher.decrypt(
        aes.SecretBox(ciphertext, nonce: nonce, mac: aes.Mac(mac)),
        secretKey: aes.SecretKey(key),
      );
      return utf8.decode(clear);
    } catch (_) {
      throw StateError('Entschluesselung fehlgeschlagen: falsches Passwort?');
    }
  }

  // ── intern ──────────────────────────────────────────────────────

  static Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    List<int> key = utf8.encode(password);
    for (var i = 0; i < _pbkdf2Iterations; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
