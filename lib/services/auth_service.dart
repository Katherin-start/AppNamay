import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<AuthResponse> loginWithEmail(String email, String password) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> registerWithEmail(String email, String password) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );
      return response;
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

