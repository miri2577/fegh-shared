import 'dart:typed_data';

import 'result.dart';

/// Einheitliche API fuer Cloud-Storage-Provider (WebDAV-basiert).
///
/// Implementierungen pro Provider: [HidriveAdapter], [NextcloudAdapter],
/// [OwncloudAdapter], [GenericWebdavAdapter]. Alle Methoden sind idempotent
/// wo moeglich (createDirectory + delete sind OK bei nicht existenten Pfaden).
abstract class CloudAdapter {
  CloudProviderType get providerType;

  /// Prueft die Verbindung inkl. Authentifizierung.
  /// Success: Server erreichbar + Credentials gueltig.
  Future<CloudResult<void>> testConnection();

  /// Legt einen Ordner inkl. aller fehlenden Zwischenordner an.
  /// Pfad ohne fuehrenden Slash, relativ zum User-Root.
  /// Returns success auch bei bereits existenten Ordnern.
  Future<CloudResult<void>> createDirectory(String path);

  /// Laedt eine Datei hoch. Ueberschreibt bestehende Dateien.
  Future<CloudResult<void>> upload(String path, Uint8List data);

  /// Laedt eine Datei herunter.
  /// Failure mit statusCode=404 wenn Datei nicht existiert.
  Future<CloudResult<Uint8List>> download(String path);

  /// Loescht Datei oder Ordner (rekursiv).
  /// Success auch bei nicht existenten Pfaden.
  Future<CloudResult<void>> delete(String path);

  /// Listet alle Eintraege eines Ordners (1 Ebene tief).
  /// Failure mit statusCode=404 wenn Ordner nicht existiert.
  Future<CloudResult<List<CloudEntry>>> list(String path);

  /// Listet nur Unterordner (fuer Team-Discovery etc.).
  Future<CloudResult<List<CloudEntry>>> listDirectories(String path);

  /// Prueft ob Datei oder Ordner existiert.
  Future<CloudResult<bool>> exists(String path);

  /// Schliesst offene Verbindungen.
  void dispose();
}
