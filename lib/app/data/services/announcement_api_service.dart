import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/request/announcement_request.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';

part 'announcement_api_service.g.dart';

@RestApi()
abstract class AnnouncementApiService {
  factory AnnouncementApiService(Dio dio, {String baseUrl}) =
      _AnnouncementApiService;

  /// Create new announcement
  @POST('/announcements')
  Future<AnnouncementResponse> createAnnouncement(
    @Body() CreateAnnouncementRequest request,
  );

  /// Get announcements with filters and pagination
  @GET('/announcements')
  Future<AnnouncementResponse> getAnnouncements({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('courseId') String? courseId,
    @Query('scopeType') String? scopeType,
    @Query('sortBy') String? sortBy,
    @Query('sortOrder') String? sortOrder,
  });

  /// Get announcement by ID
  @GET('/announcements/{id}')
  Future<AnnouncementResponse> getAnnouncementById(
    @Path('id') String id,
  );

  /// Update announcement
  @PUT('/announcements/{id}')
  Future<AnnouncementResponse> updateAnnouncement(
    @Path('id') String id,
    @Body() UpdateAnnouncementRequest request,
  );

  /// Delete announcement
  @DELETE('/announcements/{id}')
  Future<AnnouncementResponse> deleteAnnouncement(
    @Path('id') String id,
  );

  /// Get announcement comments
  @GET('/announcements/{id}/comments')
  Future<AnnouncementResponse> getAnnouncementComments(
    @Path('id') String id, {
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  /// Add comment to announcement
  @POST('/announcements/{id}/comments')
  Future<AnnouncementResponse> addComment(
    @Path('id') String id,
    @Body() AddCommentRequest request,
  );

  /// Track announcement view
  @POST('/announcements/{id}/views')
  Future<AnnouncementResponse> trackView(
    @Path('id') String id,
  );

  /// Track file download
  @POST('/announcements/files/{fileId}/downloads')
  Future<AnnouncementResponse> trackDownload(
    @Path('fileId') String fileId,
  );

  /// Get announcement tracking data
  @GET('/announcements/{id}/tracking')
  Future<AnnouncementResponse> getAnnouncementTracking(
    @Path('id') String id, {
    @Query('groupId') String? groupId,
    @Query('status') String? status,
  });

  /// Get file download tracking data
  @GET('/announcements/{id}/file-tracking')
  Future<AnnouncementResponse> getFileDownloadTracking(
    @Path('id') String id, {
    @Query('fileId') String? fileId,
  });
}
