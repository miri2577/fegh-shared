import 'package:fegh_billing/fegh_billing.dart';
import 'package:test/test.dart';

void main() {
  group('UstBefreiungsgrund.vatexCode', () {
    test('keine → leerer Code', () {
      expect(UstBefreiungsgrund.keine.vatexCode, '');
    });

    test('§4 Nr. 16 h → VATEX-EU-132-1G (Sozialfuersorge)', () {
      expect(UstBefreiungsgrund.par4Nr16h.vatexCode, 'VATEX-EU-132-1G');
    });

    test('§4 Nr. 18 → VATEX-EU-132-1G (Wohlfahrtspflege)', () {
      expect(UstBefreiungsgrund.par4Nr18.vatexCode, 'VATEX-EU-132-1G');
    });

    test('§4 Nr. 25 → VATEX-EU-132-1H (Jugendhilfe)', () {
      expect(UstBefreiungsgrund.par4Nr25.vatexCode, 'VATEX-EU-132-1H');
    });

    test('keine Code beginnt mit dem erfundenen VATEX-DE-Praefix', () {
      for (final g in UstBefreiungsgrund.values) {
        final code = g.vatexCode;
        expect(code.startsWith('VATEX-DE-'), isFalse,
            reason:
                'VATEX-DE-* waren historisch erfundene Codes, jetzt raus: found "$code" for $g');
      }
    });
  });

  group('UstBefreiungsgrund.rechnungstext', () {
    test('Paragraphen korrekt referenziert', () {
      expect(UstBefreiungsgrund.par4Nr16h.rechnungstext,
          contains('§4 Nr. 16 Buchst. h'));
      expect(UstBefreiungsgrund.par4Nr18.rechnungstext,
          contains('§4 Nr. 18'));
      expect(UstBefreiungsgrund.par4Nr25.rechnungstext,
          contains('§4 Nr. 25'));
    });

    test('keine → null', () {
      expect(UstBefreiungsgrund.keine.rechnungstext, isNull);
    });
  });
}
