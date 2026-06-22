import 'package:flutter/material.dart';
import '../services/assistant_service.dart';

class AssistantMessage {
  final String text;
  final bool fromUser;

  AssistantMessage({required this.text, required this.fromUser});
}

class AssistantProvider extends ChangeNotifier {
  final AssistantService _service = AssistantService();

  final List<AssistantMessage> _messages = [];
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(AssistantMessage(text: text, fromUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.sendMessage(message: text, history: _history);
      _history = result['history'] as List<Map<String, dynamic>>;
      _messages.add(AssistantMessage(text: result['reply'] as String, fromUser: false));
    } catch (e) {
      _errorMessage = e.toString();
      _messages.add(AssistantMessage(
        text: 'No pude responder en este momento. Intenta de nuevo en unos segundos.',
        fromUser: false,
      ));
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _history = [];
    _errorMessage = null;
    notifyListeners();
  }
}
