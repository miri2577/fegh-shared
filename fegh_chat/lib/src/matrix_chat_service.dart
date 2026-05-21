import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

/// Matrix-Chat-Service fuer verschluesselte Team-Kommunikation.
///
/// Konfigurierbar ueber den Konstruktor — homeserver, appName und
/// databaseName koennen von jeder FEGH-App individuell gesetzt werden.
class MatrixChatService {
  final String defaultHomeserver;
  final String appName;
  final String databaseName;

  Client? _client;
  bool _isInitialized = false;

  MatrixChatService({
    this.defaultHomeserver = 'https://cavia-aperea.de',
    this.appName = 'FEGH',
    this.databaseName = 'fegh_matrix',
  });

  Client? get client => _client;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _client?.isLogged() ?? false;

  /// Initialisiert den Matrix-Client (lokale Datenbank + Client).
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final db = await MatrixSdkDatabase.init(databaseName);
      _client = Client(
        appName,
        database: db,
        supportedLoginTypes: {AuthenticationTypes.password},
      );
      await _client!.init();
      _isInitialized = true;
      debugPrint('[MATRIX] Client initialisiert');
    } catch (e) {
      debugPrint('[MATRIX] Init Fehler: $e');
    }
  }

  /// Registriert einen neuen User auf dem Homeserver.
  Future<bool> register({
    required String username,
    required String password,
    String? homeserver,
  }) async {
    if (_client == null) await initialize();
    try {
      await _client!.checkHomeserver(Uri.parse(homeserver ?? defaultHomeserver));
      await _client!.uiaRequestBackground(
        (auth) => _client!.register(
          username: username,
          password: password,
          auth: auth,
        ),
      );
      debugPrint('[MATRIX] Registriert: @$username');
      return true;
    } catch (e) {
      debugPrint('[MATRIX] Registrierung fehlgeschlagen: $e');
      return false;
    }
  }

  /// Login mit Username und Passwort.
  Future<bool> login({
    required String username,
    required String password,
    String? homeserver,
  }) async {
    if (_client == null) await initialize();
    try {
      await _client!.checkHomeserver(Uri.parse(homeserver ?? defaultHomeserver));
      await _client!.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: username),
        password: password,
      );
      debugPrint('[MATRIX] Login OK: ${_client!.userID}');
      return true;
    } catch (e) {
      debugPrint('[MATRIX] Login fehlgeschlagen: $e');
      return false;
    }
  }

  /// Logout.
  Future<void> logout() async {
    try {
      await _client?.logout();
      debugPrint('[MATRIX] Logout');
    } catch (e) {
      debugPrint('[MATRIX] Logout Fehler: $e');
    }
  }

  /// Erstellt einen verschluesselten Raum fuer ein Team.
  Future<String?> createTeamRoom(String teamName) async {
    if (_client == null || !isLoggedIn) return null;
    try {
      final roomId = await _client!.createRoom(
        name: teamName,
        preset: CreateRoomPreset.privateChat,
        initialState: [
          StateEvent(
            type: EventTypes.Encryption,
            stateKey: '',
            content: {'algorithm': 'm.megolm.v1.aes-sha2'},
          ),
        ],
      );
      debugPrint('[MATRIX] Team-Raum erstellt: $roomId');
      return roomId;
    } catch (e) {
      debugPrint('[MATRIX] Raum erstellen fehlgeschlagen: $e');
      return null;
    }
  }

  /// Erstellt einen verschluesselten 1:1 Chat.
  Future<String?> createDirectChat(String userId) async {
    if (_client == null || !isLoggedIn) return null;
    try {
      final roomId = await _client!.startDirectChat(
        userId,
        enableEncryption: true,
      );
      debugPrint('[MATRIX] Direktchat erstellt: $roomId mit $userId');
      return roomId;
    } catch (e) {
      debugPrint('[MATRIX] Direktchat fehlgeschlagen: $e');
      return null;
    }
  }

  /// Laedt einen User in einen Raum ein.
  Future<bool> inviteToRoom(String roomId, String userId) async {
    if (_client == null || !isLoggedIn) return false;
    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) return false;
      await room.invite(userId);
      debugPrint('[MATRIX] $userId eingeladen in $roomId');
      return true;
    } catch (e) {
      debugPrint('[MATRIX] Einladung fehlgeschlagen: $e');
      return false;
    }
  }

  /// Sendet eine verschluesselte Textnachricht.
  Future<bool> sendMessage(String roomId, String message) async {
    if (_client == null || !isLoggedIn) return false;
    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) return false;
      await room.sendTextEvent(message);
      return true;
    } catch (e) {
      debugPrint('[MATRIX] Senden fehlgeschlagen: $e');
      return false;
    }
  }

  /// Alle Raeume (Chats) des Users.
  List<Room> get rooms => _client?.rooms ?? [];

  /// Alle Raeume mit ungelesenen Nachrichten.
  int get unreadCount {
    if (_client == null) return 0;
    return _client!.rooms.where((r) => r.isUnreadOrInvited).length;
  }

  /// Erstellt einen neuen Matrix-User auf dem Server (Admin-Funktion).
  /// Nutzt die Registration-API direkt per HTTP. Nur zulaessig, wenn der
  /// Server-Admin-Token vorhanden ist — auf Conduit-Servern mit offener
  /// Registrierung reicht ein Dummy-Auth.
  static Future<Map<String, dynamic>?> createUserOnServer({
    required String username,
    required String password,
    String homeserver = 'https://cavia-aperea.de',
  }) async {
    try {
      final url = '$homeserver/_matrix/client/v3/register';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'auth': {'type': 'm.login.dummy'},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[MATRIX] User erstellt: @$username');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint(
            '[MATRIX] User-Erstellung fehlgeschlagen: ${error['error'] ?? response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[MATRIX] createUserOnServer error: $e');
      return null;
    }
  }

  /// Sendet eine Datei (Bild, Dokument) in einen Raum.
  Future<bool> sendFile(String roomId, MatrixFile file) async {
    if (_client == null || !isLoggedIn) return false;
    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) return false;
      await room.sendFileEvent(file);
      return true;
    } catch (e) {
      debugPrint('[MATRIX] Datei senden fehlgeschlagen: $e');
      return false;
    }
  }

  /// Raeumt auf (Client-Dispose). Danach muss `initialize()` erneut gerufen werden.
  Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
    _isInitialized = false;
  }
}
