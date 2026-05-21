import 'dart:convert';

/// Ausgabe-Formate fuer den SIEM-Export.
enum SiemFormat {
  /// RFC 5424 Syslog mit strukturierten Daten.
  /// Kompatibel mit rsyslog, syslog-ng, Splunk UF, rsyslog-to-SIEM-Adaptern.
  syslog5424,

  /// ArcSight Common Event Format (CEF). Kompatibel mit ArcSight,
  /// Splunk CEF TA, QRadar, LogRhythm.
  cef,

  /// Normalisierte JSON Lines (eine Zeile pro Event). Kompatibel mit
  /// ELK, Loki, OpenSearch, generischen SIEM-Adaptern.
  jsonLines,
}

/// Exporter, der Audit-Eintraege (JSON Lines aus [AuditLogger]) in
/// SIEM-freundliche Formate konvertiert.
///
/// Die Input-Eintraege haben die Struktur
/// `{ts, action, userId, ctx?}`; der Exporter ergaenzt ein Severity-
/// Level (Default `info`) und respektiert Facility/Hostname/App-Name.
class SiemExporter {
  /// Facility 13 = 'log audit' (RFC 5424 Tabelle 1).
  static const int _facility = 13;

  /// Severity 6 = 'informational'.
  static const int _defaultSeverity = 6;

  /// Mehr-Severity fuer fehlgeschlagene/stornierte Ereignisse.
  static const Map<String, int> _severityOverrides = {
    'auth.login_failed': 4, // warning
    'medication.refused': 5, // notice
    'medication.missed': 4, // warning
    'kassenbuch.entry.storno': 5,
    'shift.swap.rejected': 5,
    'medication.btm.destroyed': 5,
  };

  final String hostname;
  final String appName;
  final String appVersion;
  final int processId;
  final String vendor;

  const SiemExporter({
    required this.hostname,
    required this.appName,
    required this.appVersion,
    this.processId = 0,
    this.vendor = 'FEGH',
  });

  /// Haupt-Konvertierung: Liste der Audit-Eintraege → SIEM-Format.
  String export(
    Iterable<Map<String, dynamic>> entries, {
    required SiemFormat format,
    DateTime? since,
    DateTime? until,
    String? actionPrefix,
  }) {
    final buffer = StringBuffer();
    for (final entry in _filter(entries,
        since: since, until: until, actionPrefix: actionPrefix)) {
      final line = _formatOne(entry, format);
      if (line.isEmpty) continue;
      buffer.write(line);
      buffer.write('\n');
    }
    return buffer.toString();
  }

  Iterable<Map<String, dynamic>> _filter(
    Iterable<Map<String, dynamic>> entries, {
    DateTime? since,
    DateTime? until,
    String? actionPrefix,
  }) sync* {
    for (final e in entries) {
      final tsRaw = e['ts'];
      if (tsRaw is! String) continue;
      final ts = DateTime.tryParse(tsRaw);
      if (ts == null) continue;
      if (since != null && ts.isBefore(since)) continue;
      if (until != null && !ts.isBefore(until)) continue;
      final action = (e['action'] as String?) ?? '';
      if (actionPrefix != null && !action.startsWith(actionPrefix)) continue;
      yield e;
    }
  }

  String _formatOne(Map<String, dynamic> e, SiemFormat format) {
    final ts = DateTime.parse(e['ts'] as String).toUtc();
    final action = (e['action'] as String?) ?? 'unknown';
    final userId = (e['userId'] as String?) ?? 'system';
    final ctx = (e['ctx'] as Map?)?.cast<String, dynamic>() ?? const {};
    final severity = _severityOverrides[action] ?? _defaultSeverity;

    switch (format) {
      case SiemFormat.syslog5424:
        return _renderSyslog(ts, action, userId, ctx, severity);
      case SiemFormat.cef:
        return _renderCef(ts, action, userId, ctx, severity);
      case SiemFormat.jsonLines:
        return _renderJsonLine(ts, action, userId, ctx, severity);
    }
  }

