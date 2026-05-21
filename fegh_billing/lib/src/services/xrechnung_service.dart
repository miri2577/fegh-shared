import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/rechnung.dart';
import '../models/rechnung_empfaenger.dart';
// Hinweis: Die frueher vorhandene fromMitarbeiter-Factory wurde entfernt,
// weil Mitarbeiter ein app-spezifisches Model ist. Die Apps koennen in
// ihrem eigenen Code ein RechnungsstellerDaten-Objekt aus dem
// Mitarbeiter konstruieren.

/// Erzeugt XRechnung-konformes UBL 2.1 XML.
///
/// Spezifikation: XRechnung 3.0.2 (KoSIT/XEinkauf), basierend auf
/// EN 16931 / UBL 2.1.
/// CustomizationID: urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0
/// ProfileID: urn:fdc:peppol.eu:2017:poacc:billing:01:1.0
///
/// Hinweis: Der URN wurde mit XRechnung 3.0.2 von
/// `urn:xoev-de:kosit:standard:xrechnung_3.0` auf
/// `urn:xeinkauf.de:kosit:xrechnung_3.0` umgestellt. Der alte URN
/// matched keine aktuellen KoSIT-Szenarios.
class XRechnungService {
  static const String _customizationId =
      'urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0';
  static const String _profileId =
      'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0';
  static const String _invoiceTypeCode = '380'; // Handelsrechnung

  /// Rechnungssteller-Daten (unsere Organisation).
  /// Muss aus den Einstellungen / Mitarbeiter-Profil kommen.
  final RechnungsstellerDaten rechnungssteller;

  XRechnungService({required this.rechnungssteller});

  /// Erzeugt XRechnung-XML als String.
  ///
  /// Wirft [ArgumentError], wenn XRechnung-Pflichtfelder fehlen, die
  /// sonst erst von KoSIT-Schematron-Regeln abgelehnt werden:
  /// - `rechnungssteller.telefon` (BR-DE-6, BT-42)
  /// - `rechnungssteller.email` (BR-DE-7, BT-43)
  String buildXml({
    required Rechnung rechnung,
    required RechnungEmpfaenger empfaenger,
  }) {
    final tel = rechnungssteller.telefon?.trim() ?? '';
    if (tel.isEmpty) {
      throw ArgumentError(
          'RechnungsstellerDaten.telefon ist pflicht fuer XRechnung '
          '(BR-DE-6 / BT-42).');
    }
    final mail = rechnungssteller.email?.trim() ?? '';
    if (mail.isEmpty) {
      throw ArgumentError(
          'RechnungsstellerDaten.email ist pflicht fuer XRechnung '
          '(BR-DE-7 / BT-43).');
    }

    final b = StringBuffer();
    final df = DateFormat('yyyy-MM-dd');

    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln(
        '<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" '
        'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
        'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">');

    // Header
    b.writeln('  <cbc:CustomizationID>$_customizationId</cbc:CustomizationID>');
    b.writeln('  <cbc:ProfileID>$_profileId</cbc:ProfileID>');
    b.writeln('  <cbc:ID>${_esc(rechnung.rechnungsnummer)}</cbc:ID>');
    b.writeln('  <cbc:IssueDate>${df.format(rechnung.rechnungsdatum)}</cbc:IssueDate>');
    b.writeln('  <cbc:DueDate>${df.format(rechnung.faelligkeit)}</cbc:DueDate>');
    b.writeln('  <cbc:InvoiceTypeCode>$_invoiceTypeCode</cbc:InvoiceTypeCode>');
    if (rechnung.bemerkung != null && rechnung.bemerkung!.isNotEmpty) {
      b.writeln('  <cbc:Note>${_esc(rechnung.bemerkung!)}</cbc:Note>');
    }
    b.writeln('  <cbc:DocumentCurrencyCode>${rechnung.waehrung}</cbc:DocumentCurrencyCode>');

    // BT-10 Leitweg-ID (Buyer Reference) - PFLICHT fuer XRechnung
    b.writeln('  <cbc:BuyerReference>${_esc(empfaenger.leitwegId)}</cbc:BuyerReference>');

    // BT-13 Purchase Order Reference
    if (rechnung.bestellnummer != null && rechnung.bestellnummer!.isNotEmpty) {
      b.writeln('  <cac:OrderReference>');
      b.writeln('    <cbc:ID>${_esc(rechnung.bestellnummer!)}</cbc:ID>');
      b.writeln('  </cac:OrderReference>');
    }

    // BT-12 Contract Reference
    if (rechnung.vertragsnummer != null && rechnung.vertragsnummer!.isNotEmpty) {
      b.writeln('  <cac:ContractDocumentReference>');
      b.writeln('    <cbc:ID>${_esc(rechnung.vertragsnummer!)}</cbc:ID>');
      b.writeln('  </cac:ContractDocumentReference>');
    }

    // BT-11 Project Reference
    if (rechnung.projektnummer != null && rechnung.projektnummer!.isNotEmpty) {
      b.writeln('  <cac:ProjectReference>');
      b.writeln('    <cbc:ID>${_esc(rechnung.projektnummer!)}</cbc:ID>');
      b.writeln('  </cac:ProjectReference>');
    }

    // BT-73/74 Invoice Period — laut UBL-Schema muss dieses Element
    // VOR AccountingSupplierParty stehen (Reihenfolge: BuyerReference,
    // [Order/Contract/ProjectReference], InvoicePeriod, Signature,
    // AccountingSupplierParty, AccountingCustomerParty, ...).
    if (rechnung.leistungsVon != null && rechnung.leistungsBis != null) {
      b.writeln('  <cac:InvoicePeriod>');
      b.writeln('    <cbc:StartDate>${df.format(rechnung.leistungsVon!)}</cbc:StartDate>');
      b.writeln('    <cbc:EndDate>${df.format(rechnung.leistungsBis!)}</cbc:EndDate>');
      b.writeln('  </cac:InvoicePeriod>');
    }

    // BG-4 Seller (Rechnungssteller)
    _writeSeller(b);

    // BG-7 Buyer (Rechnungsempfaenger)
    _writeBuyer(b, empfaenger);

    // Payment Means
    _writePayment(b, rechnung);

    // Tax Total
    _writeTaxTotal(b, rechnung);

    // Legal Monetary Total
    _writeMonetaryTotal(b, rechnung);

    // Invoice Lines
    for (int i = 0; i < rechnung.positionen.length; i++) {
      _writeInvoiceLine(b, rechnung.positionen[i], i + 1, rechnung.waehrung);
    }

    b.writeln('</Invoice>');
    return b.toString();
  }

