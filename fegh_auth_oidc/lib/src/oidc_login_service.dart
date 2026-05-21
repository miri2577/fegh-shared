import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'oidc_config.dart';
import 'oidc_tokens.dart';
import 'pkce.dart';

/// OIDC-Login via Authorization Code Flow + PKCE + RFC 8252 Loopback-
/// Redirect (Desktop-Apps ohne Custom URL Schemes).
///
/// Ablauf von [login]:
/// 1. Lade Discovery-Dokument vom Issuer.
/// 2. Starte einen HTTP-Server auf `127.0.0.1:<freier Port>`.
/// 3. Oeffne den System-Browser mit Authorization-URL
///    (`redirect_uri=http://127.0.0.1:PORT/callback`).
/// 4. User logt sich ein, IdP redirected auf die Callback-URL.
/// 5. Server nimmt `code` + `state` entgegen, zeigt Success-Seite,
///    schliesst sich.
/// 6. Tausche `code` + Verifier gegen Tokens ueber den Token-Endpoint.
/// 7. Persistiere Tokens im sicheren Geraetespeicher.
///
/// Timeout-Default 5 Minuten — danach wird der Login abgebrochen.
class OidcLoginService {
  static const _storageKeyPrefix = 'fegh_oidc_';
  static const Duration _defaultTimeout = Duration(minutes: 5);

  final http.Client _http;
  final FlutterSecureStorage _storage;

  OidcLoginService({
    http.Client? httpClient,
    FlutterSecureStorage? storage,
  })  : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  // ── Discovery ──────────────────────────────────────────────────

