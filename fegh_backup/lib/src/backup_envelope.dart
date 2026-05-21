import 'dart:convert';

/// Metadaten eines Backup-Envelopes.
class BackupMetadata {
  final String backupId;
  final DateTime createdAt;
  final String deviceName;
  final String appVersion;
  final String dataVersion;

  const BackupMetadata({
    required this.backupId,
    required this.createdAt,
    required this.deviceName,
    required this.appVersion,
    required this.dataVersion,
  });

  /// Erstellt Metadaten mit automatisch erzeugter ID (ms since epoch)
  /// und aktueller Zeit.
  factory BackupMetadata.create({
    required String deviceName,
    required String appVersion,
    required String dataVersion,
  }) {
    return BackupMetadata(
      backupId: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      deviceName: deviceName,
      appVersion: appVersion,
      dataVersion: dataVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'backupId': backupId,
        'createdAt': createdAt.toIso8601String(),
        'deviceName': deviceName,
        'appVersion': appVersion,
        'dataVersion': dataVersion,
      };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
        backupId: json['backupId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deviceName: json['deviceName'] as String,
        appVersion: json['appVersion'] as String,
        dataVersion: json['dataVersion'] as String,
      );
}

/// Generischer Backup-Container. App-spezifische Inhalte liegen als
/// `Map<String, dynamic>` in [payload].
///
/// Die App kapselt ihre typisierten Datenmodelle in dieses Envelope:
///
/// ```dart
/// final env = BackupEnvelope(
///   metadata: BackupMetadata.create(
///     deviceName: 'Windows', appVersion: '1.0.0', dataVersion: '2.1.0'),
///   payload: {
///     'clients': clients.map((c) => c.toJson()).toList(),
///     'appointments': appointments.map((a) => a.toJson()).toList(),
///   },
/// );
/// final json = jsonEncode(env.toJson());
/// final bytes = await BackupCodec.encrypt(json, password);
/// ```
class BackupEnvelope {
  final BackupMetadata metadata;
  final Map<String, dynamic> payload;

  const BackupEnvelope({required this.metadata, required this.payload});

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'payload': payload,
      };

  factory BackupEnvelope.fromJson(Map<String, dynamic> json) => BackupEnvelope(
        metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
        payload: (json['payload'] as Map).cast<String, dynamic>(),
      );

  String encodeJson() => jsonEncode(toJson());

  static BackupEnvelope decodeJson(String json) =>
      BackupEnvelope.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

/// Kurz-Info fuer Backup-Listen (ohne Payload-Laden).
class BackupInfo {
  final String id;
  final String filename;
  final DateTime createdAt;
  final String deviceName;
  final bool isEncrypted;
  final int fileSizeBytes;

  const BackupInfo({
    required this.id,
    required this.filename,
    required this.createdAt,
    required this.deviceName,
    required this.isEncrypted,
    required this.fileSizeBytes,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'createdAt': createdAt.toIso8601String(),
        'deviceName': deviceName,
        'isEncrypted': isEncrypted,
        'fileSizeBytes': fileSizeBytes,
      };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
        id: json['id'] as String,
        filename: json['filename'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deviceName: json['deviceName'] as String,
        isEncrypted: json['isEncrypted'] as bool,
        fileSizeBytes: json['fileSizeBytes'] as int,
      );
}
