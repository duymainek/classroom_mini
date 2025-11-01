import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/request/chat_request.dart';
import 'package:classroom_mini/app/data/models/response/chat_response.dart';
import 'package:classroom_mini/app/data/models/response/base_response.dart';
import 'package:classroom_mini/app/data/models/response/data_response.dart';

part 'chat_api_service.g.dart';

@RestApi()
abstract class ChatApiService {
  factory ChatApiService(Dio dio, {String baseUrl}) = _ChatApiService;

  @GET('/chat/conversations')
  Future<DataResponse<ConversationsListResponse>> getConversations({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  @POST('/chat/rooms/direct')
  Future<DataResponse<ChatRoomResponse>> getOrCreateDirectRoom(
    @Body() CreateDirectRoomRequest request,
  );

  @GET('/chat/rooms/{roomId}')
  Future<DataResponse<ChatRoomResponse>> getRoomDetails(
    @Path('roomId') String roomId,
  );

  @GET('/chat/rooms/{roomId}/messages')
  Future<DataResponse<MessagesListResponse>> getRoomMessages(
    @Path('roomId') String roomId, {
    @Query('limit') int? limit,
    @Query('before') String? before,
  });

  @GET('/chat/rooms/{roomId}/search')
  Future<DataResponse<List<ChatMessageResponse>>> searchMessages(
    @Path('roomId') String roomId,
    @Query('q') String query, {
    @Query('limit') int? limit,
  });

  @PUT('/chat/rooms/{roomId}/hide')
  Future<BaseResponse> hideConversation(
    @Path('roomId') String roomId,
    @Body() Map<String, dynamic> body,
  );

  @PUT('/chat/rooms/{roomId}/mute')
  Future<BaseResponse> muteConversation(
    @Path('roomId') String roomId,
    @Body() Map<String, dynamic> body,
  );

  @POST('/chat/rooms/{roomId}/read')
  Future<BaseResponse> markAsRead(
    @Path('roomId') String roomId,
  );

  @GET('/chat/users/search')
  Future<DataResponse<List<SearchUserResponse>>> searchUsers({
    @Query('q') String? query,
    @Query('limit') int? limit,
  });

  @GET('/chat/unread-count')
  Future<DataResponse<UnreadCountResponse>> getUnreadCount();
}

