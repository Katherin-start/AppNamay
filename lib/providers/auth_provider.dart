import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  String? _userEmail;
  Map<String, dynamic>? _profile;
  bool _initialized = false;
  bool _isNewUser = false;
  final List<Map<String, dynamic>> _pendingAppointments = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get profile => _profile;
  bool get initialized => _initialized;
  bool get isNewUser => _isNewUser;
  List<Map<String, dynamic>> get pendingAppointments => List.unmodifiable(_pendingAppointments);
  
  /// Obtener el token de autenticación actual
  String? getAuthToken() => _authService.getAuthToken();

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await _authService.init();
    _isLoggedIn = _authService.isLoggedIn();
    _userEmail = _authService.getCurrentUserEmail();
    if (_isLoggedIn) {
      await fetchProfile();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.loginWithEmail(email, password);
      _isLoggedIn = success;
      _isNewUser = false;
      if (success) {
        _userEmail = email;
        // No bloquea la navegación: el perfil se carga en segundo plano
        // y notifica a los listeners cuando llegue.
        unawaited(fetchProfile());
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(
    String nombre,
    String apellido,
    String email,
    String password,
    String fotoPerfil,
    {String rol = 'Paciente'} // Rol por defecto: Paciente
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.registerWithEmail(
        nombre,
        apellido,
        email,
        password,
        fotoPerfil,
        rol: rol,
      );
      if (!success) {
        throw Exception('No se pudo registrar el usuario.');
      }
      _isLoggedIn = success;
      _isNewUser = true;
      _userEmail = email;
      await fetchProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoggedIn = false;
      _userEmail = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordDirect({
    required String email,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPasswordDirect(
        email: email,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileData = await _authService.getProfile();
      _profile = profileData;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOdontologos() async {
    return await _authService.fetchOdontologos();
  }

  Future<Map<String, dynamic>> fetchDoctorDetail(String doctorId) async {
    return await _authService.fetchDoctorDetail(doctorId);
  }

  Future<Map<String, dynamic>> submitDoctorReview(
    String doctorId,
    int rating,
    String comentario,
  ) async {
    return await _authService.createDoctorReview(doctorId, rating, comentario);
  }

  Future<List<Map<String, dynamic>>> fetchDiscounts() async {
    return await _authService.fetchDiscounts();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableSlots(String doctorId, String fecha) async {
    return await _authService.fetchAvailableSlots(doctorId, fecha);
  }

  Future<List<Map<String, dynamic>>> fetchServices() async {
    return await _authService.fetchServices();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _authService.updateProfile(profileData);
      _profile = updatedProfile;
      // ignore: avoid_print
      print('AuthProvider: profile updated => $_profile');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void addPendingAppointment(Map<String, dynamic> appointment) {
    _pendingAppointments.add(appointment);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
