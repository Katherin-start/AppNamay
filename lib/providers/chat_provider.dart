import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final _service = ChatService();

  List<ChatContact> _contacts = [];
  List<ChatContact> get contacts => _contacts;

  // messages keyed by contactId
  final Map<String, List<ChatMessage>> _messages = {};
  List<ChatMessage> messagesFor(String contactId) => _messages[contactId] ?? [];

  // unread count per contact
  final Map<String, int> _unread = {};
  int unreadFor(String contactId) => _unread[contactId] ?? 0;
  int get totalUnread => _unread.values.fold(0, (a, b) => a + b);

  bool _loadingContacts = false;
  bool get loadingContacts => _loadingContacts;

  String? _activeContactId;
  String? get activeContactId => _activeContactId;

  // comprobante received from cashier
  Map<String, dynamic>? _lastComprobante;
  Map<String, dynamic>? get lastComprobante => _lastComprobante;

  void init(String myUserId) {
    SocketService.instance.registerChatHandler((msg) {
      _onIncomingMessage(msg, myUserId);
    });
    SocketService.instance.registerComprobanteHandler((data) {
      _lastComprobante = data;
      notifyListeners();
    });
  }

  void _onIncomingMessage(Map<String, dynamic> msg, String myId) {
    final senderId = msg['remitente_id']?.toString() ?? msg['id_usuario']?.toString() ?? '';
    final destId   = msg['destinatario_id']?.toString() ?? '';
    // The other participant is whoever isn't me
    final contactId = senderId == myId ? destId : senderId;
    if (contactId.isEmpty) return;

    final chatMsg = ChatMessage.fromJson(msg);
    final list = _messages.putIfAbsent(contactId, () => []);
    // Avoid duplicates
    if (!list.any((m) => m.id == chatMsg.id && m.id.isNotEmpty)) {
      list.add(chatMsg);
    }

    if (_activeContactId != contactId) {
      _unread[contactId] = (_unread[contactId] ?? 0) + 1;
    }

    notifyListeners();
  }

  Future<void> loadContacts() async {
    _loadingContacts = true;
    notifyListeners();
    _contacts = await _service.getContacts();
    _loadingContacts = false;
    notifyListeners();
  }

  Future<void> loadMessages(String contactId, String myId) async {
    _activeContactId = contactId;
    _unread[contactId] = 0;
    final msgs = await _service.getMessages(contactId);
    _messages[contactId] = msgs;
    notifyListeners();
    // Mark as read
    await _service.markAsRead(contactId, myId);
  }

  void sendMessageViaSocket({
    required String myId,
    required String contactId,
    required String contenido,
  }) {
    if (contenido.trim().isEmpty) return;
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      conversacionId: '',
      senderId: myId,
      contenido: contenido.trim(),
      leido: false,
      fecha: DateTime.now(),
    );
    final list = _messages.putIfAbsent(contactId, () => []);
    list.add(tempMsg);
    notifyListeners();

    SocketService.instance.sendChatMessage(
      remitenteId: myId,
      destinatarioId: contactId,
      contenido: contenido.trim(),
    );
  }

  void onMessageSentConfirmed(Map<String, dynamic> data, String contactId) {
    final confirmed = ChatMessage.fromJson(data);
    final list = _messages[contactId] ?? [];
    // Replace temp message (last optimistic one from me with same text)
    final idx = list.lastIndexWhere(
      (m) => m.id.startsWith('tmp_') && m.contenido == confirmed.contenido,
    );
    if (idx >= 0) {
      list[idx] = confirmed;
    } else if (!list.any((m) => m.id == confirmed.id)) {
      list.add(confirmed);
    }
    _messages[contactId] = list;
    notifyListeners();
  }

  void clearActiveContact() {
    _activeContactId = null;
  }

  void clearComprobante() {
    _lastComprobante = null;
    notifyListeners();
  }

  void updateContactStatus(String userId, bool online) {
    final idx = _contacts.indexWhere((c) => c.id == userId);
    if (idx >= 0) {
      final c = _contacts[idx];
      _contacts[idx] = ChatContact(
        id: c.id,
        nombre: c.nombre,
        fotoPerfil: c.fotoPerfil,
        rol: c.rol,
        online: online,
        lastSeen: c.lastSeen,
        isAssignedDoctor: c.isAssignedDoctor,
      );
      notifyListeners();
    }
  }
}
