import 'package:fegh_core/fegh_core.dart';
import 'package:test/test.dart';

Shift _s({
  String id = 's1',
  String employeeId = 'e1',
  DateTime? start,
  DateTime? end,
  ShiftStatus status = ShiftStatus.scheduled,
  ShiftType type = ShiftType.regular,
  String? location,
  String? description,
  String? notes,
  String? teamId,
}) {
  final st = start ?? DateTime.utc(2026, 4, 20, 6, 0, 0);
  final et = end ?? DateTime.utc(2026, 4, 20, 14, 0, 0);
  return Shift(
    id: id,
    employeeId: employeeId,
    teamId: teamId,
    startTime: st,
    endTime: et,
    status: status,
    type: type,
    location: location,
    description: description,
    notes: notes,
    hourlyRate: 0,
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  );
}

void main() {
  group('ShiftIcsExporter', () {
    test('erzeugt gueltiges VCALENDAR-Geruest mit CRLF', () {
      final ics = ShiftIcsExporter.export(const <Shift>[]);
      expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
      expect(ics, contains('VERSION:2.0\r\n'));
      expect(ics, contains('PRODID:-//FEGH//Dienstplan//DE\r\n'));
      expect(ics, endsWith('END:VCALENDAR\r\n'));
    });

    test('schreibt DTSTART/DTEND in UTC mit Z', () {
      final ics = ShiftIcsExporter.export([_s()]);
      expect(ics, contains('DTSTART:20260420T060000Z'));
      expect(ics, contains('DTEND:20260420T140000Z'));
      expect(ics, contains('UID:s1@fegh'));
    });

    test('ueberspringt abgesagte Schichten', () {
      final ics = ShiftIcsExporter.export([
        _s(id: 'live'),
        _s(id: 'dead', status: ShiftStatus.cancelled),
      ]);
      expect(ics, contains('UID:live@fegh'));
      expect(ics, isNot(contains('UID:dead@fegh')));
    });

    test('escaped Kommas, Semikolons und Zeilenumbrueche', () {
      final ics = ShiftIcsExporter.export([
        _s(description: 'Zeile1\nZeile2; mit, Zeichen'),
      ]);
      expect(ics, contains(r'Zeile1\nZeile2\; mit\, Zeichen'));
    });

    test('setzt X-WR-CALNAME wenn calName uebergeben wird', () {
      final ics = ShiftIcsExporter.export(
        [_s()],
        calName: 'Mein Dienstplan',
      );
      expect(ics, contains('X-WR-CALNAME:Mein Dienstplan'));
    });

    test('nutzt employeeNameResolver fuer SUMMARY', () {
      final ics = ShiftIcsExporter.export(
        [_s(employeeId: 'e42')],
        employeeNameResolver: (id) => id == 'e42' ? 'Alice Muster' : id,
      );
      expect(ics, contains('Alice Muster'));
    });

    test('mapt ShiftStatus auf ICS-STATUS', () {
      final done = ShiftIcsExporter.export([_s(status: ShiftStatus.completed)]);
      expect(done, contains('STATUS:CONFIRMED'));
      final noshow = ShiftIcsExporter.export([_s(status: ShiftStatus.noShow)]);
      expect(noshow, contains('STATUS:TENTATIVE'));
    });

    test('faltet lange Zeilen (>75 Oktetts) mit Leerzeichen', () {
      final long = 'a' * 200;
      final ics = ShiftIcsExporter.export([_s(description: long)]);
      final lines = ics.split('\r\n');
      for (final l in lines) {
        expect(l.codeUnits.length, lessThanOrEqualTo(75));
      }
      expect(lines.any((l) => l.startsWith(' a')), isTrue);
    });
  });
}
