import 'package:fegh_billing/fegh_billing.dart';
import 'package:test/test.dart';

Rechnung _sampleRechnung({
  UstBefreiungsgrund grund = UstBefreiungsgrund.par4Nr16h,
}) {
  final leistungsZeit = DateTime(2026, 4, 1);
  return Rechnung(
    id: 'rechnung-001',
    rechnungsnummer: '2026-0042',
    rechnungsdatum: DateTime(2026, 4, 30),
    leistungsVon: leistungsZeit,
    leistungsBis: DateTime(2026, 4, 30),
    empfaengerId: 'empf-1',
    positionen: [
      RechnungsPosition(
        id: 'pos-1',
        bezeichnung: 'Fachleistungsstunde Eingliederungshilfe',
        menge: 12.5,
        einheit: 'Stunde',
        einzelpreis: 72.50,
        steuerprozent: 0,
        leistungszeitraumVon: '2026-04-01',
        leistungszeitraumBis: '2026-04-30',
        clientName: 'Max Mustermann',
        fallnummer: 'EGH-2026-12345',
      ),
    ],
    bemerkung: 'Abrechnungszeitraum April 2026',
    ustBefreiung: grund,
    erstelltAm: DateTime(2026, 4, 30),
  );
}

RechnungEmpfaenger _sampleEmpfaenger() {
  return RechnungEmpfaenger(
    id: 'empf-1',
    name: 'Sozialamt Friedrichshain-Kreuzberg',
    abteilung: 'Teilhabefachdienst',
    leitwegId: '991-01234-44',
    strasse: 'Yorckstrasse 4-11',
    plz: '10965',
    ort: 'Berlin',
    ansprechpartner: 'Anna Schmitt',
    email: 'teilhabe@ba-fk.berlin.de',
    erstelltAm: DateTime(2026, 1, 1),
  );
}

RechnungsstellerDaten _sampleSteller({
  String? telefon = '+49 30 12345678',
}) {
  return RechnungsstellerDaten(
    name: 'FEGH gGmbH',
    strasse: 'Musterstrasse 5',
    plz: '10115',
    ort: 'Berlin',
    umsatzsteuerId: 'DE123456789',
    iban: 'DE89370400440532013000',
    bic: 'COBADEFFXXX',
    kontoinhaber: 'FEGH gGmbH',
    email: 'rechnung@fegh.example',
    telefon: telefon,
    ansprechpartner: 'Rechnungswesen FEGH',
    elektronischeAdresse: 'rechnung@fegh.example',
  );
}

void main() {
  group('XRechnungService.buildXml — Header', () {
    test('enthaelt XML-Deklaration und UBL-Namespaces', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );

      expect(xml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(xml, contains('urn:oasis:names:specification:ubl:schema:xsd:Invoice-2'));
      expect(xml, contains('xmlns:cac='));
      expect(xml, contains('xmlns:cbc='));
    });

    test('enthaelt KoSIT-3.0 CustomizationID', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(
        xml,
        contains(
            'urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0'),
      );
    });

    test('setzt ProfileID (Peppol BIS 3.0)', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(xml, contains('urn:fdc:peppol.eu:2017:poacc:billing:01:1.0'));
    });

    test('Rechnungsnummer, Datum und InvoiceTypeCode 380', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(xml, contains('<cbc:ID>2026-0042</cbc:ID>'));
      expect(xml, contains('<cbc:IssueDate>2026-04-30</cbc:IssueDate>'));
      expect(xml, contains('<cbc:InvoiceTypeCode>380</cbc:InvoiceTypeCode>'));
    });
  });

  group('XRechnungService.buildXml — BuyerReference (Leitweg-ID)', () {
    test('Leitweg-ID steht als BuyerReference (BT-10)', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(xml, contains('<cbc:BuyerReference>991-01234-44</cbc:BuyerReference>'));
    });
  });

  group('XRechnungService.buildXml — TaxTotal & VATEX', () {
    test('§4 Nr. 16h UStG → VATEX-EU-132-1G mit Klartext', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(grund: UstBefreiungsgrund.par4Nr16h),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(
          xml,
          contains(
              '<cbc:TaxExemptionReasonCode>VATEX-EU-132-1G</cbc:TaxExemptionReasonCode>'));
      expect(
          xml,
          contains(
              '<cbc:TaxExemptionReason>Steuerfreie Leistung nach §4 Nr. 16 Buchst. h UStG</cbc:TaxExemptionReason>'));
    });

    test('§4 Nr. 25 UStG → VATEX-EU-132-1H', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(grund: UstBefreiungsgrund.par4Nr25),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(
          xml,
          contains(
              '<cbc:TaxExemptionReasonCode>VATEX-EU-132-1H</cbc:TaxExemptionReasonCode>'));
    });

    test('§4 Nr. 18 UStG → VATEX-EU-132-1G (wie Nr. 16h)', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(grund: UstBefreiungsgrund.par4Nr18),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(
          xml,
          contains(
              '<cbc:TaxExemptionReasonCode>VATEX-EU-132-1G</cbc:TaxExemptionReasonCode>'));
    });

    test('keine Befreiung → kein Exemption-Element', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final r = Rechnung(
        id: 'r',
        rechnungsnummer: '2026-0043',
        rechnungsdatum: DateTime(2026, 4, 30),
        empfaengerId: 'empf-1',
        positionen: [
          RechnungsPosition(
            id: 'p',
            bezeichnung: 'Steuerpflichtige Leistung',
            menge: 1,
            einheit: 'Stueck',
            einzelpreis: 100,
            steuerprozent: 19,
          ),
        ],
        ustBefreiung: UstBefreiungsgrund.keine,
        erstelltAm: DateTime(2026, 4, 30),
      );
      final xml = service.buildXml(rechnung: r, empfaenger: _sampleEmpfaenger());
      expect(xml, isNot(contains('TaxExemptionReasonCode')));
      expect(xml, contains('<cbc:Percent>19'));
    });

    test('TaxCategory ID: E bei 0% (Exempt), S bei >0%', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      expect(xml, contains('<cbc:ID>E</cbc:ID>'));
    });
  });

  group('XRechnungService.buildXml — Betraege', () {
    test('Position 12.5 h × 72.50 EUR = 906.25 Netto', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );
      // Netto = Brutto bei 0% Befreiung
      expect(xml, contains('<cbc:TaxInclusiveAmount currencyID="EUR">906.25'));
      expect(xml, contains('<cbc:PayableAmount currencyID="EUR">906.25'));
    });
  });

  group('XRechnungService.buildXml — Nicht-akzeptable Inhalte', () {
    test('keine erfundenen VATEX-DE-* Codes im XML', () {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      for (final grund in UstBefreiungsgrund.values) {
        final xml = service.buildXml(
          rechnung: _sampleRechnung(grund: grund),
          empfaenger: _sampleEmpfaenger(),
        );
        expect(xml, isNot(contains('VATEX-DE-HE')),
            reason: 'erfundener Code darf nicht auftauchen ($grund)');
        expect(xml, isNot(contains('VATEX-DE-H<')),
            reason: 'erfundener Code darf nicht auftauchen ($grund)');
        expect(xml, isNot(contains('VATEX-DE-V')),
            reason: 'erfundener Code darf nicht auftauchen ($grund)');
      }
    });
  });
}
