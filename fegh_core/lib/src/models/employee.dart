/// Beschaeftigungs-Status eines Mitarbeiters.
enum EmployeeStatus { active, inactive, onLeave, terminated }

/// Vertragsart.
enum ContractType { fullTime, partTime, freelance, intern, temporary }

/// Fachlicher Bereich (aus FEGH-Dokumentation uebernommen).
enum MitarbeiterBereich {
  eingliederungshilfe,
  familienhilfe,
  jugendhilfe,
  sozialhilfe,
  betreuung,
  verwaltung,
}

extension EmployeeStatusDisplay on EmployeeStatus {
  String get displayName {
    switch (this) {
      case EmployeeStatus.active:
        return 'Aktiv';
      case EmployeeStatus.inactive:
        return 'Inaktiv';
      case EmployeeStatus.onLeave:
        return 'Beurlaubt';
      case EmployeeStatus.terminated:
        return 'Beendet';
    }
  }
}

extension ContractTypeDisplay on ContractType {
  String get displayName {
    switch (this) {
      case ContractType.fullTime:
        return 'Vollzeit';
      case ContractType.partTime:
        return 'Teilzeit';
      case ContractType.freelance:
        return 'Freiberuflich';
      case ContractType.intern:
        return 'Praktikum';
      case ContractType.temporary:
        return 'Befristet';
    }
  }
}

extension MitarbeiterBereichDisplay on MitarbeiterBereich {
  String get wireValue => name;

  String get displayName {
    switch (this) {
      case MitarbeiterBereich.eingliederungshilfe:
        return 'Eingliederungshilfe';
      case MitarbeiterBereich.familienhilfe:
        return 'Familienhilfe';
      case MitarbeiterBereich.jugendhilfe:
        return 'Jugendhilfe';
      case MitarbeiterBereich.sozialhilfe:
        return 'Sozialhilfe';
      case MitarbeiterBereich.betreuung:
        return 'Betreuung';
      case MitarbeiterBereich.verwaltung:
        return 'Verwaltung';
    }
  }
}

/// Vereintes Mitarbeiter-/Employee-Modell.
///
/// Basis ist die strukturierte Verwaltungs-Form (HR-Felder wie
/// `employeeNumber`, `position`, `department`, `contractType`,
/// `hoursPerWeek`, `hourlyRate`, `supervisor`, `address`, `emergencyContact`,
/// `qualifications`, `hireDate`, `terminationDate`). Hinzugekommen aus
/// der Doku-App: `teamIds`, `teamNummer`, `bereich`
/// ([MitarbeiterBereich]), `urlaubstage`.
///
/// `fromJson` akzeptiert sowohl Verwaltungs- als auch Legacy-Doku-
/// Felder (`name` = lastName, `vorname` = firstName, `telefon` = phone,
/// `wochenarbeitszeit` = hoursPerWeek, `isActive` = status=active).
class Employee {
  final String id;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final DateTime? hireDate;
  final DateTime? terminationDate;
  final EmployeeStatus status;
  final ContractType? contractType;
  final double hoursPerWeek;
  final double hourlyRate;
  final String position;
  final String department;
  final String? supervisor;
  final Address? address;
  final EmergencyContact? emergencyContact;
  final List<String> qualifications;
  final String? notes;

