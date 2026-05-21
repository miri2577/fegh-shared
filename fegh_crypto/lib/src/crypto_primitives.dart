import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'encrypted_record.dart';

/// Pure AES-256-GCM Primitive fuer das EncryptedRecord-Wire-Format.
///
/// Keine Abhaengigkeit zu SharedPreferences, Secure-Storage, HiDrive oder einer
/// spezifischen MEK-Quelle. Der aufrufende Code liefert den MEK als Bytes.
class FeghCrypto {
  FeghCrypto({Random? random}) : _rng = random ?? Random.secure();

  static final AesGcm _aead = AesGcm.with256bits();
  final Random _rng;

  /// Verschluesselt Klartext und wrappt den zufaelligen DEK unter dem MEK.
  ///
  /// - [plaintext]: Zu verschluesselnde Bytes.
  /// - [mek]: 32 Byte Master-Key (AES-256).
  /// - [aad]: optionale Additional Authenticated Data (JSON-Map). Wird
  ///   canonical als `utf8(json.encode(aad))` gebunden.
  Future<EncryptedRecord> encryptRecord({
    required List<int> plaintext,
    required List<int> mek,
    Map<String, dynamic>? aad,
  }) async {
    _assertMekLen(mek);
    final effectiveAad = aad ?? const <String, dynamic>{};
    final aadBytes = utf8.encode(json.encode(effectiveAad));

    // 1) Random DEK (32 Byte), Random Nonce (12 Byte)
    final dekBytes = _randomBytes(32);
    final dekNonce = _randomBytes(12);
    final dekKey = SecretKey(dekBytes);

    final box = await _aead.encrypt(
      plaintext,
      secretKey: dekKey,
      nonce: dekNonce,
      aad: aadBytes,
    );

    // 2) Wrap DEK mit MEK + konstantem AAD `{"type":"dek"}`
    final mekKey = SecretKey(mek);
    final mekNonce = _randomBytes(12);
    final wrapped = await _aead.encrypt(
      dekBytes,
      secretKey: mekKey,
      nonce: mekNonce,
      aad: kDekWrapAad,
    );

    return EncryptedRecord(
      nonce: base64.encode(dekNonce),
      aad: effectiveAad,
      ciphertext: base64.encode(box.cipherText),
      tag: base64.encode(box.mac.bytes),
      dekWrapped: WrappedDek(
        nonce: base64.encode(mekNonce),
        ciphertext: base64.encode(wrapped.cipherText),
        tag: base64.encode(wrapped.mac.bytes),
      ),
    );
  }

  /// Entschluesselt einen Record mit dem MEK.
  Future<Uint8List> decryptRecord({
    required EncryptedRecord record,
    required List<int> mek,
  }) async {
    _assertMekLen(mek);

    // 1) DEK entpacken
    final dekBytes = await _aead.decrypt(
      SecretBox(
        base64.decode(record.dekWrapped.ciphertext),
        nonce: base64.decode(record.dekWrapped.nonce),
        mac: Mac(base64.decode(record.dekWrapped.tag)),
      ),
      secretKey: SecretKey(mek),
      aad: kDekWrapAad,
    );

    // 2) Daten entschluesseln
    final aadBytes = utf8.encode(json.encode(record.aad));
    final plain = await _aead.decrypt(
      SecretBox(
        base64.decode(record.ciphertext),
        nonce: base64.decode(record.nonce),
        mac: Mac(base64.decode(record.tag)),
      ),
      secretKey: SecretKey(dekBytes),
      aad: aadBytes,
    );
    return Uint8List.fromList(plain);
  }

  // ── Helpers ─────────────────────────────────────────────────────

  Uint8List _randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }

  void _assertMekLen(List<int> mek) {
    if (mek.length != 32) {
      throw ArgumentError('MEK muss 32 Byte lang sein (aktuell ${mek.length})');
    }
  }
}
