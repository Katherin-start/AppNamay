import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth   = context.read<AuthProvider>();
      final chat   = context.read<ChatProvider>();
      final myId   = auth.profile?['id']?.toString() ?? '';
      chat.init(myId);
      chat.loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final myId = auth.profile?['id']?.toString() ?? '';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: chat.loadContacts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: chat.loadingContacts
          ? const Center(child: CircularProgressIndicator())
          : chat.contacts.isEmpty
              ? _EmptyState(onRetry: chat.loadContacts)
              : RefreshIndicator(
                  onRefresh: chat.loadContacts,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.contacts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 76, endIndent: 16),
                    itemBuilder: (context, i) {
                      final contact = chat.contacts[i];
                      final unread  = chat.unreadFor(contact.id);
                      return _ContactTile(
                        contact: contact,
                        unread: unread,
                        myId: myId,
                      );
                    },
                  ),
                ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ChatContact contact;
  final int unread;
  final String myId;

  const _ContactTile({
    required this.contact,
    required this.unread,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primary.withOpacity(0.12),
            backgroundImage: contact.fotoPerfil != null
                ? NetworkImage(contact.fotoPerfil!)
                : null,
            child: contact.fotoPerfil == null
                ? Text(
                    contact.nombre.isNotEmpty
                        ? contact.nombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: contact.online ? Colors.green : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.nombre,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (contact.isAssignedDoctor)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mi doctor',
                style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text(
        contact.rolLabel,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: unread > 0
          ? Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  unread > 9 ? '9+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              contactId: contact.id,
              contactName: contact.nombre,
              contactRole: contact.rolLabel,
              contactPhoto: contact.fotoPerfil,
              myId: myId,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay contactos disponibles',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Agenda una cita para comunicarte\ncon tu odontóloga',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
