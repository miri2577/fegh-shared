/// Konfiguration eines OIDC-Providers fuer eine FEGH-Organisation.
///
/// Beispiele fuer [issuerUrl]:
/// - Entra ID:   `https://login.microsoftonline.com/<tenant>/v2.0`
/// - Keycloak:   `https://auth.example.de/realms/fegh`
/// - Google:     `https://accounts.google.com`
class OidcConfig {
  final String issuerUrl;
  final String clientId;

  /// OAuth-Scopes. Default: `openid`, `profile`, `email`.
  final List<String> scopes;

  /// Zusaetzliche Authorization-Parameter (z. B. `prompt=login`).
  final Map<String, String> extraAuthParams;

  const OidcConfig({
    required this.issuerUrl,
    required this.clientId,
    this.scopes = const ['openid', 'profile', 'email'],
    this.extraAuthParams = const {},
  });

  OidcConfig copyWith({
    String? issuerUrl,
    String? clientId,
    List<String>? scopes,
    Map<String, String>? extraAuthParams,
  }) {
    return OidcConfig(
      issuerUrl: issuerUrl ?? this.issuerUrl,
      clientId: clientId ?? this.clientId,
      scopes: scopes ?? this.scopes,
      extraAuthParams: extraAuthParams ?? this.extraAuthParams,
    );
  }

  Map<String, dynamic> toJson() => {
        'issuerUrl': issuerUrl,
        'clientId': clientId,
        'scopes': scopes,
        'extraAuthParams': extraAuthParams,
      };

  factory OidcConfig.fromJson(Map<String, dynamic> json) => OidcConfig(
        issuerUrl: json['issuerUrl'] as String,
        clientId: json['clientId'] as String,
        scopes: ((json['scopes'] as List?) ?? ['openid', 'profile', 'email'])
            .cast<String>(),
        extraAuthParams:
            ((json['extraAuthParams'] as Map?) ?? const {}).cast<String, String>(),
      );
}

/// Discovery-Endpunkte aus `/.well-known/openid-configuration`.
class OidcDiscovery {
  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String? userinfoEndpoint;
  final String? jwksUri;
  final String? endSessionEndpoint;

  const OidcDiscovery({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.userinfoEndpoint,
    this.jwksUri,
    this.endSessionEndpoint,
  });

  factory OidcDiscovery.fromJson(Map<String, dynamic> json) => OidcDiscovery(
        issuer: json['issuer'] as String,
        authorizationEndpoint: json['authorization_endpoint'] as String,
        tokenEndpoint: json['token_endpoint'] as String,
        userinfoEndpoint: json['userinfo_endpoint'] as String?,
        jwksUri: json['jwks_uri'] as String?,
        endSessionEndpoint: json['end_session_endpoint'] as String?,
      );
}
