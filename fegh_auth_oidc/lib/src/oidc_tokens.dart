import 'dart:convert';

/// Tokens, die nach erfolgreichem OIDC-Login vorliegen.
class OidcTokens {
  final String accessToken;
  final String idToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? tokenType;
  final List<String> scopes;

  const OidcTokens({
    required this.accessToken,
    required this.idToken,
    this.refreshToken,
    required this.expiresAt,
    this.tokenType,
    this.scopes = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 1 Minute Puffer — wenn der Token "gerade noch" gilt, lieber jetzt
  /// refreshen, nicht waehrend eines Requests ablaufen.
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(minutes: 1)).isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'id_token': idToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
        if (tokenType != null) 'token_type': tokenType,
        'scopes': scopes,
      };

  factory OidcTokens.fromJson(Map<String, dynamic> json) => OidcTokens(
        accessToken: json['access_token'] as String,
        idToken: json['id_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        tokenType: json['token_type'] as String?,
        scopes: ((json['scopes'] as List?) ?? const []).cast<String>(),
      );

  /// Baut das Objekt aus der Token-Response eines Providers.
  factory OidcTokens.fromTokenResponse(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final scope = json['scope'] as String? ?? '';
    return OidcTokens(
      accessToken: json['access_token'] as String,
      idToken: (json['id_token'] as String?) ?? '',
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      tokenType: json['token_type'] as String?,
      scopes: scope.isEmpty ? const [] : scope.split(' '),
    );
  }
}

/// Der authentifizierte Benutzer aus dem ID-Token.
///
/// Quelle: OIDC-Claims (`sub`, `email`, `name`, `preferred_username`).
class OidcUser {
  final String subject;
  final String? email;
  final String? name;
  final String? preferredUsername;
  final Map<String, dynamic> allClaims;

  const OidcUser({
    required this.subject,
    this.email,
    this.name,
    this.preferredUsername,
    this.allClaims = const {},
  });

  /// Mapped auf die interne FEGH-`userId`: bevorzugt Email, fallback
  /// auf preferred_username, dann subject.
  String get feghUserId =>
      (email ?? preferredUsername ?? subject).toLowerCase();

  /// Parst den ID-Token-JWT und extrahiert die Claims.
  ///
  /// Achtung: Diese Methode **validiert die Signatur NICHT**. Wer
  /// dem ID-Token vertrauen will, muss ihn gegen die `jwks_uri`
  /// des Issuers pruefen (siehe `jose`-Package). Fuer die meisten
  /// Desktop-Flows reicht es, dass der Token ueber TLS vom Token-
  /// Endpoint kam.
  factory OidcUser.fromIdToken(String idToken) {
    final parts = idToken.split('.');
    if (parts.length < 2) {
      throw FormatException('ID-Token hat nicht das JWT-Format');
    }
    final payload = parts[1];
    final padded = payload.padRight((payload.length + 3) & ~3, '=');
    final decoded = utf8.decode(base64Url.decode(padded));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    return OidcUser(
      subject: claims['sub'] as String,
      email: claims['email'] as String?,
      name: claims['name'] as String?,
      preferredUsername: claims['preferred_username'] as String?,
      allClaims: claims,
    );
  }
}
