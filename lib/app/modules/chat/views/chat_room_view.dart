import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/chat_room_controller.dart';
import '../../../data/models/response/chat_response.dart';
import '../../../core/services/auth_service.dart';

class ChatRoomView extends StatelessWidget {
  const ChatRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatRoomController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: controller.conversation.displayAvatar != null
                  ? CachedNetworkImageProvider(controller.conversation.displayAvatar!)
                  : null,
              child: controller.conversation.displayAvatar == null
                  ? Text(controller.conversation.displayName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.conversation.displayName),
                  Obx(() {
                    final typingUsers = controller.typingUsers;
                    if (typingUsers.isNotEmpty) {
                      return const Text(
                        'Typing...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }
                    if (controller.conversation.otherUser?.isOnline == true) {
                      return const Text(
                        'Online',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                reverse: true,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return _MessageBubble(message: message);
                },
              );
            }),
          ),
          _MessageInput(controller: controller),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageResponse message;

  const _MessageBubble({required this.message});

  bool get isMe {
    final authService = Get.find<AuthService>();
    final currentUserId = authService.user.value?.id ?? '';
    return message.authorId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && message.author != null)
              Text(
                message.author!.fullName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            if (message.isTextMessage)
              Text(
                message.text ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            if (message.isImageMessage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.uri ?? '',
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported);
                  },
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message.displayTime,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final ChatRoomController controller;

  const _MessageInput({required this.controller});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.messageText.value);
    _focusNode = FocusNode();
    widget.controller.messageText.listen((value) {
      if (_textController.text != value) {
        _textController.text = value;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.controller.messageText.value = value;
                  widget.controller.onTyping(value.isNotEmpty);
                },
                onSubmitted: (value) {
                  widget.controller.sendMessage();
                  // Keep focus after sending
                  _focusNode.requestFocus();
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                widget.controller.sendMessage();
                // Keep focus after sending
                _focusNode.requestFocus();
              },
            ),
          ],
        ),
      ),
    );
  }
}

