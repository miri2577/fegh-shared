import 'package:flutter_test/flutter_test.dart';
import 'package:fegh_compliance/fegh_compliance.dart';

/// Tests pruefen die oeffentliche API-Stabilitaet des AuditLoggers.
/// Datei-I/O wird nicht integriert getestet (braucht
/// TestWidgetsFlutterBinding + tmpDir); in der App selbst wird es
/// durch die Plattform getestet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuditLogger Singleton', () {
    test('instance liefert Singleton', () {
      final a = AuditLogger.instance;
      final b = AuditLogger.instance;
      expect(identical(a, b), isTrue);
    });

    test('Vordefinierte Methoden existieren', () {
      final l = AuditLogger.instance;
      expect(l.logClientAccess, isA<Function>());
      expect(l.logClientCreate, isA<Function>());
      expect(l.logLogin, isA<Function>());
      expect(l.logRoleChange, isA<Function>());
      expect(l.logRechnungErstellt, isA<Function>());
      expect(l.logRechnungStorniert, isA<Function>());
    });
  });
}
