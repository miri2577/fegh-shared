// Berliner Kostenträger für Eingliederungshilfe und Familienhilfe
// Gruppiert nach BTHG-Struktur (Bundesteilhabegesetz)
class Kostentraeger {
  // Gruppierte Liste im gleichen Format wie rechtsgrundlagen
  static const List<Map<String, String>> alleGruppiert = [
    // Jugendämter (Bezirke)
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Charlottenburg-Wilmersdorf'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Friedrichshain-Kreuzberg'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Lichtenberg'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Marzahn-Hellersdorf'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Mitte'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Neukölln'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Pankow'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Reinickendorf'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Spandau'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Steglitz-Zehlendorf'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Tempelhof-Schöneberg'},
    {'gruppe': 'Jugendämter (Bezirke)', 'wert': 'Jugendamt Treptow-Köpenick'},

    // Teilhabefachdienste / Sozialämter (BTHG Stufe 3)
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Charlottenburg-Wilmersdorf'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Friedrichshain-Kreuzberg'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Lichtenberg'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Marzahn-Hellersdorf'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Mitte'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Neukölln'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Pankow'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Reinickendorf'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Spandau'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Steglitz-Zehlendorf'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Tempelhof-Schöneberg'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'Sozialamt Treptow-Köpenick'},
    {'gruppe': 'Sozialämter / Teilhabefachdienste', 'wert': 'LAGeSo – Eingliederungshilfe'},

    // Krankenkassen
    {'gruppe': 'Krankenkassen', 'wert': 'AOK Nordost'},
    {'gruppe': 'Krankenkassen', 'wert': 'Barmer'},
    {'gruppe': 'Krankenkassen', 'wert': 'Techniker Krankenkasse'},
    {'gruppe': 'Krankenkassen', 'wert': 'DAK-Gesundheit'},
    {'gruppe': 'Krankenkassen', 'wert': 'IKK Brandenburg und Berlin'},
    {'gruppe': 'Krankenkassen', 'wert': 'BKK VBU'},
    {'gruppe': 'Krankenkassen', 'wert': 'HEK – Hanseatische Krankenkasse'},
    {'gruppe': 'Krankenkassen', 'wert': 'Knappschaft'},
    {'gruppe': 'Krankenkassen', 'wert': 'Private Krankenversicherung'},

    // Arbeitsagentur / Rentenversicherung
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Agentur für Arbeit Berlin Mitte'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Agentur für Arbeit Berlin Nord'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Agentur für Arbeit Berlin Süd'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Jobcenter Berlin'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Deutsche Rentenversicherung Bund'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Deutsche Rentenversicherung Berlin-Brandenburg'},
    {'gruppe': 'Arbeitsagentur / Rentenversicherung', 'wert': 'Berufsgenossenschaft'},

    // Sonstige
    {'gruppe': 'Sonstige', 'wert': 'Eigenfinanzierung'},
    {'gruppe': 'Sonstige', 'wert': 'Sonstige'},
  ];

  // Flache Liste für Backward Compatibility
  static List<String> get alle =>
      alleGruppiert.map((e) => e['wert']!).toList();
}
