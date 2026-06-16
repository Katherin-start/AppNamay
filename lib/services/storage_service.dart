import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;
  bool _initialized = false;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // ============================================
  // CITAS - Almacenamiento local
  // ============================================

  /// Guardar una cita localmente
  Future<bool> saveAppointment(Map<String, dynamic> appointment) async {
    try {
      await init();
      final key = 'appointment_${appointment['id'] ?? DateTime.now().millisecondsSinceEpoch}';
      await _prefs.setString(key, jsonEncode(appointment));
      return true;
    } catch (e) {
      print('❌ Error guardando cita localmente: $e');
      return false;
    }
  }

  /// Guardar múltiples citas
  Future<bool> saveAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      await init();
      for (var apt in appointments) {
        await saveAppointment(apt);
      }
      return true;
    } catch (e) {
      print('❌ Error guardando citas: $e');
      return false;
    }
  }

  /// Obtener todas las citas guardadas localmente
  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      await init();
      final appointments = <Map<String, dynamic>>[];
      final keys = _prefs.getKeys();

      for (var key in keys) {
        if (key.startsWith('appointment_')) {
          final data = _prefs.getString(key);
          if (data != null) {
            appointments.add(jsonDecode(data));
          }
        }
      }

      // Ordenar por fecha descendente
      appointments.sort((a, b) {
        final dateA = DateTime.tryParse(a['creado_en'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['creado_en'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return appointments;
    } catch (e) {
      print('❌ Error obteniendo citas locales: $e');
      return [];
    }
  }

  /// Obtener una cita específica
  Future<Map<String, dynamic>?> getAppointment(String appointmentId) async {
    try {
      await init();
      final key = 'appointment_$appointmentId';
      final data = _prefs.getString(key);
      return data != null ? jsonDecode(data) : null;
    } catch (e) {
      print('❌ Error obteniendo cita: $e');
      return null;
    }
  }

  /// Actualizar una cita
  Future<bool> updateAppointment(
      String appointmentId, Map<String, dynamic> updates) async {
    try {
      await init();
      final key = 'appointment_$appointmentId';
      final current = await getAppointment(appointmentId);
      if (current != null) {
        final updated = {...current, ...updates};
        await _prefs.setString(key, jsonEncode(updated));
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error actualizando cita: $e');
      return false;
    }
  }

  /// Eliminar una cita
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await init();
      final key = 'appointment_$appointmentId';
      return await _prefs.remove(key);
    } catch (e) {
      print('❌ Error eliminando cita: $e');
      return false;
    }
  }

  /// Eliminar todas las citas
  Future<bool> clearAppointments() async {
    try {
      await init();
      final keys = _prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('appointment_')) {
          await _prefs.remove(key);
        }
      }
      return true;
    } catch (e) {
      print('❌ Error limpiando citas: $e');
      return false;
    }
  }

  // ============================================
  // AUTH TOKEN - Para sincronización
  // ============================================

  /// Guardar token de autenticación
  Future<bool> saveAuthToken(String token) async {
    try {
      await init();
      return await _prefs.setString('auth_token', token);
    } catch (e) {
      print('❌ Error guardando token: $e');
      return false;
    }
  }

  /// Obtener token
  Future<String?> getAuthToken() async {
    try {
      await init();
      return _prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  /// Limpiar todo
  Future<bool> clearAll() async {
    try {
      await init();
      return await _prefs.clear();
    } catch (e) {
      print('❌ Error limpiando almacenamiento: $e');
      return false;
    }
  }
}
