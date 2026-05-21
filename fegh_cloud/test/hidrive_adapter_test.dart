import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:test/test.dart';

/// Minimaler Mock-WebDAV-Server fuer Adapter-Tests.
/// Laeuft auf localhost:{dynamic-port} und simuliert STRATO-Verhalten
/// (z.B. MKCOL 415 wenn Content-Type octet-stream).
class MockWebdavServer {
  late HttpServer _server;
  final Map<String, Uint8List> files = {};
  final Set<String> dirs = {'/'};

  /// Ob der Mock das STRATO-MKCOL-Verhalten imitiert (415 bei falschem
  /// Content-Type). Wenn true → Test soll pruefen dass der Adapter
  /// den Content-Type nicht falsch setzt.
  bool stratoStrict = false;

  Future<int> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
    return _server.port;
  }

  Future<void> stop() async {
    await _server.close();
  }

  Future<void> _handle(HttpRequest req) async {
    final method = req.method;
    final path = req.uri.path;
    final resp = req.response;

    // Auth-Check
    final auth = req.headers.value('authorization') ?? '';
    if (!auth.startsWith('Basic ')) {
      resp.statusCode = 401;
      await resp.close();
      return;
    }

    switch (method) {
      case 'MKCOL':
        if (stratoStrict) {
          final ct = req.headers.contentType?.toString() ?? '';
          if (ct.contains('application/octet-stream')) {
            resp.statusCode = 415;
            await resp.close();
            return;
          }
        }
        if (dirs.contains(path)) {
          resp.statusCode = 405; // already exists
        } else {
          dirs.add(path);
          resp.statusCode = 201;
        }
        await resp.close();
        break;

      case 'PUT':
        final bytes = await _collect(req);
        files[path] = bytes;
        resp.statusCode = 201;
        await resp.close();
        break;

      case 'GET':
        final bytes = files[path];
        if (bytes == null) {
          resp.statusCode = 404;
          await resp.close();
          return;
        }
        resp.statusCode = 200;
        resp.add(bytes);
        await resp.close();
        break;

      case 'DELETE':
        files.remove(path);
        dirs.remove(path);
        resp.statusCode = 204;
        await resp.close();
        break;

      case 'PROPFIND':
        if (!dirs.contains(path) && !dirs.contains('$path/')) {
          resp.statusCode = 404;
          await resp.close();
          return;
        }
        final children = <String>{};
        for (final f in files.keys) {
          if (f.startsWith(path) && f != path) {
            final rest = f.substring(path.length);
            final nextSlash = rest.indexOf('/');
            final name = nextSlash == -1 ? rest : rest.substring(0, nextSlash);
            if (name.isNotEmpty) children.add('file:$name');
          }
        }
        for (final d in dirs) {
          if (d.startsWith(path) && d != path) {
            final rest = d.substring(path.length);
            final nextSlash = rest.indexOf('/');
            final name = nextSlash == -1 ? rest : rest.substring(0, nextSlash);
            if (name.isNotEmpty) children.add('dir:$name');
          }
        }

        resp.statusCode = 207;
        resp.headers.contentType = ContentType('application', 'xml');
        final xml = _buildPropfindResponse(path, children);
        resp.write(xml);
        await resp.close();
        break;

      case 'OPTIONS':
        resp.statusCode = 200;
        resp.headers.set('DAV', '1, 2');
        await resp.close();
        break;

      default:
        resp.statusCode = 405;
        await resp.close();
    }
  }

  Future<Uint8List> _collect(HttpRequest req) async {
    final builder = BytesBuilder();
    await for (final chunk in req) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  String _buildPropfindResponse(String basePath, Set<String> children) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buf.writeln('<D:multistatus xmlns:D="DAV:">');
    buf.writeln('  <D:response>');
    buf.writeln('    <D:href>$basePath</D:href>');
    buf.writeln('    <D:propstat><D:prop>');
    buf.writeln('      <D:resourcetype><D:collection/></D:resourcetype>');
    buf.writeln('      <D:displayname>${basePath.split("/").last}</D:displayname>');
    buf.writeln('    </D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat>');
    buf.writeln('  </D:response>');
    for (final c in children) {
      final isDir = c.startsWith('dir:');
      final name = c.substring(4);
      final childPath = basePath.endsWith('/') ? '$basePath$name' : '$basePath/$name';
      buf.writeln('  <D:response>');
      buf.writeln('    <D:href>$childPath${isDir ? "/" : ""}</D:href>');
      buf.writeln('    <D:propstat><D:prop>');
      buf.writeln('      <D:displayname>$name</D:displayname>');
      if (isDir) {
        buf.writeln('      <D:resourcetype><D:collection/></D:resourcetype>');
      } else {
        buf.writeln('      <D:resourcetype/>');
        buf.writeln('      <D:getcontentlength>0</D:getcontentlength>');
      }
      buf.writeln('    </D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat>');
      buf.writeln('  </D:response>');
    }
    buf.writeln('</D:multistatus>');
    return buf.toString();
  }
}

/// HidriveAdapter gegen einen Mock laufen lassen — statt
/// HiDrive-URL wird localhost genutzt.
class _MockHidriveAdapter extends HidriveAdapter {
  _MockHidriveAdapter({required super.username, required super.password, required int port})
      : _port = port,
        super();

  final int _port;

  // Override der Base-URL via Vererbung nicht trivial moeglich -
  // stattdessen: erlaubt der Test direkte Client-Interaktion.
  // Fuer den Mock-Test baut der Test selbst einen webdav-Client.
}

void main() {
  group('HidriveAdapter (Mock-Server)', () {
    late MockWebdavServer server;
    late int port;

    setUp(() async {
      server = MockWebdavServer();
      port = await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('Mock-Server akzeptiert Basic Auth', () async {
      final resp = await HttpClient()
          .openUrl('OPTIONS', Uri.parse('http://localhost:$port/'))
          .then((req) {
        req.headers.set(HttpHeaders.authorizationHeader,
            'Basic ${base64Encode(utf8.encode("u:p"))}');
        return req.close();
      });
      expect(resp.statusCode, 200);
    });

    test('Mock-Server STRATO-Strict: MKCOL 415 bei octet-stream', () async {
      server.stratoStrict = true;
      final client = HttpClient();
      final req = await client.openUrl(
          'MKCOL', Uri.parse('http://localhost:$port/testdir/'));
      req.headers.set(HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode("u:p"))}');
      req.headers.contentType = ContentType('application', 'octet-stream');
      final resp = await req.close();
      expect(resp.statusCode, 415);
    });
  });

  group('CloudResult', () {
    test('Success enthaelt Daten', () {
      final r = CloudResult<int>.success(42);
      expect(r.isSuccess, true);
      expect(r.data, 42);
      expect(r.error, null);
    });

    test('Failure enthaelt Fehler + Status', () {
      final r = CloudResult<int>.failure('nope', statusCode: 404);
      expect(r.isSuccess, false);
      expect(r.data, null);
      expect(r.error, 'nope');
      expect(r.statusCode, 404);
    });
  });

  group('CloudEntry', () {
    test('Datei-Entry', () {
      final e = CloudEntry(
        name: 'test.bin',
        path: '/a/test.bin',
        isDirectory: false,
        size: 123,
      );
      expect(e.name, 'test.bin');
      expect(e.isDirectory, false);
      expect(e.size, 123);
    });
  });
}