  // Doku-Felder (aus FEGH-Dokumentation uebernommen)
  final int? teamNummer;
  final List<String> teamIds;
  final MitarbeiterBereich? bereich;
  final int urlaubstage;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.employeeNumber = '',
    this.phone,
    this.dateOfBirth,
    this.hireDate,
    this.terminationDate,
    this.status = EmployeeStatus.active,
    this.contractType,
    this.hoursPerWeek = 40,
    this.hourlyRate = 0,
    this.position = '',
    this.department = '',
    this.supervisor,
    this.address,
    this.emergencyContact,
    this.qualifications = const [],
    this.notes,
    this.teamNummer,
    this.teamIds = const [],
    this.bereich,
    this.urlaubstage = 30,
  });

  /// Factory mit auto-generierter ID + Zeitstempeln. Akzeptiert
  /// sowohl die neuen als auch die alten Doku-Feldnamen.
  factory Employee.create({
    String? firstName,
    String? lastName,
    // Legacy-Doku-Aliase
    String? name, // = lastName
    String? vorname, // = firstName
    String? telefon, // = phone
    double? wochenarbeitszeit, // = hoursPerWeek
    // Rest
    required String email,
    String employeeNumber = '',
    String? phone,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    DateTime? terminationDate,
    EmployeeStatus status = EmployeeStatus.active,
    ContractType? contractType,
    double? hoursPerWeek,
    double hourlyRate = 0,
    String position = '',
    String department = '',
    String? supervisor,
    Address? address,
    EmergencyContact? emergencyContact,
    List<String> qualifications = const [],
    String? notes,
    int? teamNummer,
    List<String> teamIds = const [],
    MitarbeiterBereich? bereich,
    int urlaubstage = 30,
    bool? isActive,
  }) {
    final resolvedFirst = firstName ?? vorname ?? '';
    final resolvedLast = lastName ?? name ?? '';
    final resolvedStatus = isActive != null
        ? (isActive ? EmployeeStatus.active : EmployeeStatus.inactive)
        : status;
    final now = DateTime.now();
    return Employee(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: resolvedFirst,
      lastName: resolvedLast,
      email: email,
      createdAt: now,
      updatedAt: now,
      employeeNumber: employeeNumber,
      phone: phone ?? telefon,
      dateOfBirth: dateOfBirth,
      hireDate: hireDate,
      terminationDate: terminationDate,
      status: resolvedStatus,
      contractType: contractType,
      hoursPerWeek: hoursPerWeek ?? wochenarbeitszeit ?? 40,
      hourlyRate: hourlyRate,
      position: position,
      department: department,
      supervisor: supervisor,
      address: address,
      emergencyContact: emergencyContact,
      qualifications: qualifications,
      notes: notes,
      teamNummer: teamNummer,
      teamIds: teamIds,
      bereich: bereich,
      urlaubstage: urlaubstage,
    );
  }

  // ── Getter + Legacy-Alias ─────────────────────────────────────────

  String get fullName => '$firstName $lastName'.trim();

  /// "Nachname, Vorname" (Admin-Listen).
  String get displayName => '$lastName, $firstName';

  /// Kompatibilitaet Doku-API: `vollstaendigerName`.
  String get vollstaendigerName => fullName;

  /// Doku-Legacy: `vorname`.
  String get vorname => firstName;

  /// Doku-Legacy: `name` = lastName.
  String get name => lastName;

  /// Doku-Legacy: `telefon`.
  String get telefon => phone ?? '';

  /// Doku-Legacy: `wochenarbeitszeit`.
  double get wochenarbeitszeit => hoursPerWeek;

  /// Doku-Legacy: `isActive`.
  bool get isActive => status == EmployeeStatus.active;

  /// Doku-Legacy: `bereichDisplayName`.
  String get bereichDisplayName => bereich?.displayName ?? '';

  String get statusLabel => status.displayName;

  double get contractualHours => hoursPerWeek;

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  Duration? get employmentDuration {
    if (hireDate == null) return null;
    final endDate = terminationDate ?? DateTime.now();
    return endDate.difference(hireDate!);
  }

  // ── (De)Serialisierung ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'employeeNumber': employeeNumber,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
        if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
        if (terminationDate != null)
          'terminationDate': terminationDate!.toIso8601String(),
        'status': status.name,
        if (contractType != null) 'contractType': contractType!.name,
        'hoursPerWeek': hoursPerWeek,
        'hourlyRate': hourlyRate,
        'position': position,
        'department': department,
        if (supervisor != null) 'supervisor': supervisor,
        if (address != null) 'address': address!.toJson(),
        if (emergencyContact != null)
          'emergencyContact': emergencyContact!.toJson(),
        'qualifications': qualifications,
        if (notes != null) 'notes': notes,
        if (teamNummer != null) 'teamNummer': teamNummer,
        'teamIds': teamIds,
        if (bereich != null) 'bereich': bereich!.wireValue,
        'urlaubstage': urlaubstage,
        // Doku-Legacy-Aliase (bidirektionale Lesbarkeit)
        'vorname': firstName,
        'name': lastName,
        if (phone != null) 'telefon': phone,
        'wochenarbeitszeit': hoursPerWeek,
        'isActive': status == EmployeeStatus.active,
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    final first = (json['firstName'] as String?) ??
        (json['vorname'] as String?) ??
        '';
    final last =
        (json['lastName'] as String?) ?? (json['name'] as String?) ?? '';
    final phoneVal =
        (json['phone'] as String?) ?? (json['telefon'] as String?);
    final hours = (json['hoursPerWeek'] as num?)?.toDouble() ??
        (json['wochenarbeitszeit'] as num?)?.toDouble() ??
        40;
    EmployeeStatus status = EmployeeStatus.active;
    final statusRaw = json['status'];
    if (statusRaw is String) {
      for (final s in EmployeeStatus.values) {
        if (s.name == statusRaw) {
          status = s;
          break;
        }
      }
    } else if (json['isActive'] == false) {
      status = EmployeeStatus.inactive;
    }
    final now = DateTime.now();
    return Employee(
      id: json['id'] as String,
      firstName: first,
      lastName: last,
      email: (json['email'] as String?) ?? '',
      createdAt: _parseDate(json['createdAt']) ?? now,
      updatedAt: _parseDate(json['updatedAt']) ?? now,
      employeeNumber: (json['employeeNumber'] as String?) ?? '',
      phone: phoneVal,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      hireDate: _parseDate(json['hireDate']),
      terminationDate: _parseDate(json['terminationDate']),
      status: status,
      contractType: _parseContractType(json['contractType']),
      hoursPerWeek: hours,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      position: (json['position'] as String?) ?? '',
      department: (json['department'] as String?) ?? '',
      supervisor: json['supervisor'] as String?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContact.fromJson(
              json['emergencyContact'] as Map<String, dynamic>)
          : null,
      qualifications: (json['qualifications'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      teamNummer: json['teamNummer'] as int?,
      teamIds:
          (json['teamIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      bereich: _parseBereich(json['bereich']),
      urlaubstage: json['urlaubstage'] as int? ?? 30,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.parse(v);
    return null;
  }

  static ContractType? _parseContractType(dynamic raw) {
    if (raw is String) {
      for (final c in ContractType.values) {
        if (c.name == raw) return c;
      }
    }
    return null;
  }

  static MitarbeiterBereich? _parseBereich(dynamic raw) {
    if (raw is String) {
      for (final b in MitarbeiterBereich.values) {
        if (b.name == raw) return b;
      }
    }
    return null;
  }

  // ── copyWith ─────────────────────────────────────────────────────

  Employee copyWith({
    String? firstName,
    String? lastName,
    // Legacy-Doku-Alias
    String? name,
    String? vorname,
    String? telefon,
    double? wochenarbeitszeit,
    bool? isActive,
    // Rest
    String? email,
    String? phone,
    String? employeeNumber,
    DateTime? dateOfBirth,
    DateTime? hireDate,
    DateTime? terminationDate,
    EmployeeStatus? status,
    ContractType? contractType,
    double? hoursPerWeek,
    double? hourlyRate,
    String? position,
    String? department,
    String? supervisor,
    // (continue unchanged)
    Address? address,
    EmergencyContact? emergencyContact,
    List<String>? qualifications,
    String? notes,
    int? teamNummer,
    List<String>? teamIds,
    MitarbeiterBereich? bereich,
    int? urlaubstage,
    DateTime? updatedAt,
  }) {
    final resolvedFirst = firstName ?? vorname ?? this.firstName;
    final resolvedLast = lastName ?? name ?? this.lastName;
    final resolvedPhone = phone ?? telefon ?? this.phone;
    final resolvedHours = hoursPerWeek ?? wochenarbeitszeit ?? this.hoursPerWeek;
    final resolvedStatus = status ??
        (isActive == null
            ? this.status
            : (isActive ? EmployeeStatus.active : EmployeeStatus.inactive));
    return Employee(
      id: id,
      firstName: resolvedFirst,
      lastName: resolvedLast,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      employeeNumber: employeeNumber ?? this.employeeNumber,
      phone: resolvedPhone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      status: resolvedStatus,
      contractType: contractType ?? this.contractType,
      hoursPerWeek: resolvedHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      position: position ?? this.position,
      department: department ?? this.department,
      supervisor: supervisor ?? this.supervisor,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      qualifications: qualifications ?? this.qualifications,
      notes: notes ?? this.notes,
      teamNummer: teamNummer ?? this.teamNummer,
      teamIds: teamIds ?? this.teamIds,
      bereich: bereich ?? this.bereich,
      urlaubstage: urlaubstage ?? this.urlaubstage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Employee && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Employee(id: $id, name: $fullName, status: ${status.name})';
}

/// Typedef-Alias fuer die Doku-App: `Mitarbeiter = Employee`.
typedef Mitarbeiter = Employee;

/// Adresse (Admin-Struktur).
class Address {
  final String street;
  final String city;
  final String postalCode;
  final String? state;
  final String country;

  const Address({
    required this.street,
    required this.city,
    required this.postalCode,
    this.state,
    this.country = 'DE',
  });

  String get fullAddress {
    final parts = [street, '$postalCode $city'];
    if (state != null) parts.add(state!);
    parts.add(country);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'postalCode': postalCode,
        if (state != null) 'state': state,
        'country': country,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: (json['street'] as String?) ?? '',
        city: (json['city'] as String?) ?? '',
        postalCode: (json['postalCode'] as String?) ?? '',
        state: json['state'] as String?,
        country: (json['country'] as String?) ?? 'DE',
      );

  @override
  String toString() => fullAddress;
}

/// Notfallkontakt.
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String? email;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        if (email != null) 'email': email,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: (json['name'] as String?) ?? '',
        relationship: (json['relationship'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        email: json['email'] as String?,
      );
}
