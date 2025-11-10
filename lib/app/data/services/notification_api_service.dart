import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/response/notification_response.dart';

part 'notification_api_service.g.dart';

@RestApi()
abstract class NotificationApiService {
  factory NotificationApiService(Dio dio, {String baseUrl}) =
      _NotificationApiService;

  @GET('/notifications')
  Future<NotificationResponse> getNotifications({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('unreadOnly') bool? unreadOnly,
  });

  @GET('/notifications/unread-count')
  Future<NotificationResponse> getUnreadCount();

  @PUT('/notifications/{id}/read')
  Future<NotificationResponse> markAsRead(
    @Path('id') String id,
  );

  @PUT('/notifications/read-all')
  Future<NotificationResponse> markAllAsRead();

  @DELETE('/notifications/{id}')
  Future<NotificationResponse> deleteNotification(
    @Path('id') String id,
  );

  @DELETE('/notifications/read')
  Future<NotificationResponse> deleteAllRead();
}

