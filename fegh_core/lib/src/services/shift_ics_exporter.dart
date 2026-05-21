import '../models/shift.dart';

/// Exportiert [Shift]s als iCalendar (RFC 5545).
///
/// Ziel ist ein in Outlook, Apple Kalender, Google Calendar und
/// Thunderbird importierbarer Feed. Zeiten werden in UTC (`...Z`)
/// geschrieben, damit kein VTIMEZONE-Block noetig ist.
///
/// Abgesagte Schichten ([ShiftStatus.cancelled]) werden uebersprungen —
/// man will sie nicht im Kalender sehen.
class ShiftIcsExporter {
  static const _crlf = '\r\n';

  /// Erzeugt den vollstaendigen ICS-Inhalt fuer [shifts].
  ///
  /// [prodId] erscheint als PRODID. [calName] wird als X-WR-CALNAME
  /// gesetzt (Anzeigename in den gaengigen Clients).
  /// [employeeNameResolver] liefert pro employeeId den Anzeigenamen
  /// fuer den SUMMARY-Text; ohne Resolver wird die id verwendet.
  static String export(
    Iterable<Shift> shifts, {
    String prodId = '-//FEGH//Dienstplan//DE',
    String? calName,
    String Function(String employeeId)? employeeNameResolver,
  }) {
    final buf = StringBuffer();
    _writeLine(buf, 'BEGIN:VCALENDAR');
    _writeLine(buf, 'VERSION:2.0');
    _writeLine(buf, 'PRODID:$prodId');
    _writeLine(buf, 'CALSCALE:GREGORIAN');
    _writeLine(buf, 'METHOD:PUBLISH');
    if (calName != null && calName.isNotEmpty) {
      _writeLine(buf, 'X-WR-CALNAME:${_escape(calName)}');
      _writeLine(buf, 'X-WR-TIMEZONE:Europe/Berlin');
    }
    for (final s in shifts) {
      if (s.status == ShiftStatus.cancelled) continue;
      _writeEvent(
        buf,
        s,
        employeeName: employeeNameResolver?.call(s.employeeId),
      );
    }
    _writeLine(buf, 'END:VCALENDAR');
    return buf.toString();
  }

  static void _writeEvent(
    StringBuffer buf,
    Shift s, {
    String? employeeName,
  }) {
    final dtStamp = _formatUtc(DateTime.now().toUtc());
    final dtStart = _formatUtc(s.startTime.toUtc());
    final dtEnd = _formatUtc(s.endTime.toUtc());

    final namePart = employeeName ?? s.employeeId;
    final summaryParts = <String>[
      'Dienst ${s.type.displayName}',
      if (namePart.isNotEmpty) namePart,
    ];
    final summary = summaryParts.join(' — ');

    final descLines = <String>[
      if (s.description != null && s.description!.isNotEmpty) s.description!,
      'Status: ${s.status.displayName}',
      'Typ: ${s.type.displayName}',
      if (s.teamId != null) 'Team: ${s.teamId}',
      if (s.breakDurationMinutes != null && s.breakDurationMinutes! > 0)
        'Pause: ${s.breakDurationMinutes!.toStringAsFixed(0)} min',
      if (s.notes != null && s.notes!.isNotEmpty) 'Notiz: ${s.notes}',
    ];
    final description = descLines.join('\\n');

    _writeLine(buf, 'BEGIN:VEVENT');
    _writeLine(buf, 'UID:${s.id}@fegh');
    _writeLine(buf, 'DTSTAMP:$dtStamp');
    _writeLine(buf, 'DTSTART:$dtStart');
    _writeLine(buf, 'DTEND:$dtEnd');
    _writeLine(buf, 'SUMMARY:${_escape(summary)}');
    if (description.isNotEmpty) {
      _writeLine(buf, 'DESCRIPTION:${_escape(description)}');
    }
    if (s.location != null && s.location!.isNotEmpty) {
      _writeLine(buf, 'LOCATION:${_escape(s.location!)}');
    }
    _writeLine(buf, 'STATUS:${_icsStatus(s.status)}');
    _writeLine(buf, 'TRANSP:OPAQUE');
    _writeLine(buf, 'END:VEVENT');
  }

  static String _icsStatus(ShiftStatus s) {
    switch (s) {
      case ShiftStatus.scheduled:
        return 'CONFIRMED';
      case ShiftStatus.inProgress:
      case ShiftStatus.completed:
        return 'CONFIRMED';
      case ShiftStatus.cancelled:
        return 'CANCELLED';
      case ShiftStatus.noShow:
        return 'TENTATIVE';
    }
  }

  static String _formatUtc(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    String four(int n) => n.toString().padLeft(4, '0');
    return '${four(utc.year)}${two(utc.month)}${two(utc.day)}'
        'T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  /// RFC 5545 TEXT-Escape: `\\`, `\,`, `\;`, `\n`.
  static String _escape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\r\n', '\\n')
        .replaceAll('\n', '\\n');
  }

  /// Schreibt [line] mit CRLF und faltet ueber 75 Oktetts.
  static void _writeLine(StringBuffer buf, String line) {
    final bytes = line.codeUnits;
    if (bytes.length <= 75) {
      buf.write(line);
      buf.write(_crlf);
      return;
    }
    var start = 0;
    var first = true;
    while (start < bytes.length) {
      final take = first ? 75 : 74;
      final end = (start + take).clamp(0, bytes.length);
      final slice = String.fromCharCodes(bytes.sublist(start, end));
      if (first) {
        buf.write(slice);
        first = false;
      } else {
        buf.write(' ');
        buf.write(slice);
      }
      buf.write(_crlf);
      start = end;
    }
  }
}
