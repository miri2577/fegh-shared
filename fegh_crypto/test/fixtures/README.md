# Cross-App-Contract

Dieser Ordner enthaelt fixture JSON-Samples, die von FEGH-Dokumentation und
FEGH-Verwaltung unabhaengig erzeugt werden.

Der Contract-Test verifiziert, dass das `fegh_crypto`-Package jeden dieser
Records mit dem bekannten Test-MEK (32 Byte: 0..31) entschluesseln kann.

## Test-MEK (nur fuer Tests!)

```dart
final testMek = List<int>.generate(32, (i) => i);
// ergibt: [0, 1, 2, 3, ..., 30, 31]
```

## Sample-Records

- `doku_sample.json` — generiert von FEGH-Dokumentation mit `CryptoStorage`
- `verwaltung_sample.json` — generiert von FEGH-Verwaltung mit `CryptoStorage`

Beide sollten Klartext "FEGH Contract Test 2026" enthalten bei Entschluesselung.
