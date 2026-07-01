import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'socket_service.dart';

enum CallStatus { idle, calling, ringing, inCall }

/// Llamada de audio 1 a 1 (WebRTC) señalizada por Socket.IO.
/// El servidor solo reenvía mensajes de señalización (ver
/// backend/src/socket/chatSocket.js); el audio viaja peer-to-peer.
class CallService extends ChangeNotifier {
  final String myId;
  final String myNombre;

  CallService({required this.myId, required this.myNombre}) {
    SocketService.instance.registerIncomingCallHandler(_onIncomingCall);
    SocketService.instance.registerCallAcceptedHandler(_onCallAccepted);
    SocketService.instance.registerCallRejectedHandler(_onCallRejected);
    SocketService.instance.registerCallCancelledHandler(_onCallCancelled);
    SocketService.instance.registerCallEndedHandler(_onCallEnded);
    SocketService.instance.registerWebrtcOfferHandler(_onOffer);
    SocketService.instance.registerWebrtcAnswerHandler(_onAnswer);
    SocketService.instance.registerWebrtcIceCandidateHandler(_onIceCandidate);
  }

  CallStatus status = CallStatus.idle;
  String? peerId;
  String? peerNombre;
  bool muted = false;
  String? errorMessage;
  Duration callDuration = Duration.zero;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final List<RTCIceCandidate> _pendingCandidates = [];
  Timer? _durationTimer;

  /// Pide los permisos necesarios y espera la respuesta antes de tocar
  /// cualquier API de WebRTC: si el motor nativo intenta abrir el
  /// dispositivo de audio sin permiso confirmado, aborta el proceso (crash
  /// nativo, no una excepción de Dart que se pueda capturar).
  ///
  /// En Android 12+ (API 31+), flutter_webrtc enumera dispositivos de audio
  /// Bluetooth al iniciar el stream local; sin el permiso en runtime de
  /// `bluetoothConnect` esa enumeración lanza una SecurityException nativa
  /// que cierra la app de inmediato, sin pasar por ningún try/catch de Dart.
  Future<bool> _ensureMicPermission() async {
    final results = await [
      Permission.microphone,
      Permission.bluetoothConnect,
    ].request();
    return results[Permission.microphone]?.isGranted ?? false;
  }

