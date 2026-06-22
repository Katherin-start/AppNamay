import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import 'storage_service.dart';

class AssistantService {
  final _storage = StorageService();

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    final token = await _storage.getAuthToken();
    if (token == null) {
      throw Exception('No hay token de autenticación disponible');
    }

    final response = await http.post(
      Uri.parse(BackendConfig.assistantChatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message, 'history': history}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'reply': data['reply']?.toString() ?? '',
        'history': data['history'] is List
            ? List<Map<String, dynamic>>.from(
                (data['history'] as List).whereType<Map>().map(
                      (e) => Map<String, dynamic>.from(e),
                    ),
              )
            : history,
      };
    }

    String errorMessage = 'No se pudo contactar al asistente';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) errorMessage = data['message'].toString();
    } catch (_) {}
    throw Exception(errorMessage);
  }
}
