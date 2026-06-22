import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/backend_config.dart';

typedef AppointmentCallback  = void Function(Map<String, dynamic> data);
typedef ChatMessageCallback  = void Function(Map<String, dynamic> data);
typedef StatusChangeCallback = void Function(String userId, bool online);
typedef TypingCallback       = void Function(String fromId, bool isTyping);
typedef CallEventCallback    = void Function(Map<String, dynamic> data);

class SocketService {
  static final SocketService instance = SocketService._internal();
  IO.Socket? _socket;

  // Appointment handlers
  AppointmentCallback? _onAppointmentEvent;
  AppointmentCallback? _onNewAppointmentEvent;

  // Chat handlers
  ChatMessageCallback?  _onNewMessage;
  ChatMessageCallback?  _onMessageSent;
  ChatMessageCallback?  _onComprobante;
  StatusChangeCallback? _onUserStatus;
  TypingCallback?       _onTyping;

  // Call (WebRTC signaling) handlers
  CallEventCallback? _onIncomingCall;
  CallEventCallback? _onCallAccepted;
  CallEventCallback? _onCallRejected;
  CallEventCallback? _onCallCancelled;
  CallEventCallback? _onCallEnded;
  CallEventCallback? _onWebrtcOffer;
  CallEventCallback? _onWebrtcAnswer;
  CallEventCallback? _onWebrtcIceCandidate;

  SocketService._internal();

  // ── Registration ────────────────────────────────────────────

  void registerAppointmentHandler(AppointmentCallback cb)    => _onAppointmentEvent    = cb;
  void registerNewAppointmentHandler(AppointmentCallback cb) => _onNewAppointmentEvent = cb;
  void registerChatHandler(ChatMessageCallback cb)           => _onNewMessage           = cb;
  void registerMessageSentHandler(ChatMessageCallback cb)    => _onMessageSent          = cb;
  void registerComprobanteHandler(AppointmentCallback cb)    => _onComprobante          = cb;
  void registerUserStatusHandler(StatusChangeCallback cb)    => _onUserStatus           = cb;
  void registerTypingHandler(TypingCallback cb)              => _onTyping               = cb;

  void registerIncomingCallHandler(CallEventCallback cb)        => _onIncomingCall        = cb;
  void registerCallAcceptedHandler(CallEventCallback cb)        => _onCallAccepted        = cb;
  void registerCallRejectedHandler(CallEventCallback cb)        => _onCallRejected        = cb;
  void registerCallCancelledHandler(CallEventCallback cb)       => _onCallCancelled       = cb;
  void registerCallEndedHandler(CallEventCallback cb)           => _onCallEnded           = cb;
  void registerWebrtcOfferHandler(CallEventCallback cb)         => _onWebrtcOffer         = cb;
  void registerWebrtcAnswerHandler(CallEventCallback cb)        => _onWebrtcAnswer        = cb;
  void registerWebrtcIceCandidateHandler(CallEventCallback cb)  => _onWebrtcIceCandidate  = cb;

  // ── Connect ─────────────────────────────────────────────────