  /// Erzeugt die XRechnung-XML als UTF-8-Bytes.
  Uint8List buildBytes({
    required Rechnung rechnung,
    required RechnungEmpfaenger empfaenger,
  }) {
    final xml = buildXml(rechnung: rechnung, empfaenger: empfaenger);
    return Uint8List.fromList(utf8.encode(xml));
  }

  // ── Seller / Buyer ─────────────────────────────────────────────────

  void _writeSeller(StringBuffer b) {
    final s = rechnungssteller;
    b.writeln('  <cac:AccountingSupplierParty>');
    b.writeln('    <cac:Party>');
    if (s.elektronischeAdresse != null && s.elektronischeAdresse!.isNotEmpty) {
      b.writeln('      <cbc:EndpointID schemeID="EM">${_esc(s.elektronischeAdresse!)}</cbc:EndpointID>');
    }
    b.writeln('      <cac:PartyName><cbc:Name>${_esc(s.name)}</cbc:Name></cac:PartyName>');
    b.writeln('      <cac:PostalAddress>');
    b.writeln('        <cbc:StreetName>${_esc(s.strasse)}</cbc:StreetName>');
    b.writeln('        <cbc:CityName>${_esc(s.ort)}</cbc:CityName>');
    b.writeln('        <cbc:PostalZone>${_esc(s.plz)}</cbc:PostalZone>');
    b.writeln('        <cac:Country><cbc:IdentificationCode>${s.land}</cbc:IdentificationCode></cac:Country>');
    b.writeln('      </cac:PostalAddress>');

    // USt-ID oder Steuernummer (Pflicht wenn umsatzsteuerpflichtig)
    if (s.umsatzsteuerId != null && s.umsatzsteuerId!.isNotEmpty) {
      b.writeln('      <cac:PartyTaxScheme>');
      b.writeln('        <cbc:CompanyID>${_esc(s.umsatzsteuerId!)}</cbc:CompanyID>');
      b.writeln('        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>');
      b.writeln('      </cac:PartyTaxScheme>');
    } else if (s.steuernummer != null && s.steuernummer!.isNotEmpty) {
      b.writeln('      <cac:PartyTaxScheme>');
      b.writeln('        <cbc:CompanyID>${_esc(s.steuernummer!)}</cbc:CompanyID>');
      b.writeln('        <cac:TaxScheme><cbc:ID>FC</cbc:ID></cac:TaxScheme>');
      b.writeln('      </cac:PartyTaxScheme>');
    }

    b.writeln('      <cac:PartyLegalEntity>');
    b.writeln('        <cbc:RegistrationName>${_esc(s.name)}</cbc:RegistrationName>');
    // Einrichtungs-IK (nur relevant bei stationaer; optional)
    if (s.einrichtungsIk != null && s.einrichtungsIk!.isNotEmpty) {
      b.writeln('        <cbc:CompanyID schemeID="0088">${_esc(s.einrichtungsIk!)}</cbc:CompanyID>');
    }
    b.writeln('      </cac:PartyLegalEntity>');

    // BG-6 Seller Contact ist in XRechnung CIUS PFLICHT (BR-DE-2).
    // Contact-Element immer schreiben; fehlender Ansprechpartner → Name
    // der Organisation als Fallback.
    b.writeln('      <cac:Contact>');
    b.writeln('        <cbc:Name>${_esc(s.ansprechpartner?.trim().isNotEmpty == true ? s.ansprechpartner! : s.name)}</cbc:Name>');
    if (s.telefon != null && s.telefon!.isNotEmpty) {
      b.writeln('        <cbc:Telephone>${_esc(s.telefon!)}</cbc:Telephone>');
    }
    if (s.email != null && s.email!.isNotEmpty) {
      b.writeln('        <cbc:ElectronicMail>${_esc(s.email!)}</cbc:ElectronicMail>');
    }
    b.writeln('      </cac:Contact>');
    b.writeln('    </cac:Party>');
    b.writeln('  </cac:AccountingSupplierParty>');
  }

