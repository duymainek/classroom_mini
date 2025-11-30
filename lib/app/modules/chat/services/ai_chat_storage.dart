import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/ai_chat_controller.dart';

class AiChatStorage {
  static const String _messagesKey = 'ai_chat_messages';

  static Future<void> saveMessages(List<AiChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((msg) => {
        'id': msg.id,
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
        'isStreaming': msg.isStreaming,
      }).toList();
      
      final jsonString = jsonEncode(messagesJson);
      await prefs.setString(_messagesKey, jsonString);
    } catch (e) {
      // Ignore storage errors
    }
  }

  static Future<List<AiChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messagesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final messagesJson = jsonDecode(jsonString) as List<dynamic>;
      return messagesJson.map((json) {
        final map = json as Map<String, dynamic>;
        return AiChatMessage(
          id: map['id'] as String,
          text: map['text'] as String,
          isUser: map['isUser'] as bool,
          timestamp: DateTime.parse(map['timestamp'] as String),
          isStreaming: map['isStreaming'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
    } catch (e) {
      // Ignore storage errors
    }
  }
}

