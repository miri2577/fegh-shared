/// Cloud-Storage-Abstraktion fuer FEGH-Dokumentation und FEGH-Verwaltung.
///
/// Einheitliche API ueber WebDAV-Provider:
///   - STRATO HiDrive (HidriveAdapter)
///   - Nextcloud (NextcloudAdapter, Phase 2)
///   - ownCloud (OwncloudAdapter, Phase 2)
///   - Generic WebDAV (GenericWebdavAdapter, Phase 2)
///
/// Basiert auf dem gepflegten `webdav_client`-Package; STRATO-Quirks
/// (MKCOL-Content-Type, etc.) werden dort korrekt behandelt.
library;

export 'src/cloud_adapter.dart';
export 'src/fegh_paths.dart';
export 'src/result.dart';
export 'src/adapters/hidrive_adapter.dart';
export 'src/adapters/nextcloud_adapter.dart';
export 'src/adapters/owncloud_adapter.dart';
export 'src/adapters/generic_webdav_adapter.dart';
