import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PKCE Code Verifier + Code Challenge (RFC 7636).
///
/// Der Verifier ist ein zufälliger base64url-kodierter String
/// (43-128 Zeichen); die Challenge ist `base64url(sha256(verifier))`.
class PkcePair {
  final String verifier;
  final String challenge;

  const PkcePair({required this.verifier, required this.challenge});

  /// Erzeugt ein neues Pair. [length] ist die Zeichenanzahl des
  /// Verifiers (43..128, Default 64 — deutlich > Empfehlung).
  factory PkcePair.generate({int length = 64, Random? random}) {
    if (length < 43 || length > 128) {
      throw ArgumentError.value(
          length, 'length', 'Muss zwischen 43 und 128 liegen (RFC 7636).');
    }
    final rng = random ?? Random.secure();
    // RFC 7636: verifier = unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final verifier = List<int>.generate(length, (_) {
      return alphabet.codeUnitAt(rng.nextInt(alphabet.length));
    });
    final verifierStr = String.fromCharCodes(verifier);

    final digest = sha256.convert(utf8.encode(verifierStr)).bytes;
    final challenge = base64Url.encode(digest).replaceAll('=', '');
    return PkcePair(verifier: verifierStr, challenge: challenge);
  }
}

/// Erzeugt einen zufälligen `state`-Wert fuer OAuth (CSRF-Schutz).
String randomState({int bytes = 16, Random? random}) {
  final rng = random ?? Random.secure();
  final b = List<int>.generate(bytes, (_) => rng.nextInt(256));
  return base64Url.encode(b).replaceAll('=', '');
}
