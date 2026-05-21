# fegh-shared

Geteilte Flutter-/Dart-Pakete für die FEGH-Apps (`FEGH-Dokumentation`, `FEGH-Verwaltung`).

## Pakete

| Paket | Zweck |
|---|---|
| `fegh_core` | Gemeinsame Domänen-Modelle (Client, Bundesland, Employee, Team, Shift) |
| `fegh_crypto` | Verschlüsselungs-Primitive |
| `fegh_cloud` | Cloud-Storage-Adapter (WebDAV via `webdav_client`) |
| `fegh_billing` | Rechnungsmodul (Models + XRechnung UBL 2.1) |
| `fegh_compliance` | Audit-Log + DSGVO-Services |
| `fegh_pdf_kit` | PDF-Toolkit (Design-Tokens, Layout-Bausteine, Preview) |
| `fegh_backup` | Backup + Recovery (RecoveryService, BackupCodec, BackupEnvelope) |
| `fegh_chat` | Matrix-Chat (MatrixChatService, ChatListScreen, ChatRoomScreen) |
| `fegh_auth_oidc` | OIDC-Authentifizierung |

## Verwendung

Diese Pakete werden von den FEGH-Apps eingebunden – primär via `git:`-Dependency auf dieses Repo, lokal optional via `pubspec_overrides.yaml` (path).

## Lizenz

Privat / unveröffentlicht.
