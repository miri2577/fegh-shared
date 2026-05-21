import 'package:flutter/material.dart';

import 'chat_room_screen.dart';
import 'matrix_chat_service.dart';

/// Uebersicht aller Chats (Raeume). Zeigt bei nicht-angemeldetem User
/// das Login-Formular; danach die Raum-Liste mit ungelesenen Markern.
class ChatListScreen extends StatefulWidget {
  final MatrixChatService chatService;

  const ChatListScreen({super.key, required this.chatService});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoggingIn = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.chatService.isLoggedIn) {
      return _buildLoginView(theme);
    }

    return _buildChatList(theme);
  }

  Widget _buildLoginView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Verschluesselter Chat', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Melden Sie sich an um den verschluesselten Team-Chat zu nutzen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoggingIn ? null : _login,
                icon: _isLoggingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoggingIn ? 'Verbinde...' : 'Anmelden'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoggingIn ? null : _register,
              icon: const Icon(Icons.person_add),
              label: const Text('Registrieren'),
            ),
            const SizedBox(height: 16),
            Text(
              'Server: ${widget.chatService.defaultHomeserver}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) return;
    setState(() => _isLoggingIn = true);
    final ok = await widget.chatService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoggingIn = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Anmeldung fehlgeschlagen'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _register() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) return;
    setState(() => _isLoggingIn = true);
    final ok = await widget.chatService.register(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoggingIn = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registriert! Sie sind angemeldet.'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registrierung fehlgeschlagen'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildChatList(ThemeData theme) {
    final client = widget.chatService.client!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat (${client.userID ?? ""})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () async {
              await widget.chatService.logout();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.edit),
      ),
      body: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) {
          final rooms = client.rooms
            ..sort((a, b) => (b.lastEvent?.originServerTs ?? DateTime(0))
                .compareTo(a.lastEvent?.originServerTs ?? DateTime(0)));

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('Noch keine Chats'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _showNewChatDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Neuen Chat starten'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final lastEvent = room.lastEvent;
              final isUnread = room.isUnreadOrInvited;
              final isEncrypted = room.encrypted;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isUnread
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    (room.getLocalizedDisplayname().isNotEmpty
                            ? room.getLocalizedDisplayname()[0]
                            : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      color: isUnread
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.getLocalizedDisplayname(),
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEncrypted)
                      Icon(Icons.lock,
                          size: 14, color: Colors.green.shade700),
                  ],
                ),
                subtitle: lastEvent != null
                    ? Text(
                        lastEvent.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: isUnread
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        room: room,
                        chatService: widget.chatService,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showNewChatDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Benutzername oder Raumname',
                hintText: '@user:<homeserver> oder Team-Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final input = controller.text.trim();
              Navigator.pop(ctx);
              if (input.startsWith('@')) {
                await widget.chatService.createDirectChat(input);
              } else if (input.isNotEmpty) {
                await widget.chatService.createTeamRoom(input);
              }
              if (mounted) setState(() {});
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
}
