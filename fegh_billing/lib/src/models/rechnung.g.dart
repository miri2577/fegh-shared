// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rechnung.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RechnungsPosition _$RechnungsPositionFromJson(Map<String, dynamic> json) =>
    RechnungsPosition(
      id: json['id'] as String,
      bezeichnung: json['bezeichnung'] as String,
      menge: (json['menge'] as num).toDouble(),
      einheit: json['einheit'] as String,
      einzelpreis: (json['einzelpreis'] as num).toDouble(),
      steuerprozent: (json['steuerprozent'] as num?)?.toDouble() ?? 0.0,
      leistungszeitraumVon: json['leistungszeitraumVon'] as String?,
      leistungszeitraumBis: json['leistungszeitraumBis'] as String?,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      clientGeburtsdatum: json['clientGeburtsdatum'] as String?,
      fallnummer: json['fallnummer'] as String?,
      leistungstyp: json['leistungstyp'] as String?,
      bewilligungsRef: json['bewilligungsRef'] as String?,
      hinweis: json['hinweis'] as String?,
    );

Map<String, dynamic> _$RechnungsPositionToJson(RechnungsPosition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bezeichnung': instance.bezeichnung,
      'menge': instance.menge,
      'einheit': instance.einheit,
      'einzelpreis': instance.einzelpreis,
      'steuerprozent': instance.steuerprozent,
      'leistungszeitraumVon': instance.leistungszeitraumVon,
      'leistungszeitraumBis': instance.leistungszeitraumBis,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'clientGeburtsdatum': instance.clientGeburtsdatum,
      'fallnummer': instance.fallnummer,
      'leistungstyp': instance.leistungstyp,
      'bewilligungsRef': instance.bewilligungsRef,
      'hinweis': instance.hinweis,
    };

Rechnung _$RechnungFromJson(Map<String, dynamic> json) => Rechnung(
      id: json['id'] as String,
      rechnungsnummer: json['rechnungsnummer'] as String,
      rechnungsdatum: DateTime.parse(json['rechnungsdatum'] as String),
      leistungsVon: json['leistungsVon'] == null
          ? null
          : DateTime.parse(json['leistungsVon'] as String),
      leistungsBis: json['leistungsBis'] == null
          ? null
          : DateTime.parse(json['leistungsBis'] as String),
      empfaengerId: json['empfaengerId'] as String,
      positionen: (json['positionen'] as List<dynamic>)
          .map((e) => RechnungsPosition.fromJson(e as Map<String, dynamic>))
          .toList(),
      skontoProzent: (json['skontoProzent'] as num?)?.toDouble() ?? 0.0,
      zahlungszielTage: (json['zahlungszielTage'] as num?)?.toInt() ?? 30,
      bestellnummer: json['bestellnummer'] as String?,
      vertragsnummer: json['vertragsnummer'] as String?,
      projektnummer: json['projektnummer'] as String?,
      bemerkung: json['bemerkung'] as String?,
      waehrung: json['waehrung'] as String? ?? 'EUR',
      status: $enumDecodeNullable(_$RechnungStatusEnumMap, json['status']) ??
          RechnungStatus.entwurf,
      ustBefreiung: $enumDecodeNullable(
              _$UstBefreiungsgrundEnumMap, json['ustBefreiung']) ??
          UstBefreiungsgrund.par4Nr16h,
      istStorno: json['istStorno'] as bool? ?? false,
      stornoFuerRechnungId: json['stornoFuerRechnungId'] as String?,
      erstelltAm: DateTime.parse(json['erstelltAm'] as String),
    );

Map<String, dynamic> _$RechnungToJson(Rechnung instance) => <String, dynamic>{
      'id': instance.id,
      'rechnungsnummer': instance.rechnungsnummer,
      'rechnungsdatum': instance.rechnungsdatum.toIso8601String(),
      'leistungsVon': instance.leistungsVon?.toIso8601String(),
      'leistungsBis': instance.leistungsBis?.toIso8601String(),
      'empfaengerId': instance.empfaengerId,
      'positionen': instance.positionen,
      'skontoProzent': instance.skontoProzent,
      'zahlungszielTage': instance.zahlungszielTage,
      'bestellnummer': instance.bestellnummer,
      'vertragsnummer': instance.vertragsnummer,
      'projektnummer': instance.projektnummer,
      'bemerkung': instance.bemerkung,
      'waehrung': instance.waehrung,
      'status': _$RechnungStatusEnumMap[instance.status]!,
      'ustBefreiung': _$UstBefreiungsgrundEnumMap[instance.ustBefreiung]!,
      'istStorno': instance.istStorno,
      'stornoFuerRechnungId': instance.stornoFuerRechnungId,
      'erstelltAm': instance.erstelltAm.toIso8601String(),
    };

const _$RechnungStatusEnumMap = {
  RechnungStatus.entwurf: 'entwurf',
  RechnungStatus.versendet: 'versendet',
  RechnungStatus.bezahlt: 'bezahlt',
  RechnungStatus.storniert: 'storniert',
};

const _$UstBefreiungsgrundEnumMap = {
  UstBefreiungsgrund.keine: 'keine',
  UstBefreiungsgrund.par4Nr16h: 'n16h',
  UstBefreiungsgrund.par4Nr25: 'n25',
  UstBefreiungsgrund.par4Nr18: 'n18',
};
