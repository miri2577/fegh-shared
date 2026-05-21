import 'dart:typed_data';

import 'package:webdav_client/webdav_client.dart' as webdav;

import '../cloud_adapter.dart';
import '../result.dart';

/// Adapter fuer STRATO HiDrive via WebDAV.
///
/// Nutzt das `webdav_client`-Package, das die STRATO-Quirks
/// (u.a. MKCOL-Content-Type-Sensitivitaet) korrekt behandelt.
///
/// URL-Schema:
/// ```
/// https://webdav.hidrive.strato.com/users/{username}/{subdirectory}
/// ```
///
/// Basis-Auth mit Username + Passwort (STRATO App-Passwort).
class HidriveAdapter implements CloudAdapter {
  static const String _baseHost = 'https://webdav.hidrive.strato.com';

  final String username;
  final String password;

  /// Wurzel-URL - entweder direkt gesetzt oder aus username +
  /// rootSubdirectory konstruiert.
  final String baseUrl;

  late final webdav.Client _client;

  HidriveAdapter({
    required this.username,
    required this.password,
    String? rootSubdirectory,
    String? baseUrlOverride,
  }) : baseUrl = baseUrlOverride ??
            _buildBaseUrl(username, rootSubdirectory) {
    _client = webdav.newClient(
      baseUrl,
      user: username,
      password: password,
      debug: false,
    );
    _client.setHeaders({
      'User-Agent': 'FEGH/1.0 (fegh_cloud)',
    });
  }

  static String _buildBaseUrl(String username, String? rootSubdirectory) {
    var url = '$_baseHost/users/$username';
    if (rootSubdirectory != null && rootSubdirectory.trim().isNotEmpty) {
      final root = rootSubdirectory.trim().replaceAll(RegExp(r'^/+|/+$'), '');
      url = '$url/$root';
    }
    return url;
  }

  @override
  CloudProviderType get providerType => CloudProviderType.hidrive;

  @override
  Future<CloudResult<void>> testConnection() async {
    try {
      await _client.ping();
      return const CloudResult.success();
    } catch (e) {
      return CloudResult.failure('Verbindung fehlgeschlagen: $e');
    }
  }

  @override
  Future<CloudResult<void>> createDirectory(String path) async {
    try {
      // webdav_client.mkdirAll legt fehlende Zwischenordner mit an
      await _client.mkdirAll(_normalize(path));
      return const CloudResult.success();
    } catch (e) {
      final msg = e.toString();
      // 405 = Method Not Allowed → Ordner existiert bereits (OK)
      if (msg.contains('405') || msg.toLowerCase().contains('already')) {
        return const CloudResult.success();
      }
      return CloudResult.failure(
        'MKCOL $path fehlgeschlagen: $e',
        statusCode: _extractStatusCode(msg),
      );
    }
  }

  @override
  Future<CloudResult<void>> upload(String path, Uint8List data) async {
    try {
      await _client.write(_normalize(path), data);
      return const CloudResult.success();
    } catch (e) {
      return CloudResult.failure(
        'Upload $path fehlgeschlagen: $e',
        statusCode: _extractStatusCode(e.toString()),
      );
    }
  }

  @override
  Future<CloudResult<Uint8List>> download(String path) async {
    try {
      final bytes = await _client.read(_normalize(path));
      return CloudResult.success(Uint8List.fromList(bytes));
    } catch (e) {
      final code = _extractStatusCode(e.toString());
      return CloudResult.failure(
        'Download $path fehlgeschlagen: $e',
        statusCode: code,
      );
    }
  }

  @override
  Future<CloudResult<void>> delete(String path) async {
    try {
      await _client.remove(_normalize(path));
      return const CloudResult.success();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404')) {
        // Nicht vorhanden = als geloescht betrachten
        return const CloudResult.success();
      }
      return CloudResult.failure(
        'Delete $path fehlgeschlagen: $e',
        statusCode: _extractStatusCode(msg),
      );
    }
  }

  @override
  Future<CloudResult<List<CloudEntry>>> list(String path) async {
    try {
      final files = await _client.readDir(_normalize(path));
      final entries = files.map((f) => _toEntry(f, path)).toList();
      return CloudResult.success(entries);
    } catch (e) {
      return CloudResult.failure(
        'List $path fehlgeschlagen: $e',
        statusCode: _extractStatusCode(e.toString()),
      );
    }
  }

  @override
  Future<CloudResult<List<CloudEntry>>> listDirectories(String path) async {
    final result = await list(path);
    if (!result.isSuccess) return result;
    final dirs = result.data!.where((e) => e.isDirectory).toList();
    return CloudResult.success(dirs);
  }

  @override
  Future<CloudResult<bool>> exists(String path) async {
    try {
      // readProps wirft bei nicht existierenden Pfaden eine Exception
      await _client.readProps(_normalize(path));
      return const CloudResult.success(true);
    } catch (e) {
      if (e.toString().contains('404')) {
        return const CloudResult.success(false);
      }
      return CloudResult.failure(
        'Exists-Check $path fehlgeschlagen: $e',
        statusCode: _extractStatusCode(e.toString()),
      );
    }
  }

  @override
  void dispose() {
    // webdav.Client hat keinen expliziten dispose
  }

  // ── Helpers ─────────────────────────────────────────────────────

  String _normalize(String path) {
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }

  CloudEntry _toEntry(webdav.File f, String parentPath) {
    final name = f.name ?? '';
    final parent = parentPath.endsWith('/') ? parentPath : '$parentPath/';
    return CloudEntry(
      name: name,
      path: f.path ?? '$parent$name',
      isDirectory: f.isDir ?? false,
      size: f.size,
      lastModified: f.mTime,
      etag: f.eTag,
    );
  }

  int? _extractStatusCode(String errorMessage) {
    final match = RegExp(r'\b(\d{3})\b').firstMatch(errorMessage);
    if (match != null) {
      final code = int.tryParse(match.group(1)!);
      if (code != null && code >= 100 && code < 600) return code;
    }
    return null;
  }
}
