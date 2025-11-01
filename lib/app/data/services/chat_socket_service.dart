import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/models/request/chat_request.dart';
import 'package:classroom_mini/app/data/models/response/chat_response.dart';
import 'package:classroom_mini/app/core/constants/api_endpoints.dart';

class ChatSocketService extends GetxService {
  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  final RxString currentRoomId = ''.obs;
  
  Function(ChatMessageResponse)? onNewMessage;
  Function(String roomId, ChatMessageResponse)? onNewMessageNotification;
  Function(String userId, bool isTyping)? onUserTyping;
  Function(String userId)? onUserJoined;
  Function(String userId)? onUserLeft;
  Function(String messageId)? onMessagesRead;
  Function(String tempId, ChatMessageResponse)? onMessageSent;

  Future<void> connect(String token) async {
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    final socketUrl = ApiEndpoints.socketUrl;
    
    _socket = IO.io(
      '$socketUrl/chat',
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      isConnected.value = false;
      currentRoomId.value = '';
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    _setupGlobalListeners();
  }

  void _setupGlobalListeners() {
    _socket!.on('new_message_notification', (data) {
      print('New message notification: $data');
      final roomId = data['roomId'] as String;
      final messageData = data['message'] as Map<String, dynamic>;
      final message = ChatMessageResponse.fromJson(messageData);
      
      onNewMessageNotification?.call(roomId, message);
    });

    _socket!.on('error', (data) {
      print('Socket error: $data');
      Get.snackbar('Error', data['message'] ?? 'Socket error occurred');
    });
  }

  void joinRoom(String roomId) {
    if (!isConnected.value) {
      print('Socket not connected, cannot join room');
      return;
    }

    if (currentRoomId.value == roomId) {
      print('Already in room $roomId');
      return;
    }

    print('Joining room: $roomId');
    _socket!.emit('join_room', {'roomId': roomId});
    
    currentRoomId.value = roomId;
    _setupRoomListeners(roomId);
    
    _socket!.once('joined_room', (data) {
      print('Successfully joined room: ${data['roomId']}');
    });
  }

  void _setupRoomListeners(String roomId) {
    _socket!.on('new_message', (data) {
      print('New message in room $roomId: $data');
      final message = ChatMessageResponse.fromJson(data as Map<String, dynamic>);
      onNewMessage?.call(message);
    });

    _socket!.on('user_typing', (data) {
      final userId = data['userId'] as String;
      final isTyping = data['isTyping'] as bool;
      onUserTyping?.call(userId, isTyping);
    });

    _socket!.on('user_joined', (data) {
      final userId = data['userId'] as String;
      onUserJoined?.call(userId);
    });

    _socket!.on('user_left', (data) {
      final userId = data['userId'] as String;
      onUserLeft?.call(userId);
    });

    _socket!.on('messages_read', (data) {
      final lastMessageId = data['lastMessageId'] as String;
      onMessagesRead?.call(lastMessageId);
    });

    _socket!.on('message_sent', (data) {
      print('Message sent confirmation: $data');
      final tempId = data['tempId'];
      final messageData = data['message'] as Map<String, dynamic>;
      final message = ChatMessageResponse.fromJson(messageData);
      onMessageSent?.call(tempId, message);
    });
  }

  void leaveRoom() {
    if (currentRoomId.value.isEmpty) return;

    print('Leaving room: ${currentRoomId.value}');
    _socket!.emit('leave_room', {'roomId': currentRoomId.value});
    
    _socket!.off('new_message');
    _socket!.off('user_typing');
    _socket!.off('user_joined');
    _socket!.off('user_left');
    _socket!.off('messages_read');
    _socket!.off('message_sent');
    
    currentRoomId.value = '';
  }

  void sendMessage(SendMessageRequest request) {
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to chat server');
      return;
    }

    if (currentRoomId.value != request.roomId) {
      Get.snackbar('Error', 'Not in the correct room');
      return;
    }

    print('Sending message: ${request.toJson()}');
    _socket!.emit('send_message', request.toJson());
  }

  void sendTypingIndicator(String roomId, bool isTyping) {
    if (!isConnected.value || currentRoomId.value != roomId) return;
    
    _socket!.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void markAsRead(String roomId, String lastMessageId) {
    if (!isConnected.value) return;
    
    _socket!.emit('mark_read', {
      'roomId': roomId,
      'lastMessageId': lastMessageId,
    });
  }

  void disconnect() {
    if (currentRoomId.value.isNotEmpty) {
      leaveRoom();
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    
    print('Socket disconnected and disposed');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}

