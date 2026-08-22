import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../models/ai_message_model.dart';

enum AiStatus { idle, thinking, error }

/// Manages the AI Safety Assistant conversation state.
///
/// Wired to POST /api/v1/ai/chat/. Until apps.ai_assistant.services.call_llm()
/// has a real provider plugged in on the backend, this will surface a clear
/// "assistant isn't set up yet" error rather than fake responses — see
/// SAFEHER_NEXT_STEPS.md for how to wire the LLM provider.
class AiProvider extends ChangeNotifier {
  AiStatus _status = AiStatus.idle;
  final List<AiMessageModel> _messages = [];
  String? _errorMessage;

  AiStatus get status => _status;
  List<AiMessageModel> get messages => List.unmodifiable(_messages);
  bool get isThinking => _status == AiStatus.thinking;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messages.add(AiMessageModel.user(text));
    _messages.add(AiMessageModel.typing());
    _status = AiStatus.thinking;
    notifyListeners();

    try {
      final response = await ApiService.instance.post('ai/chat/', data: {'message': text});
      _messages.removeWhere((m) => m.isTyping);
      final reply = (response.data as Map<String, dynamic>)['reply'] as String? ??
          "Sorry, I didn't get a reply.";
      _messages.add(AiMessageModel.ai(reply));
      _status = AiStatus.idle;
    } catch (e) {
      _messages.removeWhere((m) => m.isTyping);
      _errorMessage = e.toString();
      // Logged so `flutter run` shows the real cause instead of only the
      // generic in-app message below (a dead connection to the backend,
      // an expired auth token, and a real Gemini/server error all need
      // different fixes, but looked identical to the user before this).
      debugPrint('AI chat failed: $_errorMessage');

      String userMessage;
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout)) {
        userMessage = "Can't reach the server. Check that your phone and "
            "the backend are on the same Wi-Fi network, and that the app's "
            "server address (ApiConfig.lanUrl) matches the backend "
            "machine's current IP.";
      } else if (e is DioException &&
          e.response?.statusCode == 401) {
        userMessage = 'Your session has expired — please log in again.';
      } else {
        userMessage = "The safety assistant hit an error on the server side. "
            "Check the Django terminal output for the real cause "
            "(e.g. a missing/invalid GEMINI_API_KEY), or use the "
            'Emergency tab for immediate help.';
      }
      _messages.add(AiMessageModel.ai(userMessage));
      _status = AiStatus.error;
    }
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _status = AiStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
