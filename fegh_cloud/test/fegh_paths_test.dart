import 'package:fegh_cloud/fegh_cloud.dart';
import 'package:test/test.dart';

void main() {
  const paths = FeghPaths(orgId: 'acme');

  group('FeghPaths — Basis', () {
    test('organization', () {
      expect(paths.organization, 'eingliederungshilfe/organizations/acme');
    });

    test('administration', () {
      expect(paths.administration,
          'eingliederungshilfe/organizations/acme/administration');
    });

    test('organizationRecord', () {
      expect(paths.organizationRecord,
          'eingliederungshilfe/organizations/acme/administration/organization.bin');
    });

    test('rolesJson', () {
      expect(paths.rolesJson,
          'eingliederungshilfe/organizations/acme/administration/users/roles.json');
    });

    test('clientsIndex', () {
      expect(paths.clientsIndex,
          'eingliederungshilfe/organizations/acme/administration/clients-index.bin');
    });
  });

  group('FeghPaths — Employees', () {
    test('employeeRecord', () {
      expect(paths.employeeRecord('emp-42'),
          'eingliederungshilfe/organizations/acme/employees/emp-42.bin');
    });
  });

  group('FeghPaths — Teams', () {
    test('teamRoot und teamKey', () {
      expect(paths.teamRoot('team-a'),
          'eingliederungshilfe/organizations/acme/teams/team-a');
      expect(paths.teamKey('team-a'),
          'eingliederungshilfe/organizations/acme/teams/team-a/team-key.bin');
    });

    test('teamClientRecord', () {
      expect(paths.teamClientRecord('team-a', 'c1'),
          'eingliederungshilfe/organizations/acme/teams/team-a/clients/c1.bin');
    });

    test('teamShiftRecord', () {
      expect(paths.teamShiftRecord('team-a', 's1'),
          'eingliederungshilfe/organizations/acme/teams/team-a/schedules/s1.bin');
    });

    test('teamWorktimeRecord nutzt yyyy-mm', () {
      final month = DateTime(2026, 4);
      expect(
        paths.teamWorktimeRecord('team-a', 'emp-42', month),
        'eingliederungshilfe/organizations/acme/teams/team-a/worktime/emp-42/2026-04.bin',
      );
    });

    test('teamReportRecord', () {
      expect(paths.teamReportRecord('team-a', 'r1'),
          'eingliederungshilfe/organizations/acme/teams/team-a/reports/r1.bin');
    });
  });

  group('FeghPaths — Shared', () {
    test('calendarSync und messages', () {
      expect(paths.calendarSync,
          'eingliederungshilfe/organizations/acme/shared/calendar-sync');
      expect(paths.messagesDir,
          'eingliederungshilfe/organizations/acme/shared/messages');
    });
  });

  group('FeghPaths — bootstrapDirectories', () {
    test('enthaelt Organisations- und Sub-Ordner', () {
      final dirs = paths.bootstrapDirectories();
      expect(dirs, contains('eingliederungshilfe'));
      expect(dirs, contains('eingliederungshilfe/organizations'));
      expect(dirs, contains('eingliederungshilfe/organizations/acme'));
      expect(dirs, contains(paths.administration));
      expect(dirs, contains(paths.employees));
      expect(dirs, contains(paths.teams));
      expect(dirs, contains(paths.shared));
    });

    test('Reihenfolge ist parent-first (fuer mkcol-Schleife)', () {
      final dirs = paths.bootstrapDirectories();
      final iOrg = dirs.indexOf('eingliederungshilfe/organizations');
      final iAdmin = dirs.indexOf(paths.administration);
      expect(iOrg, lessThan(iAdmin),
          reason: 'organizations/ muss vor administration/ kommen');
    });
  });

  group('FeghPaths — custom root', () {
    test('laesst sich fuer Tests ueberschreiben', () {
      const custom = FeghPaths(orgId: 'acme', root: 'test-root');
      expect(custom.organization, 'test-root/organizations/acme');
    });
  });
}
