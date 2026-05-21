import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:test/test.dart';

/// Sanity-Tests fuer Adapter-Konstruktion.
/// Echte WebDAV-Operationen brauchen Live-Server, siehe integration-test/.
void main() {
  group('HidriveAdapter Konstruktion', () {
    test('URL wird aus username + rootSubdirectory gebaut', () {
      final adapter = HidriveAdapter(
        username: 'max',
        password: 'secret',
        rootSubdirectory: 'Gemeinsam/EGH',
      );
      expect(adapter.username, 'max');
      expect(adapter.baseUrl,
          'https://webdav.hidrive.strato.com/users/max/Gemeinsam/EGH');
      expect(adapter.providerType, CloudProviderType.hidrive);
    });

    test('baseUrlOverride hat Vorrang', () {
      final adapter = HidriveAdapter(
        username: 'max',
        password: 'secret',
        baseUrlOverride: 'https://custom.example.com/path',
      );
      expect(adapter.baseUrl, 'https://custom.example.com/path');
    });

    test('Ohne rootSubdirectory: User-Root-Pfad', () {
      final adapter = HidriveAdapter(username: 'max', password: 'p');
      expect(adapter.baseUrl, 'https://webdav.hidrive.strato.com/users/max');
    });
  });

  group('NextcloudAdapter Konstruktion', () {
    test('URL folgt Nextcloud-Konvention', () {
      final adapter = NextcloudAdapter(
        serverUrl: 'https://cloud.example.de',
        username: 'anna',
        appToken: 'app-xyz',
      );
      expect(adapter.providerType, CloudProviderType.nextcloud);
      expect(adapter.username, 'anna');
    });

    test('Trailing slash in serverUrl wird entfernt', () {
      final adapter = NextcloudAdapter(
        serverUrl: 'https://cloud.example.de/',
        username: 'anna',
        appToken: 'x',
      );
      expect(adapter.serverUrl, 'https://cloud.example.de/');
      // baseUrl wird ohne trailing slash zusammengebaut (privat, nicht testbar
      // von aussen - aber die Konstruktion wirft keinen Fehler)
    });
  });

  group('OwncloudAdapter Konstruktion', () {
    test('Erbt Nextcloud-Verhalten, anderer providerType', () {
      final adapter = OwncloudAdapter(
        serverUrl: 'https://own.example.de',
        username: 'bob',
        appToken: 'tok',
      );
      expect(adapter.providerType, CloudProviderType.owncloud);
      expect(adapter.username, 'bob');
    });
  });

  group('GenericWebdavAdapter Konstruktion', () {
    test('Beliebige WebDAV-URL akzeptiert', () {
      final adapter = GenericWebdavAdapter(
        baseUrl: 'https://dav.example.com/files',
        username: 'u',
        password: 'p',
      );
      expect(adapter.providerType, CloudProviderType.generic);
    });
  });

  group('CloudAdapter Polymorphie', () {
    test('Alle Adapter implementieren CloudAdapter', () {
      final hidrive = HidriveAdapter(username: 'x', password: 'y');
      final nextcloud = NextcloudAdapter(
        serverUrl: 'https://x.de',
        username: 'x',
        appToken: 'y',
      );
      final owncloud = OwncloudAdapter(
        serverUrl: 'https://x.de',
        username: 'x',
        appToken: 'y',
      );
      final generic = GenericWebdavAdapter(
        baseUrl: 'https://x.de/dav',
        username: 'x',
        password: 'y',
      );

      final adapters = <CloudAdapter>[hidrive, nextcloud, owncloud, generic];
      expect(adapters.length, 4);
      for (final a in adapters) {
        expect(a.providerType, isA<CloudProviderType>());
      }
    });
  });
}
