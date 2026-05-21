/// Lebensphase eines Teams.
enum TeamStatus { active, inactive, onHold }

extension TeamStatusDisplay on TeamStatus {
  String get displayName {
    switch (this) {
      case TeamStatus.active:
        return 'Aktiv';
      case TeamStatus.inactive:
        return 'Inaktiv';
      case TeamStatus.onHold:
        return 'Pausiert';
    }
  }
}

/// Team (Organisationseinheit): bindet Mitarbeiter und Klienten
/// zusammen. Basis der rollenbasierten Sichtbarkeit.
///
/// Vereint die Doku- und Verwaltungs-Team-Modelle. `clientIds` kommt
/// aus der Doku (wer ist im Team zugewiesen), `budget`/`notes` aus
/// der Verwaltung.
class Team {
  final String id;
  final String name;
  final String description;
  final String? department;
  final String? location;
  final String? teamLeaderId;
  final List<String> memberIds;
  final List<String> clientIds;
  final TeamStatus status;
  final double? budget;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.name,
    this.description = '',
    this.department,
    this.location,
    this.teamLeaderId,
    this.memberIds = const [],
    this.clientIds = const [],
    this.status = TeamStatus.active,
    this.budget,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory mit auto-ID + Zeitstempeln.
  factory Team.create({
    required String name,
    String description = '',
    String? department,
    String? location,
    String? teamLeaderId,
    List<String> memberIds = const [],
    List<String> clientIds = const [],
    TeamStatus status = TeamStatus.active,
    double? budget,
    String? notes,
  }) {
    final now = DateTime.now();
    return Team(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      department: department,
      location: location,
      teamLeaderId: teamLeaderId,
      memberIds: memberIds,
      clientIds: clientIds,
      status: status,
      budget: budget,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ── Getter ────────────────────────────────────────────────────────

  int get memberCount => memberIds.length;
  int get clientCount => clientIds.length;
  bool get hasTeamLeader => teamLeaderId != null;
  bool get isActive => status == TeamStatus.active;
  String get statusDisplayName => status.displayName;

  // ── Mitglieder/Klienten-Aenderungen ──────────────────────────────

  Team addMember(String employeeId) {
    if (memberIds.contains(employeeId)) return this;
    return copyWith(memberIds: [...memberIds, employeeId]);
  }

  Team removeMember(String employeeId) {
    return copyWith(
      memberIds: memberIds.where((id) => id != employeeId).toList(),
    );
  }

  Team addClient(String clientId) {
    if (clientIds.contains(clientId)) return this;
    return copyWith(clientIds: [...clientIds, clientId]);
  }

  Team removeClient(String clientId) {
    return copyWith(
      clientIds: clientIds.where((id) => id != clientId).toList(),
    );
  }

  // ── (De)Serialisierung ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'department': department,
        'location': location,
        'teamLeaderId': teamLeaderId,
        'memberIds': memberIds,
        'clientIds': clientIds,
        'status': status.name,
        if (budget != null) 'budget': budget,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) {
    TeamStatus status = TeamStatus.active;
    final s = json['status'];
    if (s is String) {
      for (final t in TeamStatus.values) {
        if (t.name == s) {
          status = t;
          break;
        }
      }
    }
    final now = DateTime.now();
    return Team(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      department: json['department'] as String?,
      location: json['location'] as String?,
      teamLeaderId: json['teamLeaderId'] as String?,
      memberIds:
          (json['memberIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      clientIds:
          (json['clientIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      status: status,
      budget: (json['budget'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? department,
    String? location,
    String? teamLeaderId,
    List<String>? memberIds,
    List<String>? clientIds,
    TeamStatus? status,
    double? budget,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      location: location ?? this.location,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      memberIds: memberIds ?? this.memberIds,
      clientIds: clientIds ?? this.clientIds,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Team && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, members: $memberCount)';
}
