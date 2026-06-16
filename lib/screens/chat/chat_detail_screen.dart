import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactRole;
  final String? contactPhoto;
  final String myId;

  const ChatDetailScreen({
    Key? key,
    required this.contactId,
    required this.contactName,
    required this.contactRole,
    this.contactPhoto,
    required this.myId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _isTyping     = false;
  bool _otherTyping  = false;
  bool _loading      = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Listen for message_sent confirmation
    SocketService.instance.registerMessageSentHandler((data) {
      if (!mounted) return;
      context.read<ChatProvider>().onMessageSentConfirmed(data, widget.contactId);
      _scrollToBottom();
    });
    // Listen typing from other side
    SocketService.instance.registerTypingHandler((fromId, isTyping) {
      if (!mounted) return;
      if (fromId == widget.contactId) {
        setState(() => _otherTyping = isTyping);
      }
    });
  }

  Future<void> _load() async {
    final chat = context.read<ChatProvider>();
    await chat.loadMessages(widget.contactId, widget.myId);
    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().sendMessageViaSocket(
      myId: widget.myId,
      contactId: widget.contactId,
      contenido: text,
    );
    _scrollToBottom();
    _setTyping(false);
  }

  void _setTyping(bool v) {
    if (_isTyping == v) return;
    _isTyping = v;
    SocketService.instance.emitTyping(
      from: widget.myId,
      to: widget.contactId,
      isTyping: v,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().clearActiveContact();
    _setTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat     = context.watch<ChatProvider>();
    final messages = chat.messagesFor(widget.contactId);
    final primary  = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        leadingWidth: 36,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: widget.contactPhoto != null
                  ? NetworkImage(widget.contactPhoto!)
                  : null,
              child: widget.contactPhoto == null
                  ? Text(
                      widget.contactName.isNotEmpty
                          ? widget.contactName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _otherTyping ? 'escribiendo...' : widget.contactRole,
                    style: TextStyle(
                      fontSize: 11,
                      color: _otherTyping ? Colors.greenAccent : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'Escribe el primer mensaje',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg  = messages[i];
                          final mine = msg.isMine(widget.myId);
                          final showDate = i == 0 ||
                              messages[i].fecha.day != messages[i - 1].fecha.day;
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.fecha),
                              _MessageBubble(msg: msg, mine: mine, primaryColor: primary),
                            ],
                          );
                        },
                      ),
          ),
          if (_otherTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${widget.contactName} está escribiendo...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          _InputBar(
            controller: _controller,
            onSend: _send,
            onChanged: (v) => _setTyping(v.isNotEmpty),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool mine;
  final Color primaryColor;

  const _MessageBubble({
    required this.msg,
    required this.mine,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.contenido,
              style: TextStyle(
                color: mine ? Colors.white : Colors.black87,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(msg.fecha),
              style: TextStyle(
                color: mine ? Colors.white60 : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = 'Hoy';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Ayer';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
