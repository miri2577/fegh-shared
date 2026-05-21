import '../cloud_adapter.dart';
import '../result.dart';
import 'nextcloud_adapter.dart';

/// Adapter fuer ownCloud via WebDAV.
///
/// ownCloud und Nextcloud haben gemeinsame Wurzeln und identisches
/// WebDAV-URL-Schema:
/// ```
/// https://{host}/remote.php/dav/files/{username}/
/// ```
///
/// Deshalb erbt OwncloudAdapter von NextcloudAdapter. Der einzige
/// Unterschied ist der [providerType], der fuer Telemetrie/Logging
/// relevant sein kann.
class OwncloudAdapter extends NextcloudAdapter {
  OwncloudAdapter({
    required super.serverUrl,
    required super.username,
    required super.appToken,
    super.rootSubdirectory,
  });

  @override
  CloudProviderType get providerType => CloudProviderType.owncloud;
}
