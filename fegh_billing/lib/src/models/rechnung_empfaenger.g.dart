// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rechnung_empfaenger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RechnungEmpfaenger _$RechnungEmpfaengerFromJson(Map<String, dynamic> json) =>
    RechnungEmpfaenger(
      id: json['id'] as String,
      name: json['name'] as String,
      abteilung: json['abteilung'] as String?,
      leitwegId: json['leitwegId'] as String,
      strasse: json['strasse'] as String,
      plz: json['plz'] as String,
      ort: json['ort'] as String,
      land: json['land'] as String? ?? 'DE',
      ansprechpartner: json['ansprechpartner'] as String?,
      email: json['email'] as String?,
      telefon: json['telefon'] as String?,
      umsatzsteuerId: json['umsatzsteuerId'] as String?,
      erstelltAm: DateTime.parse(json['erstelltAm'] as String),
    );

Map<String, dynamic> _$RechnungEmpfaengerToJson(RechnungEmpfaenger instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'abteilung': instance.abteilung,
      'leitwegId': instance.leitwegId,
      'strasse': instance.strasse,
      'plz': instance.plz,
      'ort': instance.ort,
      'land': instance.land,
      'ansprechpartner': instance.ansprechpartner,
      'email': instance.email,
      'telefon': instance.telefon,
      'umsatzsteuerId': instance.umsatzsteuerId,
      'erstelltAm': instance.erstelltAm.toIso8601String(),
    };
