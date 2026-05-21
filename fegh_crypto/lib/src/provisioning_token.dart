import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as aes;
import 'package:crypto/crypto.dart' as hash;

/// Typisierte Huelle fuer das Provisioning-Token (QR-Code zwischen
/// FEGH-Verwaltung und FEGH-Dokumentation).
///
/// Klartext-Payload:
/// ```json
/// {
///   "type": "egh-provisioning-v1",
///   "org": "<orgId>",
///   "user": "<email>",
///   "role": "team_member|team_lead|pv_admin|org_admin|org_auditor",
///   "teams": ["team-a", ...],
///   "teamKeys": { "team-a": "<base64-32byte>", ... },
///   "totp": "<base32 secret, optional>",
///   "hidrive": { "username": "...", "appPassword": "..." },
///   "flags": { "managed": true, "forceInitialSync": true, "hideCredentials": true },
///   "ts": "<ISO-8601>"
/// }
/// ```
///
/// Wird PIN-verschluesselt (PBKDF2 10000 Iter. mit Salt
/// `egh-provisioning-salt-v1`, AES-256-GCM, kein AAD) und als
/// Base64-String in den QR-Code geschrieben.
class ProvisioningToken {
  static const String kType = 'egh-provisioning-v1';
  static const String kSalt = 'egh-provisioning-salt-v1';
  static const int kPbkdf2Iterations = 10000;

  final String type;
  final String org;
  final String user;
  final String role;
  final List<String> teams;
  final Map<String, String> teamKeys; // teamId → base64 key
  final String? totp; // base32 secret
  final HidriveCredentials? hidrive;
  final Map<String, dynamic> flags;
  final DateTime ts;

  const ProvisioningToken({
    this.type = kType,
    required this.org,
    required this.user,
    required this.role,
    required this.teams,
    this.teamKeys = const {},
    this.totp,
    this.hidrive,
    this.flags = const {},
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'org': org,
        'user': user,
        'role': role,
        'teams': teams,
        'teamKeys': teamKeys,
        if (totp != null) 'totp': totp,
        if (hidrive != null) 'hidrive': hidrive!.toJson(),
        'flags': flags,
        'ts': ts.toIso8601String(),
      };

  factory ProvisioningToken.fromJson(Map<String, dynamic> m) {
    return ProvisioningToken(
      type: (m['type'] as String?) ?? kType,
      org: m['org'] as String,
      user: m['user'] as String,
      role: m['role'] as String,
      teams: List<String>.from(m['teams'] ?? const <String>[]),
      teamKeys: Map<String, String>.from(m['teamKeys'] ?? const {}),
      totp: m['totp'] as String?,
      hidrive: m['hidrive'] == null
          ? null
          : HidriveCredentials.fromJson(Map<String, dynamic>.from(m['hidrive'])),
      flags: Map<String, dynamic>.from(m['flags'] ?? const {}),
      ts: DateTime.parse(m['ts'] as String),
    );
  }

  /// Verschluesselt Payload mit PIN und liefert Base64-String fuer QR-Code.
  Future<String> encryptWithPin(String pin, {Random? random}) async {
    final payload = utf8.encode(json.encode(toJson()));
    final key = await _deriveKeyFromPin(pin);
    final cipher = aes.AesGcm.with256bits();
    final nonce = _randomBytes(12, random);
    final box = await cipher.encrypt(
      payload,
      secretKey: aes.SecretKey(key),
      nonce: nonce,
    );
    final envelope = {
      'nonce': base64.encode(nonce),
      'ciphertext': base64.encode(box.cipherText),
      'tag': base64.encode(box.mac.bytes),
    };
    return base64.encode(utf8.encode(json.encode(envelope)));
  }

  /// Entschluesselt ein PIN-geschuetztes Token.
  static Future<ProvisioningToken?> decryptWithPin(
    String tokenBase64,
    String pin,
  ) async {
    try {
      final envelope = json.decode(utf8.decode(base64.decode(tokenBase64)))
          as Map<String, dynamic>;
      final key = await _deriveKeyFromPin(pin);
      final cipher = aes.AesGcm.with256bits();
      final plaintext = await cipher.decrypt(
        aes.SecretBox(
          base64.decode(envelope['ciphertext']),
          nonce: base64.decode(envelope['nonce']),
          mac: aes.Mac(base64.decode(envelope['tag'])),
        ),
        secretKey: aes.SecretKey(key),
      );
      final json0 = json.decode(utf8.decode(plaintext)) as Map<String, dynamic>;
      if (json0['type'] != kType) return null;
      return ProvisioningToken.fromJson(json0);
    } catch (_) {
      return null;
    }
  }

  /// PBKDF2-artige Key-Ableitung (HMAC-SHA256-Iterationen).
  /// Bit-identisch zwischen FEGH-Dokumentation und FEGH-Verwaltung.
  static Future<Uint8List> _deriveKeyFromPin(String pin) async {
    final salt = utf8.encode(kSalt);
    List<int> key = utf8.encode(pin);
    for (var i = 0; i < kPbkdf2Iterations; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  static Uint8List _randomBytes(int n, Random? rng) {
    final r = rng ?? Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = r.nextInt(256);
    }
    return out;
  }
}

/// HiDrive-Credentials im Provisioning-Token.
class HidriveCredentials {
  final String username;
  final String? appPassword;

  const HidriveCredentials({required this.username, this.appPassword});

  Map<String, dynamic> toJson() => {
        'username': username,
        if (appPassword != null) 'appPassword': appPassword,
      };

  factory HidriveCredentials.fromJson(Map<String, dynamic> m) =>
      HidriveCredentials(
        username: m['username'] as String,
        appPassword: m['appPassword'] as String?,
      );
}
