import 'dart:convert';

import 'package:fegh_auth_oidc/fegh_auth_oidc.dart';
import 'package:flutter_test/flutter_test.dart';

String _buildJwt(Map<String, dynamic> claims) {
  final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'))
      .replaceAll('=', '');
  final payload =
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return '$header.$payload.nosignature';
}

void main() {
  group('OidcTokens', () {
    test('fromTokenResponse setzt expiresAt und scopes', () {
      final t = OidcTokens.fromTokenResponse({
        'access_token': 'at',
        'id_token': 'idt',
        'refresh_token': 'rt',
        'expires_in': 3600,
        'token_type': 'Bearer',
        'scope': 'openid email profile',
      });
      expect(t.accessToken, 'at');
      expect(t.refreshToken, 'rt');
      expect(t.scopes, ['openid', 'email', 'profile']);
      final delta =
          t.expiresAt.difference(DateTime.now()).inSeconds;
      expect(delta, inInclusiveRange(3595, 3605));
    });

    test('isExpired und isExpiringSoon', () {
      final past = OidcTokens(
        accessToken: 'a',
        idToken: 'i',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(past.isExpired, isTrue);
      expect(past.isExpiringSoon, isTrue);

      final soon = OidcTokens(
        accessToken: 'a',
        idToken: 'i',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );
      expect(soon.isExpired, isFalse);
      expect(soon.isExpiringSoon, isTrue);

      final later = OidcTokens(
        accessToken: 'a',
        idToken: 'i',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );
      expect(later.isExpired, isFalse);
      expect(later.isExpiringSoon, isFalse);
    });

    test('JSON-Roundtrip', () {
      final original = OidcTokens(
        accessToken: 'at',
        idToken: 'idt',
        refreshToken: 'rt',
        expiresAt: DateTime.utc(2026, 4, 19, 21, 0),
        tokenType: 'Bearer',
        scopes: const ['openid', 'email'],
      );
      final back = OidcTokens.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(back.accessToken, 'at');
      expect(back.scopes, ['openid', 'email']);
      expect(back.expiresAt, original.expiresAt);
    });
  });

  group('OidcUser.fromIdToken', () {
    test('extrahiert sub, email, name, preferred_username', () {
      final jwt = _buildJwt({
        'sub': 'abc-123',
        'email': 'alice@fegh.local',
        'name': 'Alice Mueller',
        'preferred_username': 'alice',
      });
      final user = OidcUser.fromIdToken(jwt);
      expect(user.subject, 'abc-123');
      expect(user.email, 'alice@fegh.local');
      expect(user.name, 'Alice Mueller');
      expect(user.preferredUsername, 'alice');
    });

    test('feghUserId bevorzugt Email, sonst username, sonst sub', () {
      expect(
        OidcUser.fromIdToken(_buildJwt({
          'sub': 'x',
          'email': 'Alice@Fegh.Local',
          'preferred_username': 'alice',
        })).feghUserId,
        'alice@fegh.local',
      );
      expect(
        OidcUser.fromIdToken(_buildJwt({
          'sub': 'x',
          'preferred_username': 'bob',
        })).feghUserId,
        'bob',
      );
      expect(
        OidcUser.fromIdToken(_buildJwt({'sub': 'only-sub'})).feghUserId,
        'only-sub',
      );
    });

    test('wirft bei unvollstaendigem JWT', () {
      expect(() => OidcUser.fromIdToken('not-a-jwt'),
          throwsA(isA<FormatException>()));
    });
  });
}
