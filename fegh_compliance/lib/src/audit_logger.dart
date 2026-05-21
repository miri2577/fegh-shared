import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persistenter Audit-Logger fuer DSGVO-konforme Protokollierung.
/// Speichert wer wann was getan hat als JSON-Lines.
class AuditLogger {
  static AuditLogger? _instance;
  File? _logFile;

  AuditLogger._();

  static AuditLogger get instance {
    _instance ??= AuditLogger._();
    return _instance!;
  }

  Future<File> _getLogFile() async {
    if (_logFile != null) return _logFile!;
    if (kIsWeb) throw UnsupportedError('AuditLogger nicht auf Web verfuegbar');
    final dir = await getApplicationSupportDirectory();
    _logFile = File('${dir.path}/audit.log');
    return _logFile!;
  }

  /// Schreibt einen Audit-Eintrag.
  Future<void> log({
    required String action,
    required String userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (kIsWeb) return;
      final entry = {
        'ts': DateTime.now().toUtc().toIso8601String(),
        'action': action,
        'userId': userId,
        if (context != null) 'ctx': context,
      };
      final file = await _getLogFile();
      await file.writeAsString(
        '${jsonEncode(entry)}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AUDIT] Log-Fehler: $e');
    }
  }

  /// Liest die letzten N Eintraege.
  Future<List<Map<String, dynamic>>> getLastEntries({int count = 100}) async {
    try {
      if (kIsWeb) return [];
      final file = await _getLogFile();
      if (!await file.exists()) return [];
      final lines = await file.readAsLines();
      final entries = <Map<String, dynamic>>[];
      final start = lines.length > count ? lines.length - count : 0;
      for (int i = start; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        try {
          entries.add(jsonDecode(lines[i]));
        } catch (_) {}
      }
      return entries;
    } catch (e) {
      if (kDebugMode) debugPrint('[AUDIT] Lese-Fehler: $e');
      return [];
    }
  }

  /// Loescht das Audit-Log (z.B. bei DSGVO-Loeschung).
  Future<void> clear() async {
    try {
      if (kIsWeb) return;
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
      _logFile = null;
    } catch (e) {
      if (kDebugMode) debugPrint('[AUDIT] Clear-Fehler: $e');
    }
  }

  /// Rotiert das Log: Eintraege aelter als [maxAge] werden entfernt.
  /// Standard: 3 Jahre (DSGVO Art. 5 Abs. 2 Rechenschaftspflicht).
  Future<void> rotate({Duration maxAge = const Duration(days: 1095)}) async {
    try {
      if (kIsWeb) return;
      final file = await _getLogFile();
      if (!await file.exists()) return;

      final cutoff = DateTime.now().subtract(maxAge);
      final lines = await file.readAsLines();
      final kept = <String>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final entry = jsonDecode(line);
          final ts = DateTime.parse(entry['ts']);
          if (ts.isAfter(cutoff)) {
            kept.add(line);
          }
        } catch (_) {
          kept.add(line); // Kaputte Zeilen behalten
        }
      }

      final removed = lines.length - kept.length;
      if (removed > 0) {
        await file.writeAsString('${kept.join('\n')}\n');
        if (kDebugMode) debugPrint('[AUDIT] Rotation: $removed Eintraege entfernt');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AUDIT] Rotation-Fehler: $e');
    }
  }

  // ── Vordefinierte Audit-Aktionen ────────────────────────────────

  Future<void> logClientAccess(String userId, String clientId) =>
      log(action: 'client.access', userId: userId, context: {'clientId': clientId});

  Future<void> logClientCreate(String userId, String clientId) =>
      log(action: 'client.create', userId: userId, context: {'clientId': clientId});

  Future<void> logClientUpdate(String userId, String clientId) =>
      log(action: 'client.update', userId: userId, context: {'clientId': clientId});

  Future<void> logClientDelete(String userId, String clientId) =>
      log(action: 'client.delete', userId: userId, context: {'clientId': clientId});

  Future<void> logLogin(String userId, String method) =>
      log(action: 'auth.login', userId: userId, context: {'method': method});

  Future<void> logLogout(String userId) =>
      log(action: 'auth.logout', userId: userId);

  Future<void> logLoginFailed(String userId) =>
      log(action: 'auth.login_failed', userId: userId);

  Future<void> logTeamCreate(String userId, String teamId) =>
      log(action: 'team.create', userId: userId, context: {'teamId': teamId});

  Future<void> logUserInvite(String userId, String invitedUser, String teamId) =>
      log(action: 'user.invite', userId: userId, context: {'invitedUser': invitedUser, 'teamId': teamId});

  Future<void> logRoleChange(String userId, String targetUser, String newRole) =>
      log(action: 'role.change', userId: userId, context: {'targetUser': targetUser, 'newRole': newRole});

  Future<void> logDataExport(String userId, String type) =>
      log(action: 'data.export', userId: userId, context: {'type': type});

  Future<void> logDataDelete(String userId, String type) =>
      log(action: 'data.delete', userId: userId, context: {'type': type});

  Future<void> logRecoveryTokenGenerated(String userId, String targetUser) =>
      log(action: 'recovery.generated', userId: userId, context: {'targetUser': targetUser});

  Future<void> logRecoveryUsed(String userId) =>
      log(action: 'recovery.used', userId: userId);

  // ── Rechnungs-Events ────────────────────────────────────────────

  Future<void> logRechnungErstellt(String userId, String rechnungsnr, double betrag) =>
      log(action: 'rechnung.create', userId: userId, context: {
        'rechnungsnr': rechnungsnr,
        'brutto': betrag,
      });

  Future<void> logRechnungStatusAenderung(
    String userId,
    String rechnungsnr,
    String alterStatus,
    String neuerStatus,
  ) =>
      log(action: 'rechnung.status', userId: userId, context: {
        'rechnungsnr': rechnungsnr,
        'alt': alterStatus,
        'neu': neuerStatus,
      });

  Future<void> logRechnungStorniert(String userId, String originalNr, String stornoNr) =>
      log(action: 'rechnung.storno', userId: userId, context: {
        'original': originalNr,
        'storno': stornoNr,
      });

  Future<void> logRechnungXmlExport(String userId, String rechnungsnr) =>
      log(action: 'rechnung.xml_export', userId: userId, context: {
        'rechnungsnr': rechnungsnr,
      });

  // ── Static-Compat-API (fuer FEGH-Verwaltung) ───────────────────
  //
  // Die Verwaltung nutzt historisch eine andere API-Form. Die
  // folgenden static Methoden delegieren an das Singleton, damit
  // beide Apps mit demselben Logger arbeiten.

  static Future<void> logStatic(String action,
      {Map<String, dynamic>? context, String userId = 'system'}) async {
    await AuditLogger.instance
        .log(action: action, userId: userId, context: context);
  }

  /// Liefert die letzten [lines] Eintraege als JSON-Strings.
  /// Verwaltungs-Kompatibilitaet: tail() statt getLastEntries().
  static Future<List<String>> tail({int lines = 200}) async {
    final entries = await AuditLogger.instance.getLastEntries(count: lines);
    return entries.map(jsonEncode).toList();
  }
}
