import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../config/backend_config.dart';

/// Extrae el claim `id` del JWT emitido por nuestro backend.
/// La app no usa sesiones nativas de Supabase Auth (el login pasa por
/// nuestro backend), así que `SupabaseConfig.auth.currentUser` siempre
/// es null aquí; el id del usuario solo vive dentro del JWT guardado.
String? _userIdFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final data = jsonDecode(payload) as Map<String, dynamic>;
    return data['id']?.toString();
  } catch (_) {
    return null;
  }
}

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();
  final StorageService _storage = StorageService();

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _pendingAppointments = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;

  // Getters
  List<Map<String, dynamic>> get appointments => List.unmodifiable(_appointments);
  List<Map<String, dynamic>> get pendingAppointments =>
      List.unmodifiable(_pendingAppointments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;

  AppointmentProvider() {
    _initialize();
  }

  /// Inicializar provider: cargar citas del almacenamiento local
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cargar citas del almacenamiento local
      _appointments = await _storage.getAppointments();

      // Separar pendientes de sincronizadas
      _pendingAppointments = _appointments
          .where((apt) => apt['sincronizado'] != true)
          .toList();

      debugPrint(
          '✅ AppointmentProvider inicializado: ${_appointments.length} citas, ${_pendingAppointments.length} pendientes');

      await connectSocket();

      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error inicializando citas: $e';
      _isLoading = false;
      debugPrint('❌ $_errorMessage');
    }
    notifyListeners();
  }

  /// Conecta el socket si hay token guardado. Se llama al arrancar la app
  /// (sesión ya existente) y también justo después de un login/registro
  /// exitoso, porque en ese momento aún no había token cuando se construyó
  /// este provider.
  Future<void> connectSocket() async {
    try {
      final token = await _storage.getAuthToken();
      final userId = token != null ? _userIdFromToken(token) : null;
      if (token == null || userId == null) return;

      SocketService.instance.registerAppointmentHandler((data) async {
        // Al recibir evento de cambio de estado, recargar citas desde backend
        debugPrint('🔔 Socket event received (appointment): $data');
        try {
          await loadAppointments();
        } catch (e) {
          debugPrint('⚠️ Error recargando citas tras evento socket: $e');
        }
      });

      SocketService.instance.registerNewAppointmentHandler((data) async {
        debugPrint('🔔 Socket event received (new appointment): $data');
        try {
          await loadAppointments();
        } catch (e) {
          debugPrint('⚠️ Error recargando citas tras evento nuevo: $e');
        }
      });

      SocketService.instance.connect(token: token, userId: userId);
    } catch (e) {
      debugPrint('⚠️ Error iniciando SocketService: $e');
    }
  }

  /// Crear una cita
  Future<bool> createAppointment({
    required String fecha,
    required String hora,
    required String idOdontologo,
    required String nombreOdontologo,
    required double monto,
    String metodoPago = 'Yape',
    String? servicio,
    String? descripcion,
    File? paymentProof,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Crear en backend
      final result = await _appointmentService.createAppointment(
        fecha: fecha,
        hora: hora,
        idOdontologo: idOdontologo,
        monto: monto,
        metodoPago: metodoPago,
        servicio: servicio,
        descripcion: descripcion,
      );

      // Si el paciente adjuntó la captura del pago (ej. Yape), subirla al
      // pago recién creado para que cajero/recepción la vean en el panel.
      final paymentId = result['payment']?['id']?.toString();
      if (paymentProof != null && paymentId != null) {
        final uploaded = await _appointmentService.uploadPaymentProof(paymentId, paymentProof);
        if (!uploaded) {
          debugPrint('⚠️ No se pudo subir el comprobante de pago para la cita recién creada');
        }
      }

      // Guardar localmente
      final appointment = {
        'id': result['appointment']['id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
        'id_backend': result['appointment']['id'],
        'fecha': fecha,
        'hora': hora,
        'id_odontologo': idOdontologo,
        'nombre_odontologo': nombreOdontologo,
        'monto': monto,
        'metodo_pago': metodoPago,
        'servicio': servicio ?? 'Pago de cita',
        'descripcion': descripcion,
        'estado': result['appointment']['estado'] ?? 'pendiente',
        'procesada': result['appointment']['procesada'] == true ? true : false,
        'procesada_por_rol': result['appointment']['procesada_por_rol'],
        'procesada_por_id': result['appointment']['procesada_por_id'],
        'procesada_en': result['appointment']['procesada_en'],
        'sincronizado': true,
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _storage.saveAppointment(appointment);
      _appointments.add(appointment);

      debugPrint('✅ Cita creada localmente y en backend: ${appointment['id']}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Si falla el backend, guardar localmente como pendiente
      _errorMessage = e.toString();
      debugPrint('⚠️ Error creando cita en backend, guardando localmente: $_errorMessage');

      final localAppointment = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'fecha': fecha,
        'hora': hora,
        'id_odontologo': idOdontologo,
        'nombre_odontologo': nombreOdontologo,
        'monto': monto,
        'metodo_pago': metodoPago,
        'servicio': servicio ?? 'Pago de cita',
        'descripcion': descripcion,
        'estado': 'pendiente_sincronizacion',
        'procesada': false,
        'procesada_por_rol': null,
        'procesada_por_id': null,
        'procesada_en': null,
        'sincronizado': false,
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _storage.saveAppointment(localAppointment);
      _appointments.add(localAppointment);
      _pendingAppointments.add(localAppointment);

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cargar citas desde el backend
  Future<void> loadAppointments() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final appointments = await _appointmentService.getUserAppointments();
      _appointments = appointments;

      // Separar pendientes
      _pendingAppointments = _appointments
          .where((apt) => apt['sincronizado'] != true)
          .toList();

      debugPrint('✅ Citas cargadas: ${_appointments.length}');

      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Error cargando citas: $e';
      _isLoading = false;
      debugPrint('❌ $_errorMessage');
    }
    notifyListeners();
  }

  /// Obtener cita específica
  Future<Map<String, dynamic>?> getAppointmentDetail(String appointmentId) async {
    try {
      return await _appointmentService.getAppointmentDetail(appointmentId);
    } catch (e) {
      _errorMessage = 'Error obteniendo cita: $e';
      notifyListeners();
      return null;
    }
  }

  /// Cancelar cita
  Future<bool> cancelAppointment(
      String appointmentId, String reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success =
          await _appointmentService.cancelAppointment(appointmentId, reason);

      if (success) {
        // Actualizar localmente. Se compara con .toString() porque el backend
        // devuelve id como número (5) pero appointmentId es String ("5").
        final index = _appointments.indexWhere((apt) =>
            apt['id']?.toString() == appointmentId ||
            apt['id_backend']?.toString() == appointmentId);
        if (index != -1) {
          _appointments[index]['estado'] = 'cancelada';
          _appointments[index]['razon_cancelacion'] = reason;
          await _storage.updateAppointment(appointmentId, {
            'estado': 'cancelada',
            'razon_cancelacion': reason,
          });
        }

        debugPrint('✅ Cita cancelada');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error cancelando cita: $e';
      _isLoading = false;
      debugPrint('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// Reagendar una cita: cambia fecha/hora y, opcionalmente, método de pago.
  /// Si se adjunta [paymentProof] (ej. nueva captura de Yape), se sube al pago.
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required String fecha,
    required String hora,
    String? metodoPago,
    File? paymentProof,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _appointmentService.rescheduleAppointment(
        appointmentId: appointmentId,
        fecha: fecha,
        hora: hora,
        metodoPago: metodoPago,
      );

      final paymentId = result['payment']?['id']?.toString();
      if (paymentProof != null && paymentId != null) {
        final uploaded = await _appointmentService.uploadPaymentProof(paymentId, paymentProof);
        if (!uploaded) {
          debugPrint('⚠️ No se pudo subir el comprobante del pago reagendado');
        }
      }

      final index = _appointments.indexWhere((apt) =>
          apt['id']?.toString() == appointmentId ||
          apt['id_backend']?.toString() == appointmentId);
      if (index != -1) {
        _appointments[index]['fecha'] = fecha;
        _appointments[index]['hora'] = hora;
        if (metodoPago != null) _appointments[index]['metodo_pago'] = metodoPago;
        _appointments[index]['estado'] =
            result['appointment']?['estado'] ?? _appointments[index]['estado'];
        await _storage.updateAppointment(_appointments[index]['id']?.toString() ?? appointmentId, {
          'fecha': fecha,
          'hora': hora,
          if (metodoPago != null) 'metodo_pago': metodoPago,
        });
      }

      debugPrint('✅ Cita reagendada: $appointmentId');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error reagendando cita: $e';
      debugPrint('❌ $_errorMessage');

      // Guardar el cambio localmente como pendiente de sincronización
      final index = _appointments.indexWhere((apt) =>
          apt['id']?.toString() == appointmentId ||
          apt['id_backend']?.toString() == appointmentId);
      if (index != -1) {
        _appointments[index]['fecha'] = fecha;
        _appointments[index]['hora'] = hora;
        if (metodoPago != null) _appointments[index]['metodo_pago'] = metodoPago;
        _appointments[index]['sincronizado'] = false;
        await _storage.updateAppointment(_appointments[index]['id']?.toString() ?? appointmentId, {
          'fecha': fecha,
          'hora': hora,
          if (metodoPago != null) 'metodo_pago': metodoPago,
          'sincronizado': false,
        });
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sincronizar citas pendientes
  Future<void> syncPendingAppointments() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 Iniciando sincronización de citas pendientes...');
      notifyListeners();

      final synced =
          await _appointmentService.syncPendingAppointments();

      if (synced > 0) {
        // Recargar citas
        await loadAppointments();
        debugPrint('✅ $synced citas sincronizadas');
      }

      _isSyncing = false;
    } catch (e) {
      _errorMessage = 'Error sincronizando: $e';
      _isSyncing = false;
      debugPrint('❌ $_errorMessage');
    }
    notifyListeners();
  }

  /// Obtener citas de un rango de fechas
  List<Map<String, dynamic>> getAppointmentsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _appointments.where((apt) {
      final aptDate = DateTime.tryParse(apt['fecha'] ?? '');
      return aptDate != null &&
          aptDate.isAfter(startDate) &&
          aptDate.isBefore(endDate);
    }).toList();
  }

  /// Obtener citas de un odontólogo específico
  List<Map<String, dynamic>> getAppointmentsByDoctor(String doctorId) {
    return _appointments
        .where((apt) => apt['id_odontologo'] == doctorId)
        .toList();
  }

  /// Obtener próximas citas (siguientes 30 días)
  List<Map<String, dynamic>> getUpcomingAppointments() {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return getAppointmentsByDateRange(now, thirtyDaysFromNow);
  }

  /// Obtener citas pasadas
  List<Map<String, dynamic>> getPastAppointments() {
    final now = DateTime.now();
    return _appointments.where((apt) {
      final aptDate = DateTime.tryParse(apt['fecha'] ?? '');
      return aptDate != null && aptDate.isBefore(now);
    }).toList();
  }

  /// Borrar cita (solo del almacenamiento local)
  Future<bool> deleteAppointmentLocal(String appointmentId) async {
    try {
      final success = await _storage.deleteAppointment(appointmentId);
      if (success) {
        _appointments.removeWhere((apt) => apt['id'] == appointmentId);
        _pendingAppointments
            .removeWhere((apt) => apt['id'] == appointmentId);
        debugPrint('✅ Cita eliminada localmente');
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error eliminando cita: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Marcar una cita como procesada por rol administrativo (cajero/recepcionista)
  Future<bool> markAppointmentProcessed(String appointmentId, String role, {String? userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _appointmentService.processAppointment(appointmentId, role: role, userId: userId);

      if (success) {
        final idx = _appointments.indexWhere((apt) =>
            apt['id']?.toString() == appointmentId ||
            apt['id_backend']?.toString() == appointmentId);
        if (idx != -1) {
          _appointments[idx]['procesada'] = true;
          _appointments[idx]['procesada_por_rol'] = role;
          _appointments[idx]['procesada_por_id'] = userId;
          _appointments[idx]['procesada_en'] = DateTime.now().toIso8601String();
          await _storage.updateAppointment(_appointments[idx]['id'] ?? appointmentId, {
            'procesada': true,
            'procesada_por_rol': role,
            'procesada_por_id': userId,
            'procesada_en': DateTime.now().toIso8601String(),
          });
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error marcando cita procesada: $e';
      debugPrint('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
  }
}
