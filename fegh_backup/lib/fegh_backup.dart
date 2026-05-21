/// Gemeinsame Backup- und Recovery-Services fuer FEGH-Apps (Doku + Verwaltung).
///
/// Das Paket bietet drei Primitiven, die App-unabhaengig sind:
///
/// - [RecoveryService] - 12-Wort Recovery-Phrase (deutsche Wortliste
///   mit 128 Eintraegen), MEK-Wiederherstellung ueber Recovery-Key
///   (AES-256-GCM + PBKDF2 50 000 Runden) und Recovery-Token
///   (PIN-geschuetzt, ablaufbar) fuer Teamleitung -> Mitarbeiter.
/// - [BackupCodec] - Passwort-basierte AES-256-GCM Verschluesselung
///   fuer Backup-Dateien (IV + ciphertext + MAC in einem Byte-Array).
/// - [BackupEnvelope] - Generischer Container mit Metadaten (ID,
///   Zeitstempel, Gerae­tename, App-/Daten-Version), App-spezifischer
///   Payload bleibt beliebiger JSON.
///
/// Die Apps erzeugen eigene Content-Klassen (z. B. die Doku-BackupData
/// mit Clients/Appointments) und wickeln diese in [BackupEnvelope] ein.
library;

export 'src/recovery_service.dart';
export 'src/backup_codec.dart';
export 'src/backup_envelope.dart';
