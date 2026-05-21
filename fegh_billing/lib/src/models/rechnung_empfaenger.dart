import 'package:json_annotation/json_annotation.dart';

part 'rechnung_empfaenger.g.dart';

/// Rechnungsempfaenger (Kostentraeger) mit allen fuer XRechnung
/// erforderlichen Daten: Leitweg-ID, Adresse, ggf. USt-ID.
///
/// Die Leitweg-ID ist der Kernschluessel der XRechnung und
/// eindeutig pro Behoerde / Kostentraeger. Format: 05314-xxxxx-xx (Beispiel Berlin)
/// oder 04011-xxxxx-xx (Bund).
@JsonSerializable()
class RechnungEmpfaenger {
  final String id;
  final String name;              // "Sozialamt Friedrichshain-Kreuzberg"
  final String? abteilung;        // optional "Teilhabefachdienst"
  final String leitwegId;         // z.B. "05314-11001001-01" (Berlin Bezirk Mitte Sozialamt)
  final String strasse;           // "Platz der Luftbruecke 5"
  final String plz;
  final String ort;
  final String land;              // "DE"
  final String? ansprechpartner;
  final String? email;
  final String? telefon;
  final String? umsatzsteuerId;   // meist leer fuer Behoerden
  final DateTime erstelltAm;

  RechnungEmpfaenger({
    required this.id,
    required this.name,
    this.abteilung,
    required this.leitwegId,
    required this.strasse,
    required this.plz,
    required this.ort,
    this.land = 'DE',
    this.ansprechpartner,
    this.email,
    this.telefon,
    this.umsatzsteuerId,
    required this.erstelltAm,
  });

  RechnungEmpfaenger.create({
    required this.name,
    this.abteilung,
    required this.leitwegId,
    required this.strasse,
    required this.plz,
    required this.ort,
    this.land = 'DE',
    this.ansprechpartner,
    this.email,
    this.telefon,
    this.umsatzsteuerId,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        erstelltAm = DateTime.now();

  factory RechnungEmpfaenger.fromJson(Map<String, dynamic> json) =>
      _$RechnungEmpfaengerFromJson(json);
  Map<String, dynamic> toJson() => _$RechnungEmpfaengerToJson(this);

  RechnungEmpfaenger copyWith({
    String? name,
    String? abteilung,
    String? leitwegId,
    String? strasse,
    String? plz,
    String? ort,
    String? land,
    String? ansprechpartner,
    String? email,
    String? telefon,
    String? umsatzsteuerId,
  }) {
    return RechnungEmpfaenger(
      id: id,
      name: name ?? this.name,
      abteilung: abteilung ?? this.abteilung,
      leitwegId: leitwegId ?? this.leitwegId,
      strasse: strasse ?? this.strasse,
      plz: plz ?? this.plz,
      ort: ort ?? this.ort,
      land: land ?? this.land,
      ansprechpartner: ansprechpartner ?? this.ansprechpartner,
      email: email ?? this.email,
      telefon: telefon ?? this.telefon,
      umsatzsteuerId: umsatzsteuerId ?? this.umsatzsteuerId,
      erstelltAm: erstelltAm,
    );
  }

  /// Grobe Pruefung: Leitweg-ID hat Format NNNNN-xxxxxxxxxxxxxx-NN
  /// Genaue Validierung regelt die Landesstelle/XRechnung-Pruefer.
  bool get leitwegIdGueltig {
    final pattern = RegExp(r'^\d{2,12}(-[A-Za-z0-9]{1,30})?(-\d{1,3})?$');
    return pattern.hasMatch(leitwegId);
  }
}
