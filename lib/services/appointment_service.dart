import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../config/backend_config.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  late String _baseUrl;
  final _storage = StorageService();

  factory AppointmentService({String? baseUrl}) {
    _instance._baseUrl = baseUrl ?? BackendConfig.apiBaseUrl;
    return _instance;
  }

  AppointmentService._internal();

  List<Map<String, dynamic>> _parseAppointmentsResponse(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['appointments'] is List) {
        return List<Map<String, dynamic>>.from(data['appointments']);
      }
      if (data['citas'] is List) {
        return List<Map<String, dynamic>>.from(data['citas']);
      }
      if (data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
          return List<Map<String, dynamic>>.from(value);
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _extractCreateAppointmentResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Direct fields
      if (data.containsKey('appointment')) {
        final appointment = data['appointment'] is Map ? Map<String, dynamic>.from(data['appointment']) : null;
        final payment = data['payment'] is Map ? Map<String, dynamic>.from(data['payment']) : null;
        return {'appointment': appointment, 'payment': payment};
      }

      // Common alternative names
      if (data.containsKey('data') && data['data'] is Map && data['data'].containsKey('appointment')) {
        final inner = data['data'];
        return {'appointment': Map<String, dynamic>.from(inner['appointment']), 'payment': inner['payment'] is Map ? Map<String, dynamic>.from(inner['payment']) : null};
      }

      // If the response itself looks like an appointment
      final possibleKeys = ['id', 'fecha', 'hora'];
      if (possibleKeys.every((k) => data.containsKey(k))) {
        return {'appointment': Map<String, dynamic>.from(data)};
      }
    }

    return {'appointment': null, 'payment': null};
  }

  // ============================================
  // API CALLS AL BACKEND
  // ============================================

  /// Crear una cita en el backend
  Future<Map<String, dynamic>> createAppointment({
    required String fecha,
    required String hora,
    required String idOdontologo,
    required double monto,
    String metodoPago = 'Yape',
    String? servicio,
    String? descripcion,
  }) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      final payload = {
        'fecha': fecha,
        'hora': hora,
        'id_odontologo': idOdontologo,
        'monto': monto,
        'metodo_pago': metodoPago,
        'payment_method': metodoPago,
        'servicio': servicio ?? 'Pago de cita',
        'descripcion': descripcion,
      };
      debugPrint('📤 Enviando createAppointment -> ${BackendConfig.mobileAppointmentsUrl}');
      debugPrint('📦 Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(BackendConfig.mobileAppointmentsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final extracted = _extractCreateAppointmentResponse(data);
        debugPrint('✅ Cita creada en backend: ${extracted['appointment']?['id']}');
        return extracted;
      }

      // Manejo de conflictos explícito
      if (response.statusCode == 409) {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ?? 'Horario no disponible';
          final note = data['suggestion']?['nota'] ?? '';
          final combined = note.isNotEmpty ? '$msg - $note' : msg;
          debugPrint('⚠️ Backend 409: $combined');
          throw Exception(combined);
        } catch (e) {
          debugPrint('⚠️ Backend 409 (no JSON): ${response.body}');
          throw Exception('Horario no disponible');
        }
      }

      // Otros errores: intentar parsear cuerpo, si no, mostrar body crudo
      try {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? errorData.toString();
        debugPrint('❌ Backend error ${response.statusCode}: $message');
        throw Exception(message);
      } catch (e) {
        debugPrint('❌ Backend error ${response.statusCode} (no JSON): ${response.body}');
        throw Exception('Error al crear cita: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creando cita: $e');
      rethrow;
    }
  }

  /// Obtener citas del usuario
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        // Si no hay token, retorna citas locales
        return await _storage.getAppointments();
      }

      final response = await http.get(
        Uri.parse(BackendConfig.mobileAppointmentsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appointments = _parseAppointmentsResponse(data);

        if (appointments.isNotEmpty) {
          await _storage.saveAppointments(appointments);
        }

        debugPrint('✅ ${appointments.length} citas sincronizadas');
        return appointments;
      } else {
        return await _storage.getAppointments();
      }
    } catch (e) {
      debugPrint('⚠️ Error sincronizando citas, usando almacenamiento local: $e');
      // Retorna citas locales si hay error
      return await _storage.getAppointments();
    }
  }

  /// Obtener detalles de una cita
  Future<Map<String, dynamic>?> getAppointmentDetail(String appointmentId) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        return await _storage.getAppointment(appointmentId);
      }

      final response = await http.get(
        Uri.parse(BackendConfig.mobileAppointmentDetailUrl(appointmentId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['appointment'];
      } else {
        // Si falla, intenta obtener de almacenamiento local
        return await _storage.getAppointment(appointmentId);
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo detalle de cita: $e');
      return await _storage.getAppointment(appointmentId);
    }
  }

  /// Obtener pago de una cita
  Future<Map<String, dynamic>?> getAppointmentPayment(String appointmentId) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse(BackendConfig.mobileAppointmentPaymentUrl(appointmentId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payment'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo pago: $e');
      return null;
    }
  }

  String _mimeTypeForPath(String filePath) {
    switch (filePath.toLowerCase().split('.').last) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Subir la captura del comprobante de pago (ej. Yape) para un pago ya creado
  Future<bool> uploadPaymentProof(String paymentId, File proofImage) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        debugPrint('⚠️ No se pudo subir comprobante: sin token de autenticación');
        return false;
      }

      final uri = Uri.parse(BackendConfig.mobilePaymentProofUrl(paymentId));
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = _mimeTypeForPath(proofImage.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'comprobante',
          proofImage.path,
          contentType: MediaType(mimeType.split('/').first, mimeType.split('/').last),
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Comprobante de pago subido para pago $paymentId');
        return true;
      }

      final body = await response.stream.bytesToString();
      debugPrint('❌ Error subiendo comprobante (${response.statusCode}): $body');
      return false;
    } catch (e) {
      debugPrint('❌ Error subiendo comprobante: $e');
      return false;
    }
  }

  /// Reagendar una cita existente (cambiar fecha/hora y, opcionalmente, método de pago)
  Future<Map<String, dynamic>> rescheduleAppointment({
    required String appointmentId,
    required String fecha,
    required String hora,
    String? metodoPago,
  }) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        throw Exception('Token de autenticación no disponible');
      }

      final payload = {
        'fecha': fecha,
        'hora': hora,
        if (metodoPago != null) 'metodo_pago': metodoPago,
        if (metodoPago != null) 'payment_method': metodoPago,
      };

      final response = await http.patch(
        Uri.parse(BackendConfig.mobileAppointmentRescheduleUrl(appointmentId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _extractCreateAppointmentResponse(data);
      }

      if (response.statusCode == 409) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Horario no disponible');
        } catch (_) {
          throw Exception('Horario no disponible');
        }
      }

      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'No se pudo reagendar la cita');
      } catch (_) {
        throw Exception('Error al reagendar: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error reagendando cita: $e');
      rethrow;
    }
  }

  /// Cancelar una cita
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      final token = await _storage.getAuthToken();
      if (token == null) {
        // Marcar como cancelada localmente
        await _storage.updateAppointment(
          appointmentId,
          {
            'estado': 'cancelada',
            'razon_cancelacion': reason,
            'actualizado_en': DateTime.now().toIso8601String(),
          },
        );
        return true;
      }

      final response = await http.patch(
        Uri.parse(BackendConfig.mobileAppointmentCancelUrl(appointmentId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        // Actualizar localmente
        await _storage.updateAppointment(
          appointmentId,
          {
            'estado': 'cancelada',
            'razon_cancelacion': reason,
          },
        );
        debugPrint('✅ Cita cancelada');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error cancelando cita: $e');
      return false;
    }
  }

  /// Marcar una cita como procesada por cajero/recepción
  Future<bool> processAppointment(String appointmentId, {required String role, String? userId}) async {
    try {
      final token = await _storage.getAuthToken();
      final payload = {
        'procesada': true,
        'procesada_por_rol': role,
        'procesada_por_id': userId,
        'procesada_en': DateTime.now().toIso8601String(),
      };

      if (token == null) {
        // No auth: actualizar localmente
        await _storage.updateAppointment(appointmentId, payload);
        return true;
      }

      // Intentar endpoint /process primero, luego /confirm como fallback
      final urlsToTry = [
        BackendConfig.mobileAppointmentProcessUrl(appointmentId),
        BackendConfig.mobileAppointmentConfirmUrl(appointmentId),
      ];

      for (final url in urlsToTry) {
        try {
          final response = await http.patch(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _storage.updateAppointment(appointmentId, payload);
            return true;
          }

          // Si 404 o 405, probar siguiente URL
          if (response.statusCode == 404 || response.statusCode == 405) continue;

          // Otros códigos: intentar siguiente URL antes de fallar
        } catch (e) {
          // Ignorar y probar siguiente URL
          continue;
        }
      }

      // Si ninguna URL funcionó, actualizar localmente y devolver false
      await _storage.updateAppointment(appointmentId, payload);
      return false;
    } catch (e) {
      debugPrint('❌ Error marcando cita procesada: $e');
      try {
        await _storage.updateAppointment(appointmentId, {
          'procesada': true,
          'procesada_por_rol': role,
          'procesada_por_id': userId,
          'procesada_en': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return false;
    }
  }

  // ============================================
  // ALMACENAMIENTO LOCAL
  // ============================================

  /// Guardar cita localmente (sin enviar al backend)
  Future<bool> savePendingAppointment(Map<String, dynamic> appointment) async {
    return await _storage.saveAppointment(appointment);
  }

  /// Obtener citas pendientes (creadas localmente, no sincronizadas)
  Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    final allAppointments = await _storage.getAppointments();
    return allAppointments
        .where((apt) => apt['sincronizado'] != true)
        .toList();
  }

  /// Sincronizar citas pendientes cuando haya conexión
  Future<int> syncPendingAppointments() async {
    final pending = await getPendingAppointments();
    int synced = 0;

    for (var apt in pending) {
      try {
        final result = await createAppointment(
          fecha: apt['fecha'],
          hora: apt['hora'],
          idOdontologo: apt['id_odontologo'],
          monto: apt['monto'] ?? 0.0,
          metodoPago: apt['metodo_pago'] ?? 'Yape',
          servicio: apt['servicio'],
          descripcion: apt['descripcion'],
        );

        // Marcar como sincronizada
        await _storage.updateAppointment(
          apt['id'] ?? '',
          {
            'sincronizado': true,
            'id_backend': result['appointment']?['id'],
            'sincronizado_en': DateTime.now().toIso8601String(),
          },
        );

        synced++;
        debugPrint('✅ Cita sincronizada: ${apt['id']}');
      } catch (e) {
        debugPrint('⚠️ Error sincronizando cita: $e');
      }
    }

    debugPrint('✅ $synced citas sincronizadas de ${pending.length}');
    return synced;
  }
}