  Future<OidcDiscovery> discover(String issuerUrl) async {
    final url = '${issuerUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/.well-known/openid-configuration';
    final res = await _http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw OidcException(
          'Discovery fehlgeschlagen ($url): HTTP ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return OidcDiscovery.fromJson(json);
  }

  // ── Login ──────────────────────────────────────────────────────

  /// Fuehrt den kompletten Login durch und gibt Tokens + User zurueck.
  Future<OidcLoginResult> login(
    OidcConfig config, {
    Duration timeout = _defaultTimeout,
    String redirectPath = '/callback',
  }) async {
    final disco = await discover(config.issuerUrl);
    final pkce = PkcePair.generate();
    final state = randomState();

    // Loopback-Server starten (RFC 8252).
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}$redirectPath';

    try {
      // Browser oeffnen.
      final authUrl = _buildAuthUrl(
        endpoint: disco.authorizationEndpoint,
        config: config,
        redirectUri: redirectUri,
        codeChallenge: pkce.challenge,
        state: state,
      );
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw OidcException('Konnte System-Browser nicht oeffnen');
      }

      // Auf Callback warten.
      final callback = await _awaitCallback(
        server,
        expectedState: state,
        redirectPath: redirectPath,
      ).timeout(
        timeout,
        onTimeout: () =>
            throw OidcException('Login-Timeout nach $timeout abgelaufen'),
      );

      // Code gegen Tokens tauschen.
      final tokens = await _exchangeCode(
        tokenEndpoint: disco.tokenEndpoint,
        clientId: config.clientId,
        code: callback.code,
        codeVerifier: pkce.verifier,
        redirectUri: redirectUri,
      );
      final user = OidcUser.fromIdToken(tokens.idToken);

      await _persistTokens(config.issuerUrl, tokens);
      return OidcLoginResult(tokens: tokens, user: user);
    } finally {
      await server.close(force: true);
    }
  }

  String _buildAuthUrl({
    required String endpoint,
    required OidcConfig config,
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) {
    final params = <String, String>{
      'response_type': 'code',
      'client_id': config.clientId,
      'redirect_uri': redirectUri,
      'scope': config.scopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
      ...config.extraAuthParams,
    };
    final sep = endpoint.contains('?') ? '&' : '?';
    final query = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}='
            '${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$endpoint$sep$query';
  }

  Future<_CallbackResult> _awaitCallback(
    HttpServer server, {
    required String expectedState,
    required String redirectPath,
  }) async {
    await for (final req in server) {
      if (req.uri.path != redirectPath) {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await req.response.close();
        continue;
      }
      final code = req.uri.queryParameters['code'];
      final state = req.uri.queryParameters['state'];
      final error = req.uri.queryParameters['error'];

      req.response.headers.contentType = ContentType.html;
      if (error != null) {
        req.response
          ..statusCode = 400
          ..write(_resultHtml(
            title: 'Login fehlgeschlagen',
            message: 'Der Identity-Provider meldet: $error',
            success: false,
          ));
        await req.response.close();
        throw OidcException('IdP-Fehler: $error');
      }
      if (code == null || state == null) {
        req.response
          ..statusCode = 400
          ..write(_resultHtml(
            title: 'Login fehlgeschlagen',
            message: 'Antwort ohne code/state.',
            success: false,
          ));
        await req.response.close();
        throw OidcException('Callback ohne code/state');
      }
      if (state != expectedState) {
        req.response
          ..statusCode = 400
          ..write(_resultHtml(
            title: 'Login abgebrochen',
            message: 'State passt nicht — moeglicher CSRF-Versuch.',
            success: false,
          ));
        await req.response.close();
        throw OidcException('State-Mismatch');
      }
      req.response.write(_resultHtml(
        title: 'Login erfolgreich',
        message: 'Dieses Fenster kann geschlossen werden.',
        success: true,
      ));
      await req.response.close();
      return _CallbackResult(code: code, state: state);
    }
    throw OidcException('Callback-Server wurde geschlossen, bevor ein '
        'Callback eingetroffen ist.');
  }

  Future<OidcTokens> _exchangeCode({
    required String tokenEndpoint,
    required String clientId,
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final res = await _http.post(
      Uri.parse(tokenEndpoint),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
    );
    if (res.statusCode != 200) {
      throw OidcException(
          'Token-Exchange fehlgeschlagen: HTTP ${res.statusCode} '
          '— ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return OidcTokens.fromTokenResponse(json);
  }

  // ── Refresh ────────────────────────────────────────────────────

  Future<OidcTokens?> refresh(OidcConfig config) async {
    final current = await loadTokens(config.issuerUrl);
    if (current?.refreshToken == null) return null;
    final disco = await discover(config.issuerUrl);
    final res = await _http.post(
      Uri.parse(disco.tokenEndpoint),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': current!.refreshToken!,
        'client_id': config.clientId,
      },
    );
    if (res.statusCode != 200) {
      return null;
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final newTokens = OidcTokens.fromTokenResponse(json);
    await _persistTokens(config.issuerUrl, newTokens);
    return newTokens;
  }

  // ── Storage ────────────────────────────────────────────────────

  String _storageKey(String issuerUrl) =>
      '$_storageKeyPrefix${Uri.encodeQueryComponent(issuerUrl)}';

  Future<void> _persistTokens(String issuerUrl, OidcTokens tokens) async {
    await _storage.write(
      key: _storageKey(issuerUrl),
      value: jsonEncode(tokens.toJson()),
    );
  }

  Future<OidcTokens?> loadTokens(String issuerUrl) async {
    final raw = await _storage.read(key: _storageKey(issuerUrl));
    if (raw == null || raw.isEmpty) return null;
    return OidcTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> logout(String issuerUrl) async {
    await _storage.delete(key: _storageKey(issuerUrl));
  }

  // ── UI-Helper ──────────────────────────────────────────────────

  String _resultHtml({
    required String title,
    required String message,
    required bool success,
  }) {
    final color = success ? '#2e7d32' : '#c62828';
    return '''<!DOCTYPE html>
<html lang="de"><head>
<meta charset="utf-8">
<title>$title</title>
<style>
  body{font-family:system-ui,Arial,sans-serif;margin:0;padding:0;display:flex;
       align-items:center;justify-content:center;height:100vh;background:#f5f5f7}
  .card{max-width:480px;padding:32px;background:#fff;border-radius:12px;
        box-shadow:0 4px 20px rgba(0,0,0,0.08);text-align:center}
  h1{color:$color;margin:0 0 12px 0;font-size:22px}
  p{color:#555;margin:0;font-size:15px}
</style></head><body>
<div class="card"><h1>$title</h1><p>$message</p></div>
</body></html>''';
  }
}

/// Ergebnis eines erfolgreichen Logins.
class OidcLoginResult {
  final OidcTokens tokens;
  final OidcUser user;
  const OidcLoginResult({required this.tokens, required this.user});
}

class OidcException implements Exception {
  final String message;
  OidcException(this.message);
  @override
  String toString() => 'OidcException: $message';
}

class _CallbackResult {
  final String code;
  final String state;
  _CallbackResult({required this.code, required this.state});
}