  void _writeBuyer(StringBuffer b, RechnungEmpfaenger e) {
    b.writeln('  <cac:AccountingCustomerParty>');
    b.writeln('    <cac:Party>');
    b.writeln('      <cbc:EndpointID schemeID="0204">${_esc(e.leitwegId)}</cbc:EndpointID>');
    b.writeln('      <cac:PartyName><cbc:Name>${_esc(e.name)}</cbc:Name></cac:PartyName>');
    b.writeln('      <cac:PostalAddress>');
    b.writeln('        <cbc:StreetName>${_esc(e.strasse)}</cbc:StreetName>');
    b.writeln('        <cbc:CityName>${_esc(e.ort)}</cbc:CityName>');
    b.writeln('        <cbc:PostalZone>${_esc(e.plz)}</cbc:PostalZone>');
    b.writeln('        <cac:Country><cbc:IdentificationCode>${e.land}</cbc:IdentificationCode></cac:Country>');
    b.writeln('      </cac:PostalAddress>');
    b.writeln('      <cac:PartyLegalEntity>');
    b.writeln('        <cbc:RegistrationName>${_esc(e.name)}</cbc:RegistrationName>');
    b.writeln('      </cac:PartyLegalEntity>');
    if (e.ansprechpartner != null && e.ansprechpartner!.isNotEmpty) {
      b.writeln('      <cac:Contact>');
      b.writeln('        <cbc:Name>${_esc(e.ansprechpartner!)}</cbc:Name>');
      if (e.telefon != null) b.writeln('        <cbc:Telephone>${_esc(e.telefon!)}</cbc:Telephone>');
      if (e.email != null) b.writeln('        <cbc:ElectronicMail>${_esc(e.email!)}</cbc:ElectronicMail>');
      b.writeln('      </cac:Contact>');
    }
    b.writeln('    </cac:Party>');
    b.writeln('  </cac:AccountingCustomerParty>');
  }

  void _writePayment(StringBuffer b, Rechnung r) {
    final s = rechnungssteller;
    // BT-81 Payment Means Code: 58 = SEPA Credit Transfer
    b.writeln('  <cac:PaymentMeans>');
    b.writeln('    <cbc:PaymentMeansCode>58</cbc:PaymentMeansCode>');
    b.writeln('    <cbc:PaymentID>${_esc(r.rechnungsnummer)}</cbc:PaymentID>');
    if (s.iban != null && s.iban!.isNotEmpty) {
      b.writeln('    <cac:PayeeFinancialAccount>');
      b.writeln('      <cbc:ID>${_esc(s.iban!)}</cbc:ID>');
      if (s.kontoinhaber != null) {
        b.writeln('      <cbc:Name>${_esc(s.kontoinhaber!)}</cbc:Name>');
      }
      if (s.bic != null && s.bic!.isNotEmpty) {
        b.writeln('      <cac:FinancialInstitutionBranch>');
        b.writeln('        <cbc:ID>${_esc(s.bic!)}</cbc:ID>');
        b.writeln('      </cac:FinancialInstitutionBranch>');
      }
      b.writeln('    </cac:PayeeFinancialAccount>');
    }
    b.writeln('  </cac:PaymentMeans>');

    // Zahlungsbedingungen
    b.writeln('  <cac:PaymentTerms>');
    b.writeln('    <cbc:Note>Zahlbar innerhalb ${r.zahlungszielTage} Tagen</cbc:Note>');
    b.writeln('  </cac:PaymentTerms>');
  }

