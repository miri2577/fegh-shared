/// OIDC-Login (OAuth 2.0 Authorization Code + PKCE + RFC 8252
/// Loopback-Redirect) fuer FEGH-Desktop-Apps.
///
/// Nutzt den System-Browser (kein embedded Webview) und einen
/// kurzlebigen HTTP-Server auf 127.0.0.1:<dynamisch>. Tokens werden
/// im `flutter_secure_storage` abgelegt (DPAPI/Keychain/Keystore).
///
/// Kompatibel mit:
/// - Microsoft Entra ID (`https://login.microsoftonline.com/<tenant>/v2.0`)
/// - Keycloak (`https://host/realms/<realm>`)
/// - Google (`https://accounts.google.com`)
/// - jeder RFC-8414-konforme Provider mit `/.well-known/openid-configuration`
library;

export 'src/oidc_config.dart';
export 'src/oidc_login_service.dart';
export 'src/oidc_tokens.dart';
export 'src/pkce.dart';
