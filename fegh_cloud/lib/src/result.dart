/// Ergebnis einer Cloud-Operation.
///
/// Success-Fall: `isSuccess == true`, `data` gesetzt (falls der Call Daten
/// liefert), `error == null`.
///
/// Failure-Fall: `isSuccess == false`, `error` enthaelt die Beschreibung,
/// `statusCode` den HTTP-Code (falls verfuegbar).
class CloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  const CloudResult.success([T? data])
      : isSuccess = true,
        data = data,
        error = null,
        statusCode = null;

  const CloudResult.failure(String errorMessage, {int? statusCode})
      : isSuccess = false,
        data = null,
        error = errorMessage,
        statusCode = statusCode;

  @override
  String toString() => isSuccess
      ? 'CloudResult.success(${data ?? "void"})'
      : 'CloudResult.failure($statusCode $error)';
}

/// Eintrag im Cloud-Verzeichnis (Datei oder Ordner).
class CloudEntry {
  /// Nur der Name (ohne Pfad-Praefix), z.B. `team-info.bin`.
  final String name;

  /// Vollstaendiger Remote-Pfad vom WebDAV-Root aus.
  final String path;
  final bool isDirectory;
  final int? size; // null bei Ordnern
  final DateTime? lastModified;
  final String? etag;

  const CloudEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.etag,
  });

  @override
  String toString() =>
      'CloudEntry($name, ${isDirectory ? "dir" : "$size bytes"})';
}

/// Kategorie des Cloud-Providers.
enum CloudProviderType {
  hidrive,
  nextcloud,
  owncloud,
  generic,
}