  void _writeTaxTotal(StringBuffer b, Rechnung r) {
    // Gruppiere Steuersaetze
    final taxGruppen = <double, double>{}; // prozent -> steuerbetrag
    final nettoGruppen = <double, double>{}; // prozent -> nettobetrag
    for (final p in r.positionen) {
      taxGruppen[p.steuerprozent] = (taxGruppen[p.steuerprozent] ?? 0) + p.steuerBetrag;
      nettoGruppen[p.steuerprozent] = (nettoGruppen[p.steuerprozent] ?? 0) + p.nettoBetrag;
    }

    b.writeln('  <cac:TaxTotal>');
    b.writeln('    <cbc:TaxAmount currencyID="${r.waehrung}">${_amt(r.gesamtSteuer)}</cbc:TaxAmount>');
    taxGruppen.forEach((prozent, steuer) {
      final netto = nettoGruppen[prozent] ?? 0;
      b.writeln('    <cac:TaxSubtotal>');
      b.writeln('      <cbc:TaxableAmount currencyID="${r.waehrung}">${_amt(netto)}</cbc:TaxableAmount>');
      b.writeln('      <cbc:TaxAmount currencyID="${r.waehrung}">${_amt(steuer)}</cbc:TaxAmount>');
      b.writeln('      <cac:TaxCategory>');
      // Kategorie: Z = Zero rated (0%), S = Standard (19%), E = Exempt
      final cat = prozent == 0 ? 'E' : 'S';
      b.writeln('        <cbc:ID>$cat</cbc:ID>');
      b.writeln('        <cbc:Percent>${_amt(prozent)}</cbc:Percent>');
      if (prozent == 0 && r.ustBefreiung != UstBefreiungsgrund.keine) {
        b.writeln('        <cbc:TaxExemptionReasonCode>${r.ustBefreiung.vatexCode}</cbc:TaxExemptionReasonCode>');
        b.writeln('        <cbc:TaxExemptionReason>${_esc(r.ustBefreiung.rechnungstext ?? "")}</cbc:TaxExemptionReason>');
      }
      b.writeln('        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>');
      b.writeln('      </cac:TaxCategory>');
      b.writeln('    </cac:TaxSubtotal>');
    });
    b.writeln('  </cac:TaxTotal>');
  }

  void _writeMonetaryTotal(StringBuffer b, Rechnung r) {
    b.writeln('  <cac:LegalMonetaryTotal>');
    b.writeln('    <cbc:LineExtensionAmount currencyID="${r.waehrung}">${_amt(r.gesamtNetto)}</cbc:LineExtensionAmount>');
    b.writeln('    <cbc:TaxExclusiveAmount currencyID="${r.waehrung}">${_amt(r.gesamtNetto)}</cbc:TaxExclusiveAmount>');
    b.writeln('    <cbc:TaxInclusiveAmount currencyID="${r.waehrung}">${_amt(r.gesamtBrutto)}</cbc:TaxInclusiveAmount>');
    b.writeln('    <cbc:PayableAmount currencyID="${r.waehrung}">${_amt(r.gesamtBrutto)}</cbc:PayableAmount>');
    b.writeln('  </cac:LegalMonetaryTotal>');
  }

