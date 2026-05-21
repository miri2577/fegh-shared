import 'package:fegh_core/fegh_core.dart';
import 'package:test/test.dart';

void main() {
  group('Employee — Basis', () {
    test('fullName + displayName + Legacy-Getter', () {
      final e = Employee(
        id: 'e1',
        firstName: 'Anna',
        lastName: 'Schmidt',
        email: 'anna@example.de',
        phone: '030-123456',
        hoursPerWeek: 32,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 4, 19),
      );
      expect(e.fullName, 'Anna Schmidt');
      expect(e.displayName, 'Schmidt, Anna');
      expect(e.vollstaendigerName, 'Anna Schmidt');
      expect(e.vorname, 'Anna');
      expect(e.name, 'Schmidt');
      expect(e.telefon, '030-123456');
      expect(e.wochenarbeitszeit, 32);
      expect(e.isActive, isTrue);
    });

    test('age aus Geburtsdatum, null ohne', () {
      final e = Employee(
        id: 'e',
        firstName: 'X',
        lastName: 'Y',
        email: 'x@y.de',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(e.age, isNull);
    });
  });

  group('Employee.create — Legacy-Aliase', () {
    test('name/vorname/telefon werden auf lastName/firstName/phone gemappt', () {
      final e = Employee.create(
        vorname: 'Max',
        name: 'Mustermann',
        telefon: '0170-555',
        email: 'max@firma.de',
        wochenarbeitszeit: 30,
        bereich: MitarbeiterBereich.eingliederungshilfe,
        teamIds: const ['team-a'],
        teamNummer: 1,
      );
      expect(e.firstName, 'Max');
      expect(e.lastName, 'Mustermann');
      expect(e.phone, '0170-555');
      expect(e.hoursPerWeek, 30);
      expect(e.bereich, MitarbeiterBereich.eingliederungshilfe);
      expect(e.teamIds, ['team-a']);
      expect(e.teamNummer, 1);
    });

    test('isActive=false → status=inactive', () {
      final e = Employee.create(
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.de',
        isActive: false,
      );
      expect(e.status, EmployeeStatus.inactive);
    });
  });

  group('Employee — JSON roundtrip', () {
    test('toJson enthaelt neue + Legacy-Felder', () {
      final e = Employee(
        id: 'e1',
        firstName: 'Anna',
        lastName: 'Schmidt',
        email: 'anna@example.de',
        phone: '030-123456',
        hoursPerWeek: 32,
        bereich: MitarbeiterBereich.eingliederungshilfe,
        teamIds: const ['team-a'],
        teamNummer: 1,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 4, 19),
      );
      final j = e.toJson();
      expect(j['firstName'], 'Anna');
      expect(j['lastName'], 'Schmidt');
      expect(j['vorname'], 'Anna');
      expect(j['name'], 'Schmidt');
      expect(j['telefon'], '030-123456');
      expect(j['wochenarbeitszeit'], 32);
      expect(j['bereich'], 'eingliederungshilfe');
      expect(j['isActive'], isTrue);
    });

    test('Legacy-Doku-JSON (vorname/name/telefon/wochenarbeitszeit)', () {
      final j = {
        'id': 'm-1',
        'vorname': 'Maria',
        'name': 'Klein',
        'email': 'maria.klein@traeger.de',
        'telefon': '030-999',
        'wochenarbeitszeit': 39.5,
        'bereich': 'familienhilfe',
        'urlaubstage': 28,
        'teamIds': ['team-b', 'team-c'],
        'teamNummer': 2,
        'isActive': true,
        'createdAt': '2025-12-01T10:00:00.000',
        'updatedAt': '2026-04-10T10:00:00.000',
      };
      final e = Employee.fromJson(j);
      expect(e.firstName, 'Maria');
      expect(e.lastName, 'Klein');
      expect(e.phone, '030-999');
      expect(e.hoursPerWeek, 39.5);
      expect(e.bereich, MitarbeiterBereich.familienhilfe);
      expect(e.urlaubstage, 28);
      expect(e.teamIds, ['team-b', 'team-c']);
      expect(e.status, EmployeeStatus.active);
    });

    test('Verwaltungs-JSON mit address + emergencyContact', () {
      final j = {
        'id': 'v-1',
        'firstName': 'Peter',
        'lastName': 'Parker',
        'email': 'pp@fegh.de',
        'employeeNumber': 'EMP-042',
        'hoursPerWeek': 40,
        'hourlyRate': 19.5,
        'status': 'active',
        'contractType': 'fullTime',
        'address': {
          'street': 'Hauptstrasse 5',
          'city': 'Berlin',
          'postalCode': '10115',
          'country': 'DE',
        },
        'emergencyContact': {
          'name': 'Mary Parker',
          'relationship': 'Tante',
          'phone': '0175-555',
        },
        'createdAt': '2026-01-10T00:00:00.000',
        'updatedAt': '2026-04-15T00:00:00.000',
      };
      final e = Employee.fromJson(j);
      expect(e.employeeNumber, 'EMP-042');
      expect(e.contractType, ContractType.fullTime);
      expect(e.address?.city, 'Berlin');
      expect(e.emergencyContact?.name, 'Mary Parker');
    });
  });

  group('MitarbeiterBereich', () {
    test('displayName', () {
      expect(MitarbeiterBereich.eingliederungshilfe.displayName,
          'Eingliederungshilfe');
      expect(MitarbeiterBereich.jugendhilfe.displayName, 'Jugendhilfe');
    });
  });

  group('Address', () {
    test('fullAddress-Format', () {
      const a = Address(
        street: 'Unter den Linden 1',
        city: 'Berlin',
        postalCode: '10117',
      );
      expect(a.fullAddress, 'Unter den Linden 1, 10117 Berlin, DE');
    });
  });
}