  void connect({required String token, String? userId}) {
    try {
      final base = BackendConfig.apiBaseUrl.replaceFirst('/api', '');
      _socket?.disconnect();

      _socket = IO.io(base, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'forceNew': true,
        'query': {'token': token, 'userId': userId},
      });

      _socket?.on('connect', (_) {
        print('SocketService: connected');
        if (userId != null) {
          _socket?.emit('join', userId);
          print('SocketService: joined room user_$userId');
        }
      });

      _socket?.on('disconnect', (_) => print('SocketService: disconnected'));
      _socket?.on('connect_error', (err) => print('SocketService: connect_error -> $err'));
      _socket?.on('error', (err) => print('SocketService: error -> $err'));
      _socket?.on('reconnect', (_) {
        print('SocketService: reconnected');
        if (userId != null) _socket?.emit('join', userId);
      });

      // ── Appointment events ──────────────────────────────────

      _socket?.on('appointment_status_changed', (payload) {
        _safeCall(_onAppointmentEvent, payload);
      });

      _socket?.on('new_mobile_appointment', (payload) {
        _safeCall(_onNewAppointmentEvent, payload);
      });

      _socket?.on('payment_proof_received', (payload) {
        _safeCall(_onAppointmentEvent, payload);
      });

      _socket?.on('payment_approved_invoice_generated', (payload) {
        _safeCall(_onComprobante, payload);
        _safeCall(_onAppointmentEvent, payload);
      });

      // ── Chat events ─────────────────────────────────────────

      _socket?.on('new_message', (payload) {
        _safeCall(_onNewMessage, payload);
      });

      _socket?.on('message_sent', (payload) {
        _safeCall(_onMessageSent, payload);
      });

      _socket?.on('user_typing', (payload) {
        try {
          final data = _toMap(payload);
          final fromId   = data['from']?.toString() ?? '';
          final isTyping = data['isTyping'] == true;
          if (fromId.isNotEmpty && _onTyping != null) _onTyping!(fromId, isTyping);
        } catch (_) {}
      });

      _socket?.on('user_status_changed', (payload) {
        try {
          final data = _toMap(payload);
          final userId = data['userId']?.toString() ?? '';
          final online = data['online'] == true;
          if (userId.isNotEmpty && _onUserStatus != null) {
            _onUserStatus!(userId, online);
          }
        } catch (_) {}
      });

      // ── Call events (señalización WebRTC) ───────────────────

      _socket?.on('incoming_call',        (payload) => _safeCall(_onIncomingCall, payload));
      _socket?.on('call_accepted',        (payload) => _safeCall(_onCallAccepted, payload));
      _socket?.on('call_rejected',        (payload) => _safeCall(_onCallRejected, payload));
      _socket?.on('call_cancelled',       (payload) => _safeCall(_onCallCancelled, payload));
      _socket?.on('call_ended',           (payload) => _safeCall(_onCallEnded, payload));
      _socket?.on('webrtc_offer',         (payload) => _safeCall(_onWebrtcOffer, payload));
      _socket?.on('webrtc_answer',        (payload) => _safeCall(_onWebrtcAnswer, payload));
      _socket?.on('webrtc_ice_candidate', (payload) => _safeCall(_onWebrtcIceCandidate, payload));
    } catch (e) {
      print('SocketService connect error: $e');
    }
  }

  // ── Send chat message ────────────────────────────────────────

  void sendChatMessage({
    required String remitenteId,
    required String destinatarioId,
    required String contenido,
  }) {
    _socket?.emit('send_message', {
      'remitente_id': remitenteId,
      'destinatario_id': destinatarioId,
      'contenido': contenido,
      'tipo': 'texto',
    });
  }

  void emitTyping({required String from, required String to, required bool isTyping}) {
    _socket?.emit('typing', {'from': from, 'to': to, 'isTyping': isTyping});
  }

  void emitMarkAsRead({required String userId, required String otherUserId}) {
    _socket?.emit('mark_as_read', {'userId': userId, 'otherUserId': otherUserId});
  }

  // ── Call (señalización WebRTC) ──────────────────────────────

  void emitCallInvite({required String fromId, required String toId, String? fromNombre}) {
    _socket?.emit('call_invite', {'from_id': fromId, 'to_id': toId, 'from_nombre': fromNombre});
  }

  void emitCallAccept({required String fromId, required String toId}) {
    _socket?.emit('call_accept', {'from_id': fromId, 'to_id': toId});
  }

  void emitCallReject({required String fromId, required String toId, String? reason}) {
    _socket?.emit('call_reject', {'from_id': fromId, 'to_id': toId, 'reason': reason});
  }

  void emitCallCancel({required String fromId, required String toId}) {
    _socket?.emit('call_cancel', {'from_id': fromId, 'to_id': toId});
  }

  void emitCallEnd({required String fromId, required String toId}) {
    _socket?.emit('call_end', {'from_id': fromId, 'to_id': toId});
  }

  void emitWebrtcOffer({required String fromId, required String toId, required Map<String, dynamic> sdp}) {
    _socket?.emit('webrtc_offer', {'from_id': fromId, 'to_id': toId, 'sdp': sdp});
  }

  void emitWebrtcAnswer({required String fromId, required String toId, required Map<String, dynamic> sdp}) {
    _socket?.emit('webrtc_answer', {'from_id': fromId, 'to_id': toId, 'sdp': sdp});
  }

  void emitWebrtcIceCandidate({required String fromId, required String toId, required Map<String, dynamic> candidate}) {
    _socket?.emit('webrtc_ice_candidate', {'from_id': fromId, 'to_id': toId, 'candidate': candidate});
  }

  // ── Disconnect ───────────────────────────────────────────────

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket = null;
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────

  Map<String, dynamic> _toMap(dynamic payload) =>
      payload is Map ? Map<String, dynamic>.from(payload) : <String, dynamic>{};

  void _safeCall(void Function(Map<String, dynamic>)? cb, dynamic payload) {
    try {
      if (cb != null) cb(_toMap(payload));
    } catch (_) {}
  }
}
