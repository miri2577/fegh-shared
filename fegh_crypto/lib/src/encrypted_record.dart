import 'dart:convert';

/// Typisierte Huelle fuer das EncryptedRecord JSON-Wire-Format.
///
/// Wire-Format (bit-identisch zwischen FEGH-Dokumentation und FEGH-Verwaltung):
/// ```json
/// {
///   "v": 1,
///   "alg": "AES-256-GCM",
///   "nonce": "<base64, 12 Byte>",
///   "aad": { ...beliebige Felder... },
///   "ciphertext": "<base64, nur Chiffretext ohne Tag>",
///   "tag": "<base64, 16 Byte Auth-Tag>",
///   "dekWrapped": {
///     "alg": "AES-256-GCM",
///     "nonce": "<base64, 12 Byte>",
///     "ciphertext": "<base64>",
///     "tag": "<base64, 16 Byte Auth-Tag>"
///   }
/// }
/// ```
///
/// `aad` wird bei En-/Entschluesselung canonical als `utf8(json.encode(aad))`
/// gebunden. `dekWrapped` nutzt konstantes AAD `{"type":"dek"}`.
class EncryptedRecord {
  final int version;
  final String algorithm;
  final String nonce; // Base64, 12 Bytes
  final Map<String, dynamic> aad;
  final String ciphertext; // Base64, ohne Tag
  final String tag; // Base64, 16 Bytes
  final WrappedDek dekWrapped;

  const EncryptedRecord({
    this.version = 1,
    this.algorithm = 'AES-256-GCM',
    required this.nonce,
    required this.aad,
    required this.ciphertext,
    required this.tag,
    required this.dekWrapped,
  });

  Map<String, dynamic> toJson() => {
        'v': version,
        'alg': algorithm,
        'nonce': nonce,
        'aad': aad,
        'ciphertext': ciphertext,
        'tag': tag,
        'dekWrapped': dekWrapped.toJson(),
      };

  String toJsonString() => json.encode(toJson());

  factory EncryptedRecord.fromJson(Map<String, dynamic> m) {
    final dek = m['dekWrapped'];
    if (dek == null) {
      throw const FormatException('EncryptedRecord: dekWrapped fehlt');
    }
    return EncryptedRecord(
      version: (m['v'] as int?) ?? 1,
      algorithm: (m['alg'] as String?) ?? 'AES-256-GCM',
      nonce: m['nonce'] as String,
      aad: Map<String, dynamic>.from(m['aad'] ?? const {}),
      ciphertext: m['ciphertext'] as String,
      tag: m['tag'] as String,
      dekWrapped: WrappedDek.fromJson(Map<String, dynamic>.from(dek)),
    );
  }

  factory EncryptedRecord.fromJsonString(String s) =>
      EncryptedRecord.fromJson(json.decode(s) as Map<String, dynamic>);
}

/// Unter dem MEK verschluesselter DEK.
/// Gebunden mit festem AAD `{"type":"dek"}` (canonical encoded).
class WrappedDek {
  final String algorithm;
  final String nonce; // Base64, 12 Bytes
  final String ciphertext; // Base64, 32 Bytes DEK verschluesselt
  final String tag; // Base64, 16 Bytes Auth-Tag

  const WrappedDek({
    this.algorithm = 'AES-256-GCM',
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'alg': algorithm,
        'nonce': nonce,
        'ciphertext': ciphertext,
        'tag': tag,
      };

  factory WrappedDek.fromJson(Map<String, dynamic> m) => WrappedDek(
        algorithm: (m['alg'] as String?) ?? 'AES-256-GCM',
        nonce: m['nonce'] as String,
        ciphertext: m['ciphertext'] as String,
        tag: m['tag'] as String,
      );
}

/// Konstanter AAD fuer DEK-Wrapping. Muss identisch zwischen beiden Apps sein.
final List<int> kDekWrapAad = utf8.encode('{"type":"dek"}');