  Future<MediaStream> _getLocalStream() async {
    _localStream ??= await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    return _localStream!;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });
    pc.onIceCandidate = (candidate) {
      final to = peerId;
      if (to != null) {
        SocketService.instance.emitWebrtcIceCandidate(
          fromId: myId,
          toId: to,
          candidate: candidate.toMap(),
        );
      }
    };
    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _cleanup();
      }
    };
    _pc = pc;
    return pc;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  Future<void> startCall(String toId, String toNombre) async {
    if (status != CallStatus.idle) return;
    errorMessage = null;
    peerId = toId;
    peerNombre = toNombre;
    status = CallStatus.calling;
    notifyListeners();
    SocketService.instance.emitCallInvite(fromId: myId, toId: toId, fromNombre: myNombre);
  }

  Future<void> acceptCall() async {
    final to = peerId;
    if (to == null) return;
    if (!await _ensureMicPermission()) {
      errorMessage = 'Permiso de micrófono denegado.';
      SocketService.instance.emitCallReject(fromId: myId, toId: to, reason: 'no_mic_permission');
      _cleanup();
      return;
    }
    try {
      await _getLocalStream();
      status = CallStatus.inCall;
      _startDurationTimer();
      notifyListeners();
      SocketService.instance.emitCallAccept(fromId: myId, toId: to);
    } catch (e) {
      errorMessage = 'No se pudo acceder al micrófono.';
      SocketService.instance.emitCallReject(fromId: myId, toId: to, reason: 'no_mic');
      _cleanup();
    }
  }

  void rejectCall() {
    final to = peerId;
    if (to != null) SocketService.instance.emitCallReject(fromId: myId, toId: to);
    _cleanup();
  }

  void hangUp() {
    final to = peerId;
    if (to != null) {
      switch (status) {
        case CallStatus.calling:
          SocketService.instance.emitCallCancel(fromId: myId, toId: to);
          break;
        case CallStatus.inCall:
          SocketService.instance.emitCallEnd(fromId: myId, toId: to);
          break;
        case CallStatus.ringing:
          SocketService.instance.emitCallReject(fromId: myId, toId: to);
          break;
        case CallStatus.idle:
          break;
      }
    }
    _cleanup();
  }

  void toggleMute() {
    final stream = _localStream;
    if (stream == null) return;
    muted = !muted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
    notifyListeners();
  }

  void _onIncomingCall(Map<String, dynamic> data) {
    if (status != CallStatus.idle) {
      final from = data['from_id']?.toString();
      if (from != null) {
        SocketService.instance.emitCallReject(fromId: myId, toId: from, reason: 'busy');
      }
      return;
    }
    peerId = data['from_id']?.toString();
    peerNombre = data['from_nombre']?.toString();
    errorMessage = null;
    status = CallStatus.ringing;
    notifyListeners();
  }

  Future<void> _onCallAccepted(Map<String, dynamic> data) async {
    if (status != CallStatus.calling || peerId != data['from_id']?.toString()) return;
    final to = peerId;
    if (to == null) return;
    if (!await _ensureMicPermission()) {
      errorMessage = 'Permiso de micrófono denegado.';
      SocketService.instance.emitCallEnd(fromId: myId, toId: to);
      _cleanup();
      return;
    }
    try {
      final stream = await _getLocalStream();
      final pc = await _createPeerConnection();
      for (final track in stream.getAudioTracks()) {
        await pc.addTrack(track, stream);
      }
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      SocketService.instance.emitWebrtcOffer(
        fromId: myId,
        toId: to,
        sdp: {'sdp': offer.sdp, 'type': offer.type},
      );
      status = CallStatus.inCall;
      _startDurationTimer();
      notifyListeners();
    } catch (e) {
      errorMessage = 'No se pudo iniciar el audio de la llamada.';
      SocketService.instance.emitCallEnd(fromId: myId, toId: to);
      _cleanup();
    }
  }

  void _onCallRejected(Map<String, dynamic> data) {
    if (peerId != data['from_id']?.toString()) return;
    errorMessage = 'La llamada fue rechazada.';
    _cleanup();
  }

  void _onCallCancelled(Map<String, dynamic> data) {
    if (peerId != data['from_id']?.toString()) return;
    _cleanup();
  }

  void _onCallEnded(Map<String, dynamic> data) {
    if (peerId != data['from_id']?.toString()) return;
    _cleanup();
  }

  Future<void> _onOffer(Map<String, dynamic> data) async {
    if (peerId != data['from_id']?.toString()) return;
    final to = peerId;
    if (to == null) return;
    if (!await _ensureMicPermission()) {
      errorMessage = 'Permiso de micrófono denegado.';
      SocketService.instance.emitCallEnd(fromId: myId, toId: to);
      _cleanup();
      return;
    }
    try {
      final pc = await _createPeerConnection();
      final stream = await _getLocalStream();
      for (final track in stream.getAudioTracks()) {
        await pc.addTrack(track, stream);
      }
      final sdpMap = Map<String, dynamic>.from(data['sdp'] as Map);
      await pc.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
      for (final candidate in _pendingCandidates) {
        await pc.addCandidate(candidate);
      }
      _pendingCandidates.clear();
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      SocketService.instance.emitWebrtcAnswer(
        fromId: myId,
        toId: to,
        sdp: {'sdp': answer.sdp, 'type': answer.type},
      );
    } catch (e) {
      errorMessage = 'Error al procesar la llamada.';
      notifyListeners();
    }
  }

  Future<void> _onAnswer(Map<String, dynamic> data) async {
    if (peerId != data['from_id']?.toString() || _pc == null) return;
    try {
      final sdpMap = Map<String, dynamic>.from(data['sdp'] as Map);
      await _pc!.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
      for (final candidate in _pendingCandidates) {
        await _pc!.addCandidate(candidate);
      }
      _pendingCandidates.clear();
    } catch (_) {}
  }

  Future<void> _onIceCandidate(Map<String, dynamic> data) async {
    if (peerId != data['from_id']?.toString()) return;
    try {
      final c = Map<String, dynamic>.from(data['candidate'] as Map);
      final candidate = RTCIceCandidate(
        c['candidate'] as String?,
        c['sdpMid'] as String?,
        c['sdpMLineIndex'] as int?,
      );
      final pc = _pc;
      if (pc != null && await pc.getRemoteDescription() != null) {
        await pc.addCandidate(candidate);
      } else {
        _pendingCandidates.add(candidate);
      }
    } catch (_) {}
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _pc?.close();
    _pc = null;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    _pendingCandidates.clear();
    peerId = null;
    peerNombre = null;
    muted = false;
    callDuration = Duration.zero;
    status = CallStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
