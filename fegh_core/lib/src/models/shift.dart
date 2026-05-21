/// Status einer Schicht.
enum ShiftStatus { scheduled, inProgress, completed, cancelled, noShow }

/// Schichttyp (Zuschlag beeinflusst Verguetung).
enum ShiftType { regular, overtime, holiday, night, weekend }

extension ShiftStatusDisplay on ShiftStatus {
  String get displayName {
    switch (this) {
      case ShiftStatus.scheduled:
        return 'Geplant';
      case ShiftStatus.inProgress:
        return 'Laufend';
      case ShiftStatus.completed:
        return 'Abgeschlossen';
      case ShiftStatus.cancelled:
        return 'Abgesagt';
      case ShiftStatus.noShow:
        return 'Nicht erschienen';
    }
  }
}

extension ShiftTypeDisplay on ShiftType {
  String get displayName {
    switch (this) {
      case ShiftType.regular:
        return 'Regulaer';
      case ShiftType.overtime:
        return 'Ueberstunden';
      case ShiftType.holiday:
        return 'Feiertag';
      case ShiftType.night:
        return 'Nacht';
      case ShiftType.weekend:
        return 'Wochenende';
    }
  }

  /// Lohn-Multiplikator fuer den Stundensatz.
  double get rateMultiplier {
    switch (this) {
      case ShiftType.regular:
        return 1.0;
      case ShiftType.overtime:
        return 1.5;
      case ShiftType.holiday:
        return 2.0;
      case ShiftType.night:
      case ShiftType.weekend:
        return 1.25;
    }
  }
}

/// Eine geplante oder tatsaechlich erbrachte Arbeitsschicht eines
/// Mitarbeiters. Basis der Dienstplanung und der Arbeitszeitabrechnung.
class Shift {
  final String id;
  final String employeeId;
  final String? teamId;

  /// Geplante Start- und Endzeit.
  final DateTime startTime;
  final DateTime endTime;

  /// Tatsaechliche Start-/Endzeit (werden beim Stempeln gesetzt).
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  final ShiftStatus status;
  final ShiftType type;
  final String? location;
  final String? description;
  final double? breakDurationMinutes;
  final double hourlyRate;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shift({
    required this.id,
    required this.employeeId,
    this.teamId,
    required this.startTime,
    required this.endTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    required this.type,
    this.location,
    this.description,
    this.breakDurationMinutes,
    required this.hourlyRate,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Getter ────────────────────────────────────────────────────────

  Duration get scheduledDuration => endTime.difference(startTime);

  Duration? get actualDuration {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  double get scheduledHours => scheduledDuration.inMinutes / 60.0;

  double? get actualHours {
    final duration = actualDuration;
    if (duration != null) {
      var hours = duration.inMinutes / 60.0;
      if (breakDurationMinutes != null) {
        hours -= breakDurationMinutes! / 60.0;
      }
      return hours;
    }
    return null;
  }

  double get scheduledPay => scheduledHours * hourlyRate;

  double get actualPay {
    final hours = actualHours;
    if (hours == null) return 0;
    return hours * hourlyRate * type.rateMultiplier;
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDate =
        DateTime(startTime.year, startTime.month, startTime.day);
    return shiftDate == today;
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  bool get isOverdue =>
      status == ShiftStatus.scheduled && endTime.isBefore(DateTime.now());

  bool get isInProgress => status == ShiftStatus.inProgress;

  bool get isCompleted => status == ShiftStatus.completed;

  // ── Zustandsuebergaenge ──────────────────────────────────────────

  Shift startShift() => copyWith(
        status: ShiftStatus.inProgress,
        actualStartTime: DateTime.now(),
      );

  Shift endShift() => copyWith(
        status: ShiftStatus.completed,
        actualEndTime: DateTime.now(),
      );

  Shift cancelShift() => copyWith(status: ShiftStatus.cancelled);

  // ── (De)Serialisierung ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'teamId': teamId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
        'status': status.name,
        'type': type.name,
        'location': location,
        'description': description,
        'breakDurationMinutes': breakDurationMinutes,
        'hourlyRate': hourlyRate,
        'notes': notes,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      employeeId: (json['employeeId'] as String?) ?? '',
      teamId: json['teamId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'] as String)
          : null,
      status: _parseEnum(json['status'], ShiftStatus.values,
          ShiftStatus.scheduled),
      type: _parseEnum(json['type'], ShiftType.values, ShiftType.regular),
      location: json['location'] as String?,
      description: json['description'] as String?,
      breakDurationMinutes: (json['breakDurationMinutes'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  static T _parseEnum<T extends Enum>(
      dynamic raw, List<T> values, T fallback) {
    if (raw is String) {
      for (final e in values) {
        if (e.name == raw) return e;
      }
    }
    return fallback;
  }

  Shift copyWith({
    String? id,
    String? employeeId,
    String? teamId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    ShiftStatus? status,
    ShiftType? type,
    String? location,
    String? description,
    double? breakDurationMinutes,
    double? hourlyRate,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      teamId: teamId ?? this.teamId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      breakDurationMinutes:
          breakDurationMinutes ?? this.breakDurationMinutes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Shift && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Shift(id: $id, employee: $employeeId, start: $startTime, status: ${status.name})';
}
