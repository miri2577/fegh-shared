/// Gemeinsames Matrix-Chat-Modul fuer FEGH-Apps.
///
/// Verschluesselter Team-Chat ueber einen Matrix-Homeserver (Default:
/// Conduit auf `cavia-aperea.de`, konfigurierbar). Exponiert:
///
/// - [MatrixChatService] — Lifecycle (init/login/logout), CRUD fuer
///   Raeume und Nachrichten, File-Upload, Admin-User-Creation.
/// - [ChatListScreen] — Startscreen mit Login-Fallback und Raum-Liste.
/// - [ChatRoomScreen] — Einzel-Raum mit Timeline, Eingabe, Attachments
///   und Member-Dialog.
///
/// Beide Screens sind thematisch neutral (Material-3-Farben, keine
/// FEGH-Logos) und koennen von jeder App eingebunden werden.
library;

export 'src/matrix_chat_service.dart';
export 'src/chat_list_screen.dart';
export 'src/chat_room_screen.dart';
