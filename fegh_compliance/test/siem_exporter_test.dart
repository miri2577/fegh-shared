import 'dart:convert';

import 'package:fegh_compliance/fegh_compliance.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _entry({
  required String action,
  String userId = 'alice@fegh.local',
  Map<String, dynamic>? ctx,
  DateTime? ts,
}) {
  return {
    'ts': (ts ?? DateTime.utc(2026, 4, 19, 21, 0, 0)).toIso8601String(),
    'action': action,
    'userId': userId,
    if (ctx != null) 'ctx': ctx,
  };
}

SiemExporter _exporter() => const SiemExporter(
      hostname: 'fegh-host',
      appName: 'fegh-verwaltung',
      appVersion: '0.3.0',
      processId: 1234,
    );

void main() {
  group('SiemExporter — Syslog RFC 5424', () {
    test('erzeugt PRI + Version + Timestamp', () {
      final out = _exporter().export(
        [_entry(action: 'client.access', ctx: {'clientId': 'c1'})],
        format: SiemFormat.syslog5424,
      );
      // facility 13 * 8 + severity 6 = 110
      expect(out, startsWith('<110>1 2026-04-19T21:00:00.000Z '));
      expect(out, contains('fegh-host fegh-verwaltung 1234 client.access'));
    });

    test('rendert Structured Data mit userId und Kontext', () {
      final out = _exporter().export(
        [_entry(action: 'client.access', ctx: {'clientId': 'c1'})],
        format: SiemFormat.syslog5424,
      );
      expect(out, contains('[fegh@12345 userId="alice@fegh.local" clientId="c1"]'));
    });

    test('escaped Quotes/Brackets im Structured Data', () {
      final out = _exporter().export(
        [_entry(action: 'client.note', ctx: {'note': 'er sagte "hallo" ]danke['})],
        format: SiemFormat.syslog5424,
      );
      expect(out, contains(r'note="er sagte \"hallo\" \]danke["'));
    });

    test('hebt Severity bei Login-Fehler auf warning', () {
      final out = _exporter().export(
        [_entry(action: 'auth.login_failed', userId: 'unbekannt')],
        format: SiemFormat.syslog5424,
      );
      // facility 13 * 8 + severity 4 = 108
      expect(out, startsWith('<108>1 '));
    });
  });

  group('SiemExporter — CEF', () {
    test('erzeugt CEF-Header mit Vendor/Product/Version', () {
      final out = _exporter().export(
        [_entry(action: 'client.access', ctx: {'clientId': 'c1'})],
        format: SiemFormat.cef,
      );
      expect(out,
          startsWith('CEF:0|FEGH|fegh-verwaltung|0.3.0|client.access|'));
    });

    test('rendert Extensions mit rt, suser, shost und Kontext-Feldern', () {
      final out = _exporter().export(
        [_entry(action: 'client.access', ctx: {'clientId': 'c1'})],
        format: SiemFormat.cef,
      );
      expect(out, contains('rt=1776632400000'));
      expect(out, contains('suser=alice@fegh.local'));
      expect(out, contains('shost=fegh-host'));
      expect(out, contains('clientId=c1'));
    });

    test('escapet | im Header und = in Extensions', () {
      final out = SiemExporter(
        hostname: 'host',
        appName: 'bad|app',
        appVersion: '1.0',
      ).export(
        [_entry(action: 'x', ctx: {'k': 'v=with=eq'})],
        format: SiemFormat.cef,
      );
      expect(out, contains(r'bad\|app'));
      expect(out, contains(r'k=v\=with\=eq'));
    });
  });

  group('SiemExporter — JSON Lines', () {
    test('normalisiert auf ECS-aehnliche Felder', () {
      final out = _exporter().export(
        [_entry(action: 'client.access', ctx: {'clientId': 'c1'})],
        format: SiemFormat.jsonLines,
      );
      final decoded = jsonDecode(out.trim()) as Map<String, dynamic>;
      expect(decoded['@timestamp'], '2026-04-19T21:00:00.000Z');
      expect(decoded['event.action'], 'client.access');
      expect(decoded['event.severity'], 'informational');
      expect(decoded['user.id'], 'alice@fegh.local');
      expect(decoded['event.context'], {'clientId': 'c1'});
    });

    test('laesst context weg wenn leer', () {
      final out = _exporter().export(
        [_entry(action: 'auth.logout')],
        format: SiemFormat.jsonLines,
      );
      final decoded = jsonDecode(out.trim()) as Map<String, dynamic>;
      expect(decoded.containsKey('event.context'), isFalse);
    });
  });

  group('SiemExporter — Filter', () {
    test('since/until schneiden Zeitraum ab', () {
      final entries = [
        _entry(action: 'a', ts: DateTime.utc(2026, 4, 18)),
        _entry(action: 'b', ts: DateTime.utc(2026, 4, 19, 12)),
        _entry(action: 'c', ts: DateTime.utc(2026, 4, 20)),
      ];
      final out = _exporter().export(
        entries,
        format: SiemFormat.jsonLines,
        since: DateTime.utc(2026, 4, 19),
        until: DateTime.utc(2026, 4, 20),
      );
      expect(out.contains('"event.action":"a"'), isFalse);
      expect(out.contains('"event.action":"b"'), isTrue);
      expect(out.contains('"event.action":"c"'), isFalse);
    });

    test('actionPrefix filtert auf Modul', () {
      final entries = [
        _entry(action: 'client.access'),
        _entry(action: 'medication.given'),
        _entry(action: 'medication.refused'),
      ];
      final out = _exporter().export(
        entries,
        format: SiemFormat.jsonLines,
        actionPrefix: 'medication.',
      );
      expect(out.contains('"event.action":"client.access"'), isFalse);
      expect(out.split('\n').where((l) => l.isNotEmpty).length, 2);
    });

    test('ueberspringt kaputte Eintraege (ts fehlt)', () {
      final entries = [
        _entry(action: 'ok'),
        {'action': 'no-ts', 'userId': 'bob'}, // kaputt
      ];
      final out = _exporter().export(entries, format: SiemFormat.jsonLines);
      expect(out.split('\n').where((l) => l.isNotEmpty).length, 1);
    });
  });
}
