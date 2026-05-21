import 'package:fegh_pdf_kit/fegh_pdf_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfDesignTokens', () {
    test('primary color matches legacy value (0xFF1E3A5F)', () {
      expect(PdfDesignTokens.primaer.toInt(), 0xFF1E3A5F);
    });

    test('warn/accent/divider are distinct from each other and from text', () {
      final values = <int>{
        PdfDesignTokens.warn.toInt(),
        PdfDesignTokens.accent.toInt(),
        PdfDesignTokens.divider.toInt(),
        PdfDesignTokens.text.toInt(),
        PdfDesignTokens.muted.toInt(),
        PdfDesignTokens.tableHeader.toInt(),
        PdfDesignTokens.primaer.toInt(),
      };
      expect(values.length, 7, reason: 'all tokens must be unique');
    });

    test('page margins are positive', () {
      expect(PdfDesignTokens.marginLeft, greaterThan(0));
      expect(PdfDesignTokens.marginTop, greaterThan(0));
      expect(PdfDesignTokens.marginRight, greaterThan(0));
      expect(PdfDesignTokens.marginBottom, greaterThan(0));
    });
  });

  group('PdfKpi', () {
    test('hero defaults to false', () {
      final kpi = PdfKpi(
        label: 'X',
        value: '1',
        color: PdfDesignTokens.primaer,
      );
      expect(kpi.hero, isFalse);
    });

    test('hero can be enabled', () {
      final kpi = PdfKpi(
        label: 'X',
        value: '1',
        color: PdfDesignTokens.primaer,
        hero: true,
      );
      expect(kpi.hero, isTrue);
    });
  });
}
