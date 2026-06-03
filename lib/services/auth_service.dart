import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backend_config.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();


  static const String _authTokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';

  String? _authToken;
  String? _userEmail;

  String? get authToken => _authToken;
  String? get userEmail => _userEmail;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_authTokenKey);
    _userEmail = prefs.getString(_userEmailKey);
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString(_authTokenKey, _authToken!);
    }
    if (_userEmail != null) {
      await prefs.setString(_userEmailKey, _userEmail!);
    }
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userEmailKey);
    _authToken = null;
    _userEmail = null;
  }

  String _parseBackendError(String body, int statusCode) {
    if (body.isEmpty) {
      return 'Error $statusCode: respuesta vacía del servidor';
    }

    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        if (parsed['error'] != null) {
          return parsed['error'].toString();
        }
        if (parsed['message'] != null) {
          return parsed['message'].toString();
        }
        return parsed.toString();
      }
      return parsed.toString();
    } catch (_) {
      return 'Error $statusCode: $body';
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    try {
      // ignore: avoid_print
      print('loginWithEmail: intentando login para $email');
      final response = await http.post(
        Uri.parse(BackendConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // ignore: avoid_print
      print('loginWithEmail: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception(
            'La respuesta de login no contiene token de autenticación',
          );
        }

        final parsed = jsonDecode(body);
        if (parsed is String) {
          _authToken = parsed;
          _userEmail = email;
          await _saveAuthData();
          return true;
        }

        if (parsed is Map<String, dynamic>) {
          _authToken =
              parsed['token'] ?? parsed['accessToken'] ?? parsed['jwt'] ?? parsed['access_token'];
          if (_authToken == null) {
            throw Exception(
              'No se encontró token de autenticación en la respuesta del login.',
            );
          }

          _userEmail = email;
          await _saveAuthData();

          if (parsed.containsKey('user') && parsed['user'] is Map<String, dynamic>) {
            return true;
          }

          return true;
        }

        throw Exception('Respuesta de login inválida');
      }

      // Si es 401, las credenciales son inválidas
      if (response.statusCode == 401) {
        throw Exception('Email o contraseña incorrectos');
      }

      // Para otros errores, devolver el mensaje del servidor
      final errorMsg = _parseBackendError(response.body, response.statusCode);
      // ignore: avoid_print
      print('loginWithEmail error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      // ignore: avoid_print
      print('loginWithEmail exception: $e');
      rethrow;
    }
  }

  static const Map<String, int> _roleNameToId = {
    'Paciente': 6,
    'Doctor': 2,
    'Odontólogo': 2,
    'Administrador': 1,
    'Admin': 1,
  };

  Future<bool> registerWithEmail(
    String nombre,
    String apellido,
    String email,
    String password,
    String? fotoPerfil,
    {String rol = 'Paciente'} // Rol por defecto: Paciente
  ) async {
    try {
      final rolId = _roleNameToId[rol] ?? int.tryParse(rol) ?? 1;
      // ignore: avoid_print
      print('registerWithEmail: iniciando registro para $email con rol=$rol rol_id=$rolId fotoPerfil=${fotoPerfil ?? 'null'}');
      final payload = {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'rol_id': rolId, // Enviar rol_id al backend
      };

      if (fotoPerfil != null && fotoPerfil.isNotEmpty) {
        payload['foto_perfil'] = fotoPerfil;
      }

      final response = await http.post(
        Uri.parse(BackendConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // ignore: avoid_print
      print('registerWithEmail: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body.isNotEmpty) {
          final parsed = jsonDecode(body);
          if (parsed is String) {
            _authToken = parsed;
            _userEmail = email;
            await _saveAuthData();
            return true;
          }
          if (parsed is Map<String, dynamic>) {
            // Intentar extraer token de varios campos posibles
            _authToken =
                parsed['token'] ?? parsed['accessToken'] ?? parsed['jwt'] ?? parsed['access_token'];
            
            // Si aún no hay token, revisar si está en 'user' o 'data'
            if (_authToken == null && parsed.containsKey('user') && parsed['user'] is Map) {
              _authToken = parsed['user']['token'] ?? parsed['user']['accessToken'];
            }
            if (_authToken == null && parsed.containsKey('data') && parsed['data'] is Map) {
              _authToken = parsed['data']['token'] ?? parsed['data']['accessToken'];
            }
            
            if (_authToken != null) {
              _userEmail = email;
              await _saveAuthData();
              return true;
            }
            
            // Si se registró pero no hay token, hacer login automático
            // ignore: avoid_print
            print('registerWithEmail: no token en respuesta, intentando login');
            return await loginWithEmail(email, password);
          }
        }
        
        // Respuesta vacía: intentar login
        // ignore: avoid_print
        print('registerWithEmail: respuesta vacía, intentando login');
        return await loginWithEmail(email, password);
      }

      final errorMsg = _parseBackendError(response.body, response.statusCode);
      // ignore: avoid_print
      print('registerWithEmail error: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      // ignore: avoid_print
      print('registerWithEmail exception: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseOdontologosResponse(dynamic data) {
    List<Map<String, dynamic>> parseList(dynamic value) {
      if (value is List) {
        return value
            .where((item) => item is Map)
            .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    if (data is List) {
      return parseList(data);
    }

    if (data is Map<String, dynamic>) {
      if (data['odontologos'] is List) {
        return parseList(data['odontologos']);
      }
      if (data['data'] is List) {
        return parseList(data['data']);
      }
      if (data['usuarios'] is List) {
        return parseList(data['usuarios']);
      }

      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
          return parseList(value);
        }
      }
    }

    throw Exception('Respuesta inválida al obtener odontólogos.');
  }

  List<Map<String, dynamic>> _parseDiscountsResponse(dynamic data) {
    List<Map<String, dynamic>> parseList(dynamic value) {
      if (value is List) {
        return value
            .where((item) => item is Map)
            .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    if (data is List) {
      return parseList(data);
    }

    if (data is Map<String, dynamic>) {
      if (data['discounts'] is List) {
        return parseList(data['discounts']);
      }
      if (data['descuentos'] is List) {
        return parseList(data['descuentos']);
      }
      if (data['data'] is List) {
        return parseList(data['data']);
      }

      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
          return parseList(value);
        }
      }
    }

    throw Exception('Respuesta inválida al obtener descuentos.');
  }

  Future<List<Map<String, dynamic>>> fetchDiscounts() async {
    final uri = Uri.parse(BackendConfig.mobileDiscountsUrl);
    final headersWithAuth = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    try {
      final response = await http.get(uri, headers: headersWithAuth);
      // ignore: avoid_print
      print('fetchDiscounts: ${uri.toString()} status=${response.statusCode} content-type=${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDiscountsResponse(data);
      }

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        final stripped = _stripHtml(response.body);
        throw Exception('Error ${response.statusCode}: ${stripped.isNotEmpty ? stripped : 'Respuesta HTML no esperada del servidor.'}');
      }

      final original = uri.toString();
      final variants = <String>{
        original,
        original.replaceFirst('/api/mobile/', '/mobile/'),
        original.replaceFirst('/api/mobile/', '/api/'),
        original.replaceFirst('/api/mobile/', '/'),
        original.replaceFirst('/api/', '/'),
        original.replaceFirst('/api/', ''),
      };

      for (final url in variants) {
        if (url == original) continue;
        try {
          final fallbackUri = Uri.parse(url);
          final fallbackResponse = await http.get(fallbackUri, headers: headersWithAuth);
          // ignore: avoid_print
          print('fetchDiscounts fallback: ${fallbackUri.toString()} status=${fallbackResponse.statusCode} content-type=${fallbackResponse.headers['content-type']}');
          if (fallbackResponse.statusCode == 200) {
            final data = jsonDecode(fallbackResponse.body);
            return _parseDiscountsResponse(data);
          }

          final ft = fallbackResponse.headers['content-type'] ?? '';
          if (ft.contains('text/html')) {
            // ignore: avoid_print
            print('fetchDiscounts fallback returned HTML for $url');
            continue;
          }

          final fallbackResponseNoAuth = await http.get(fallbackUri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
          // ignore: avoid_print
          print('fetchDiscounts fallback no-auth: ${fallbackUri.toString()} status=${fallbackResponseNoAuth.statusCode}');
          if (fallbackResponseNoAuth.statusCode == 200) {
            final data = jsonDecode(fallbackResponseNoAuth.body);
            return _parseDiscountsResponse(data);
          }
        } catch (e) {
          // ignore: avoid_print
          print('fetchDiscounts fallback failed for $url -> $e');
        }
      }

      throw Exception(_parseBackendError(response.body, response.statusCode));
    } catch (e) {
      // ignore: avoid_print
      print('fetchDiscounts error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOdontologos() async {
    final uri = Uri.parse(BackendConfig.odontologosUrl);
    final headersWithAuth = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    try {
      final response = await http.get(uri, headers: headersWithAuth);
      // ignore: avoid_print
      print('fetchOdontologos: ${uri.toString()} status=${response.statusCode} content-type=${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOdontologosResponse(data);
      }

      // Si el servidor devuelve HTML (página 404 estándar), proveer mensaje más claro
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        final stripped = _stripHtml(response.body);
        throw Exception('Error ${response.statusCode}: ${stripped.isNotEmpty ? stripped : 'Respuesta HTML no esperada del servidor.'}');
      }

      // Construir varios intentos de fallback cambiando /api y /mobile en la URL
      final original = uri.toString();
      final variants = <String>{
        original,
        original.replaceFirst('/api/mobile/', '/mobile/'),
        original.replaceFirst('/api/mobile/', '/api/'),
        original.replaceFirst('/api/mobile/', '/'),
        original.replaceFirst('/api/', '/'),
        original.replaceFirst('/api/', ''),
      };

      for (final url in variants) {
        if (url == original) continue;
        try {
          final fallbackUri = Uri.parse(url);
          // primero probar con Auth si la tuvimos
          final fallbackResponse = await http.get(fallbackUri, headers: headersWithAuth);
          // ignore: avoid_print
          print('fetchOdontologos fallback: ${fallbackUri.toString()} status=${fallbackResponse.statusCode} content-type=${fallbackResponse.headers['content-type']}');
          if (fallbackResponse.statusCode == 200) {
            final data = jsonDecode(fallbackResponse.body);
            return _parseOdontologosResponse(data);
          }

          // si devolvió HTML, intentar limpiar y continuar
          final ft = fallbackResponse.headers['content-type'] ?? '';
          if (ft.contains('text/html')) {
            // ignore: avoid_print
            print('fetchOdontologos fallback returned HTML for $url');
            continue;
          }

          // intentar sin Authorization (algunos endpoints móviles no requieren)
          final fallbackResponseNoAuth = await http.get(fallbackUri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
          // ignore: avoid_print
          print('fetchOdontologos fallback no-auth: ${fallbackUri.toString()} status=${fallbackResponseNoAuth.statusCode}');
          if (fallbackResponseNoAuth.statusCode == 200) {
            final data = jsonDecode(fallbackResponseNoAuth.body);
            return _parseOdontologosResponse(data);
          }
        } catch (e) {
          // ignore: avoid_print
          print('fetchOdontologos fallback failed for $url -> $e');
        }
      }

      throw Exception(_parseBackendError(response.body, response.statusCode));
    } catch (e) {
      // ignore: avoid_print
      print('fetchOdontologos error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchDoctorDetail(String doctorId) async {
    try {
      final uri = Uri.parse(BackendConfig.doctorDetailUrl(doctorId));
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

      final response = await http.get(uri, headers: headers);
      // ignore: avoid_print
      print('fetchDoctorDetail: ${uri.toString()} status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['doctor'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(data['doctor'] as Map<String, dynamic>);
          }
          if (data['data'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
          }
          return Map<String, dynamic>.from(data);
        }
        throw Exception('Respuesta de detalle de doctor inválida');
      }

      throw Exception(_parseBackendError(response.body, response.statusCode));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDoctorReview(
    String doctorId,
    int rating,
    String comentario,
  ) async {
    try {
      if (_authToken == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      final response = await http.post(
        Uri.parse(BackendConfig.doctorReviewUrl(doctorId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'rating': rating,
          'comentario': comentario,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          return {'rating': rating, 'comentario': comentario};
        }

        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data.containsKey('review') && data['review'] is Map<String, dynamic>) {
            return data['review'] as Map<String, dynamic>;
          }
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            return data['data'] as Map<String, dynamic>;
          }
          return data;
        }

        throw Exception('Respuesta de reseña inválida');
      }

      throw Exception('Error al enviar reseña: ${response.statusCode} ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  String _stripHtml(String html) {
    try {
      final reg = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
      return html.replaceAll(reg, '').replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (_) {
      return html;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Si tenemos token, llamar al endpoint del backend
      if (_authToken != null) {
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        };

        final response = await http.get(
          Uri.parse(BackendConfig.profileUrl),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            // El backend devuelve { "code": "...", "profile": {...} }
            // Extraer el perfil del objeto
            if (data.containsKey('profile') && data['profile'] is Map) {
              return data['profile'] as Map<String, dynamic>;
            }
            return data;
          }
          throw Exception('Respuesta de perfil inválida');
        }
        throw Exception(
          'Error al obtener perfil: ${response.statusCode} ${response.body}',
        );
      }

      // Si no hay token pero hay sesión de Supabase, usarla como fallback
      final supabaseUser = SupabaseConfig.auth.currentUser;
      if (supabaseUser != null) {
        final id = supabaseUser.id;
        final email = supabaseUser.email;
        // Intentar obtener nombre desde metadata si existe
        String? nombre;
        try {
          final meta = supabaseUser.userMetadata ?? {};
          nombre = (meta['nombre'] ?? meta['name'] ?? meta['full_name'])
              ?.toString();
        } catch (_) {}
        nombre ??= email?.split('@').first ?? 'Usuario';
        return {
          'id': id,
          'nombre': nombre,
          'email': email,
          'correo': email,
        };
      }

      throw Exception('No hay token de autenticación disponible');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      } else {
        throw Exception('No hay token de autenticación disponible');
      }

      final response = await http.put(
        Uri.parse(BackendConfig.profileUrl),
        headers: headers,
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

      throw Exception(
        'Error al actualizar perfil: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _clearAuthData();
      await SupabaseConfig.auth.signOut();
      // Google sign-out removed when Google Sign-In is disabled
    } catch (e) {
      rethrow;
    }
  }

  bool isLoggedIn() {
    return _authToken != null || SupabaseConfig.auth.currentSession != null;
  }

  String? getCurrentUserEmail() {
    return _userEmail ?? SupabaseConfig.auth.currentUser?.email;
  }

  String? getCurrentUserId() {
    return SupabaseConfig.auth.currentUser?.id;
  }

  String? getAuthToken() {
    return _authToken;
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
