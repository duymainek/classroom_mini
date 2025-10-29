import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:classroom_mini/app/data/models/request/forum_request.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/data/models/response/base_response.dart';
import 'package:classroom_mini/app/data/models/response/data_response.dart';

part 'forum_api_service.g.dart';

@RestApi()
abstract class ForumApiService {
  factory ForumApiService(Dio dio, {String baseUrl}) = _ForumApiService;

  // =====================================================
  // TOPICS
  // =====================================================

  @POST('/forum/topics')
  Future<DataResponse<ForumTopic>> createTopic(
    @Body() CreateTopicRequest request,
  );

  @GET('/forum/topics')
  Future<DataResponse<List<ForumTopic>>> getTopics(
    @Query('sort') String? sort, // latest, popular, most_replied
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  );

  @GET('/forum/topics/{id}')
  Future<DataResponse<TopicDetailResponse>> getTopicById(
    @Path('id') String id,
  );

  @PUT('/forum/topics/{id}')
  Future<DataResponse<ForumTopic>> updateTopic(
    @Path('id') String id,
    @Body() UpdateTopicRequest request,
  );

  // ✅ Dùng BaseResponse cho delete (không có data)
  @DELETE('/forum/topics/{id}')
  Future<BaseResponse> deleteTopic(
    @Path('id') String id,
  );

  // ✅ Dùng BaseResponse cho track view (không có data)
  @POST('/forum/topics/{id}/views')
  Future<BaseResponse> trackTopicView(
    @Path('id') String id,
  );

  @GET('/forum/topics/search')
  Future<DataResponse<List<ForumTopic>>> searchTopics(
    @Query('q') String query,
  );

  // =====================================================
  // REPLIES
  // =====================================================

  @GET('/forum/topics/{topicId}/replies')
  Future<DataResponse<List<ForumReply>>> getTopicReplies(
    @Path('topicId') String topicId,
  );

  @POST('/forum/topics/{topicId}/replies')
  Future<DataResponse<ForumReply>> addReply(
    @Path('topicId') String topicId,
    @Body() CreateReplyRequest request,
  );

  @PUT('/forum/replies/{id}')
  Future<DataResponse<ForumReply>> updateReply(
    @Path('id') String id,
    @Body() UpdateReplyRequest request,
  );

  // ✅ Dùng BaseResponse
  @DELETE('/forum/replies/{id}')
  Future<BaseResponse> deleteReply(
    @Path('id') String id,
  );

  @POST('/forum/replies/{id}/like')
  Future<DataResponse<LikeResponse>> toggleLike(
    @Path('id') String id,
  );
}
