import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/backend_config.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '576083952932-456v5ddm4j5mq19ibl13fd99junour1i.apps.googleusercontent.com',
  );

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      throw Exception('Error al iniciar sesión: ${response.statusCode} ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      throw Exception('Error al registrar: ${response.statusCode} ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse(BackendConfig.profileUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Respuesta de perfil inválida');
      }
      throw Exception('Error al obtener perfil: ${response.statusCode} ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse(BackendConfig.profileUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          return profileData;
        }

        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Respuesta de actualización de perfil inválida');
      }

      if (response.statusCode == 204) {
        return profileData;
      }

      throw Exception('Error al actualizar perfil: ${response.statusCode} ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> loginWithGoogle() async {
    try {
      // Inicia sesión con Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelado');
      }

      // Obtiene el token de Google
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      // Autentica con Supabase usando el token de Google
      final response = await SupabaseConfig.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken ?? '',
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseConfig.auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      rethrow;
    }
  }

  bool isLoggedIn() {
    return SupabaseConfig.auth.currentSession != null;
  }

  String? getCurrentUserEmail() {
    return SupabaseConfig.auth.currentUser?.email;
  }

  String? getCurrentUserId() {
    return SupabaseConfig.auth.currentUser?.id;
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}