  void _writeInvoiceLine(StringBuffer b, RechnungsPosition p, int nr, String waehrung) {
    b.writeln('  <cac:InvoiceLine>');
    b.writeln('    <cbc:ID>$nr</cbc:ID>');
    b.writeln('    <cbc:InvoicedQuantity unitCode="${_unitCode(p.einheit)}">${_amt(p.menge)}</cbc:InvoicedQuantity>');
    b.writeln('    <cbc:LineExtensionAmount currencyID="$waehrung">${_amt(p.nettoBetrag)}</cbc:LineExtensionAmount>');
    if (p.leistungszeitraumVon != null && p.leistungszeitraumBis != null) {
      b.writeln('    <cac:InvoicePeriod>');
      b.writeln('      <cbc:StartDate>${p.leistungszeitraumVon}</cbc:StartDate>');
      b.writeln('      <cbc:EndDate>${p.leistungszeitraumBis}</cbc:EndDate>');
      b.writeln('    </cac:InvoicePeriod>');
    }
    b.writeln('    <cac:Item>');
    // UBL `cac:Item` erwartet Description VOR Name.
    // Beschreibung: Hinweis + Klient-Meta (Fallnummer, Geburtsdatum, Leistungstyp)
    final desc = StringBuffer();
    if (p.hinweis != null && p.hinweis!.isNotEmpty) desc.write(p.hinweis);
    if (p.fallnummer != null && p.fallnummer!.isNotEmpty) {
      if (desc.isNotEmpty) desc.write(' | ');
      desc.write('Aktenzeichen: ${p.fallnummer}');
    }
    if (p.clientGeburtsdatum != null && p.clientGeburtsdatum!.isNotEmpty) {
      if (desc.isNotEmpty) desc.write(' | ');
      desc.write('geb. ${p.clientGeburtsdatum}');
    }
    if (p.leistungstyp != null && p.leistungstyp!.isNotEmpty) {
      if (desc.isNotEmpty) desc.write(' | ');
      desc.write('Leistungstyp: ${p.leistungstyp}');
    }
    if (p.bewilligungsRef != null && p.bewilligungsRef!.isNotEmpty) {
      if (desc.isNotEmpty) desc.write(' | ');
      desc.write('Bewilligung: ${p.bewilligungsRef}');
    }
    if (desc.isNotEmpty) {
      b.writeln('      <cbc:Description>${_esc(desc.toString())}</cbc:Description>');
    }
    b.writeln('      <cbc:Name>${_esc(p.bezeichnung)}</cbc:Name>');
    // Steuerkategorie: E = Exempt (steuerbefreit), S = Standard (19%)
    final cat = p.steuerprozent == 0 ? 'E' : 'S';
    b.writeln('      <cac:ClassifiedTaxCategory>');
    b.writeln('        <cbc:ID>$cat</cbc:ID>');
    b.writeln('        <cbc:Percent>${_amt(p.steuerprozent)}</cbc:Percent>');
    b.writeln('        <cac:TaxScheme><cbc:ID>VAT</cbc:ID></cac:TaxScheme>');
    b.writeln('      </cac:ClassifiedTaxCategory>');
    b.writeln('    </cac:Item>');
    b.writeln('    <cac:Price>');
    b.writeln('      <cbc:PriceAmount currencyID="$waehrung">${_amt(p.einzelpreis)}</cbc:PriceAmount>');
    b.writeln('    </cac:Price>');
    b.writeln('  </cac:InvoiceLine>');
  }

  // ── Hilfsmethoden ──────────────────────────────────────────────────

  /// UN/ECE Rec 20 Unit Codes.
  String _unitCode(String einheit) {
    final e = einheit.toLowerCase();
    if (e.startsWith('stund') || e == 'h' || e.startsWith('hour')) return 'HUR';
    if (e.startsWith('stueck') || e.startsWith('stück') || e == 'c62') return 'H87';
    if (e.startsWith('min')) return 'MIN';
    if (e.startsWith('tag') || e == 'day') return 'DAY';
    if (e.startsWith('pauschal')) return 'LS';
    return 'C62'; // default: unit of measure
  }

  String _amt(double v) => v.toStringAsFixed(2);

  String _esc(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

/// Stammdaten des Rechnungsstellers (unsere Organisation).
/// Kommt aus den App-Einstellungen und dem Admin-Profil.
class RechnungsstellerDaten {
  final String name;
  final String strasse;
  final String plz;
  final String ort;
  final String land;
  final String? umsatzsteuerId; // DE123456789 - wenn vorhanden
  final String? steuernummer;   // wenn keine USt-ID
  final String? einrichtungsIk;  // 9-stellige IK-Nummer (nur stationaer relevant)
  final String? iban;
  final String? bic;
  final String? kontoinhaber;
  final String? email;
  final String? telefon;
  final String? ansprechpartner;
  final String? elektronischeAdresse; // E-Mail fuer XRechnung EndpointID

  const RechnungsstellerDaten({
    required this.name,
    required this.strasse,
    required this.plz,
    required this.ort,
    this.land = 'DE',
    this.umsatzsteuerId,
    this.steuernummer,
    this.einrichtungsIk,
    this.iban,
    this.bic,
    this.kontoinhaber,
    this.email,
    this.telefon,
    this.ansprechpartner,
    this.elektronischeAdresse,
  });

}
