/// Gemeinsame Krypto-Primitive fuer FEGH-Dokumentation und FEGH-Verwaltung.
///
/// Wire-Format muss bit-identisch zwischen beiden Apps sein, damit der
/// HiDrive-Sync funktioniert. Dieses Package ist die Single Source of Truth
/// fuer:
///   - EncryptedRecord Serialisierung (JSON Map)
///   - AES-256-GCM mit DEK-Wrapping ueber MEK
///   - AAD-Handling (canonical JSON encoding)
library;

export 'src/encrypted_record.dart';
export 'src/crypto_primitives.dart';
export 'src/provisioning_token.dart';