  /// RFC 5424 Syslog-Zeile:
  ///
  ///   <PRI>1 TIMESTAMP HOST APP PID MSGID [SD-ID k="v" ...] MSG
  String _renderSyslog(
    DateTime ts,
    String action,
    String userId,
    Map<String, dynamic> ctx,
    int severity,
  ) {
    final pri = _facility * 8 + severity;
    final sd = _structuredData(userId, ctx);
    final msg = _humanMsg(action, userId, ctx);
    return '<$pri>1 ${_rfc3339(ts)} ${_sanitize(hostname)} '
        '${_sanitize(appName)} ${processId > 0 ? processId : '-'} '
        '${_sanitize(action)} $sd $msg';
  }

  /// CEF: CEF:0|Vendor|Product|Version|SignatureID|Name|Severity|Extensions
  String _renderCef(
    DateTime ts,
    String action,
    String userId,
    Map<String, dynamic> ctx,
    int severity,
  ) {
    final extensions = <String>[
      'rt=${ts.millisecondsSinceEpoch}',
      'suser=${_cefEscapeVal(userId)}',
      'shost=${_cefEscapeVal(hostname)}',
      for (final entry in ctx.entries)
        '${_cefKey(entry.key)}=${_cefEscapeVal(entry.value.toString())}',
    ].join(' ');
    // CEF-severity is 0–10; map RFC 5424 (0-7) → 10 - sev*1.2 is nonsense.
    // Lieber: informational=3, notice=5, warning=6, error=8, critical=9.
    final cefSev = _cefSeverity(severity);
    return 'CEF:0|${_cefHeader(vendor)}|${_cefHeader(appName)}|'
        '${_cefHeader(appVersion)}|${_cefHeader(action)}|'
        '${_cefHeader(_humanMsg(action, userId, ctx))}|$cefSev|$extensions';
  }

  String _renderJsonLine(
    DateTime ts,
    String action,
    String userId,
    Map<String, dynamic> ctx,
    int severity,
  ) {
    return jsonEncode({
      '@timestamp': ts.toIso8601String(),
      'host': hostname,
      'app': appName,
      'app.version': appVersion,
      'event.action': action,
      'event.severity': _levelName(severity),
      'user.id': userId,
      if (ctx.isNotEmpty) 'event.context': ctx,
    });
  }

  // ── Helpers ────────────────────────────────────────────────────

  String _rfc3339(DateTime ts) {
    final s = ts.toIso8601String();
    // Dart hinterlaesst "Z" am Ende fuer UTC — RFC 5424 will genau das.
    return s.endsWith('Z') ? s : '${s}Z';
  }

  String _structuredData(String userId, Map<String, dynamic> ctx) {
    final buf = StringBuffer('[fegh@12345');
    buf.write(' userId="${_sdEscape(userId)}"');
    for (final entry in ctx.entries) {
      buf.write(' ${_sdKey(entry.key)}="${_sdEscape(entry.value.toString())}"');
    }
    buf.write(']');
    return buf.toString();
  }

  String _humanMsg(String action, String userId, Map<String, dynamic> ctx) {
    if (ctx.isEmpty) return 'user=$userId action=$action';
    final ctxStr = ctx.entries
        .take(3)
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    return 'user=$userId action=$action $ctxStr';
  }

  String _levelName(int sev) {
    switch (sev) {
      case 0:
        return 'emergency';
      case 1:
        return 'alert';
      case 2:
        return 'critical';
      case 3:
        return 'error';
      case 4:
        return 'warning';
      case 5:
        return 'notice';
      case 6:
        return 'informational';
      case 7:
        return 'debug';
      default:
        return 'informational';
    }
  }

  int _cefSeverity(int rfc5424Severity) {
    switch (rfc5424Severity) {
      case 0:
      case 1:
      case 2:
        return 9;
      case 3:
        return 8;
      case 4:
        return 6;
      case 5:
        return 5;
      case 6:
        return 3;
      default:
        return 3;
    }
  }

  // ── Escaping ───────────────────────────────────────────────────

  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^\x21-\x7e]'), '-');

  String _sdKey(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9._]'), '_');

  String _sdEscape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll(']', '\\]');

  String _cefHeader(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('|', '\\|');

  String _cefKey(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

  String _cefEscapeVal(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('=', '\\=')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ');
}
