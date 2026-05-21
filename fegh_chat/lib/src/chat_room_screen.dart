import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import 'matrix_chat_service.dart';

/// Einzelner Chat-Raum mit Nachrichtenverlauf.
class ChatRoomScreen extends StatefulWidget {
  final Room room;
  final MatrixChatService chatService;

  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.chatService,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timeline? _timeline;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      _timeline = await widget.room.getTimeline(
        onChange: (_) {
          if (mounted) setState(() {});
        },
      );
      // Als gelesen markieren
      if (widget.room.isUnreadOrInvited) {
        await widget.room.setReadMarker(
          widget.room.lastEvent?.eventId ?? '',
        );
      }
    } catch (e) {
      debugPrint('[CHAT] Timeline laden fehlgeschlagen: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timeline?.cancelSubscriptions();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await widget.chatService.sendMessage(widget.room.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = widget.chatService.client;
    final myUserId = client?.userID;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.room.getLocalizedDisplayname(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.room.encrypted)
              Tooltip(
                message: 'Ende-zu-Ende verschluesselt',
                child: Icon(Icons.lock,
                    size: 18, color: Colors.green.shade700),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video-Anruf',
            onPressed: () => _startCall(true),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Audio-Anruf',
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip:
                '${widget.room.summary.mJoinedMemberCount ?? 0} Mitglieder',
            onPressed: _showMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _timeline == null || _timeline!.events.isEmpty
                    ? Center(
                        child: Text(
                          'Noch keine Nachrichten',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _timeline!.events.length,
                        itemBuilder: (context, index) {
                          final event = _timeline!.events[index];

                          if (event.type != EventTypes.Message) {
                            if (event.type == EventTypes.RoomMember) {
                              return _buildSystemMessage(
                                theme,
                                '${event.senderFromMemoryOrFallback.displayName ?? event.senderId} ist beigetreten',
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final isMe = event.senderId == myUserId;
                          return _buildMessageBubble(theme, event, isMe);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sendAttachment,
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Datei senden',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nachricht schreiben...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, Event event, bool isMe) {
    final senderName =
        event.senderFromMemoryOrFallback.displayName ?? event.senderId;
    final time =
        '${event.originServerTs.hour}:${event.originServerTs.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(event.body),
            Text(
              time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Future<void> _startCall(bool video) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(video
            ? 'Video-Anruf wird gestartet...'
            : 'Audio-Anruf wird gestartet...'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(video ? Icons.videocam : Icons.call, size: 48),
        title: Text(video ? 'Video-Anruf' : 'Audio-Anruf'),
        content: const Text(
          'Anrufe sind aktuell ueber Element Web verfuegbar.\n\n'
          'Oeffnen Sie app.element.io in Ihrem Browser und starten Sie den Anruf dort.\n\n'
          'Die native Integration in die App wird in einem zukuenftigen Update ergaenzt.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _sendAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;

      final matrixFile = MatrixFile(
        bytes: file.bytes!,
        name: file.name,
      );
      final ok =
          await widget.chatService.sendFile(widget.room.id, matrixFile);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Datei senden fehlgeschlagen'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('[CHAT] Attachment fehlgeschlagen: $e');
    }
  }

  void _showMembers() {
    showDialog(
      context: context,
      builder: (ctx) {
        final members = widget.room.getParticipants();
        return AlertDialog(
          title: Text('Mitglieder (${members.length})'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (_, i) {
                final m = members[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    child:
                        Text((m.displayName ?? m.id)[0].toUpperCase()),
                  ),
                  title: Text(m.displayName ?? m.id),
                  subtitle: Text(m.id, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        );
      },
    );
  }
}
