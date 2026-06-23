import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import '../config/backend_config.dart';
import 'storage_service.dart';

class ChatContact {
  final String id;
  final String nombre;
  final String? fotoPerfil;
  final String rol;
  final bool online;
  final String? lastSeen;
  final bool isAssignedDoctor;

  ChatContact({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    required this.rol,
    required this.online,
    this.lastSeen,
    this.isAssignedDoctor = false,
  });

  factory ChatContact.fromJson(Map<String, dynamic> j) => ChatContact(
        id: j['id']?.toString() ?? '',
        nombre: j['nombre']?.toString() ?? 'Sin nombre',
        fotoPerfil: j['foto_perfil']?.toString(),
        rol: j['rol']?.toString() ?? 'STAFF',
        online: j['online'] == true,
        lastSeen: j['last_seen']?.toString(),
        isAssignedDoctor: j['is_assigned_doctor'] == true,
      );

  String get rolLabel {
    switch (rol.toUpperCase()) {
      case 'ODONTOLOGO':
        return 'Odontóloga';
      case 'ADMINISTRADOR':
        return 'Administración';
      case 'RECEPCIONISTA':
        return 'Recepción';
      case 'CAJERO':
        return 'Caja';
      default:
        return rol;
    }
  }
}

class ChatMessage {
  final String id;
  final String conversacionId;
  final String senderId;
  final String contenido;
  final bool leido;
  final DateTime fecha;
  final String tipo;
  final String? attachmentUrl;
  final String? attachmentName;

  ChatMessage({
    required this.id,
    required this.conversacionId,
    required this.senderId,
    required this.contenido,
    required this.leido,
    required this.fecha,
    this.tipo = 'texto',
    this.attachmentUrl,
    this.attachmentName,
  });

  bool get isImage => tipo == 'imagen' && attachmentUrl != null;
  bool get isAttachment => attachmentUrl != null;

  // Perú no usa horario de verano, siempre es UTC-5.
  static DateTime _toPeruTime(DateTime dt) {
    return dt.toUtc().add(const Duration(hours: -5));
  }

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final rawFecha = j['fecha'] ?? j['fecha_envio'] ?? j['created_at'] ?? '';
    DateTime parsedDate;
    try {
      parsedDate = (rawFecha as String).isNotEmpty
          ? _toPeruTime(DateTime.parse(rawFecha))
          : _toPeruTime(DateTime.now());
    } catch (_) {
      parsedDate = _toPeruTime(DateTime.now());
    }
    return ChatMessage(
      id: j['id']?.toString() ?? '',
      conversacionId: j['id_conversacion']?.toString() ?? '',
      senderId: j['id_usuario']?.toString() ?? j['remitente_id']?.toString() ?? '',
      contenido: j['mensaje']?.toString() ?? j['contenido']?.toString() ?? '',
      leido: j['leido'] == true,
      fecha: parsedDate,
      tipo: j['tipo']?.toString() ?? 'texto',
      attachmentUrl: j['attachment_url']?.toString(),
      attachmentName: j['attachment_name']?.toString(),
    );
  }

  bool isMine(String myId) => senderId == myId;
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _storage = StorageService();

  Future<String?> _token() => _storage.getAuthToken();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<ChatContact>> getContacts() async {
    try {
      final token = await _token();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse(BackendConfig.mobileChatContactsUrl),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['contacts'] as List? ?? [];
        return list
            .map((e) => ChatContact.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      debugPrint('getContacts ${res.statusCode}');
      return [];
    } catch (e) {
      debugPrint('getContacts error: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getMessages(String withUserId) async {
    try {
      final token = await _token();
      if (token == null) return [];
      final res = await http.get(
        Uri.parse(BackendConfig.chatHistoryUrl(withUserId)),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body is Map ? (body['messages'] ?? body['mensajes'] ?? []) : body) as List? ?? [];
        return list
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('getMessages error: $e');
      return [];
    }
  }

  Future<void> markAsRead(String withUserId, String myId) async {
    try {
      final token = await _token();
      if (token == null) return;
      await http.post(
        Uri.parse(BackendConfig.chatMarkReadUrl),
        headers: _headers(token),
        body: jsonEncode({'userId': myId, 'otherUserId': withUserId}),
      );
    } catch (_) {}
  }

  /// Upload an attachment (image/document) as a chat message.
  /// Posts a multipart request to `BackendConfig.chatUploadUrl`, which the backend
  /// handles with multer + Supabase storage (see `uploadChatAttachment` controller).
  /// Expected fields: `destinatario_id`, optional `caption`, and file under `file`.
  Future<Map<String, dynamic>?> uploadAttachment(
    String remitenteId,
    String destinatarioId,
    File file,
    String filename, {
    String? mensaje,
  }) async {
    try {
      final token = await _token();
      if (token == null) return null;
      final uri = Uri.parse(BackendConfig.chatUploadUrl);
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';
      req.fields['destinatario_id'] = destinatarioId;
      if (mensaje != null) req.fields['caption'] = mensaje;
      final bytes = await file.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) return body['message'] ?? body;
        return {'message': body};
      }
      debugPrint('uploadAttachment failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      debugPrint('uploadAttachment error: $e');
      return null;
    }
  }
}
