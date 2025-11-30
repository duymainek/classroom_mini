import 'package:get/get.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../services/ai_chat_storage.dart';

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  AiChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class AiChatController extends GetxController {
  final messages = <AiChatMessage>[].obs;
  final isLoading = false.obs;
  final String systemPrompt = '''Bạn là một trợ lý AI thông minh chuyên hỗ trợ học tập. 
Nhiệm vụ của bạn là:
- Trả lời các câu hỏi liên quan đến học tập, giáo dục
- Giải thích các khái niệm, công thức, lý thuyết một cách dễ hiểu
- Hỗ trợ làm bài tập, ôn tập
- Đưa ra lời khuyên học tập hiệu quả
- Giúp đỡ với các vấn đề về kỹ năng học tập

Hãy luôn trả lời một cách thân thiện, dễ hiểu và tập trung vào việc hỗ trợ học tập.''';

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final savedMessages = await AiChatStorage.loadMessages();
    if (savedMessages.isNotEmpty) {
      messages.value = savedMessages;
    }
  }

  Future<void> _saveMessages() async {
    final messagesToSave = messages.where((m) => !m.isStreaming).toList();
    await AiChatStorage.saveMessages(messagesToSave);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);
    _saveMessages();

    final assistantMessageId = '${DateTime.now().millisecondsSinceEpoch + 1}';
    final assistantMessage = AiChatMessage(
      id: assistantMessageId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    messages.add(assistantMessage);
    isLoading.value = true;

    try {
      final conversationHistory = _buildConversationHistory();
      
      String fullResponse = '';
      await for (final candidate in Gemini.instance.streamChat(
        conversationHistory,
        modelName: 'models/gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      )) {
        if (candidate.output != null) {
          fullResponse += candidate.output!;
          
          final index = messages.indexWhere((m) => m.id == assistantMessageId);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              text: fullResponse,
              isStreaming: true,
            );
          }
        }
      }

      final index = messages.indexWhere((m) => m.id == assistantMessageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          text: fullResponse,
          isStreaming: false,
        );
        _saveMessages();
      }
    } catch (e) {
      final index = messages.indexWhere((m) => m.id == assistantMessageId);
      if (index != -1) {
        messages.removeAt(index);
      }
      Get.snackbar(
        'Lỗi',
        'Không thể gửi tin nhắn. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<Content> _buildConversationHistory() {
    final history = <Content>[];

    history.add(Content(
      parts: [Part.text(systemPrompt)],
      role: 'user',
    ));

    for (final message in messages) {
      if (message.isUser) {
        history.add(Content(
          parts: [Part.text(message.text)],
          role: 'user',
        ));
      } else if (message.text.isNotEmpty) {
        history.add(Content(
          parts: [Part.text(message.text)],
          role: 'model',
        ));
      }
    }

    return history;
  }

  Future<void> clearMessages() async {
    messages.clear();
    await AiChatStorage.clearMessages();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

