import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/services/forum_api_service.dart';
import 'package:classroom_mini/app/data/models/request/forum_request.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/data/models/response/data_response.dart';

/**
 * Forum Service
 * Handles forum-related business logic and API calls
 */
class ForumService extends GetxService {
  late final ForumApiService _forumApiService;

  @override
  void onInit() {
    super.onInit();
    _forumApiService = Get.find<ApiServiceWrapper>().forumApiService;
  }

  // =====================================================
  // TOPIC METHODS
  // =====================================================

  /// Create new forum topic
  Future<DataResponse<ForumTopic>> createTopic({
    required String title,
    required String content,
    List<String>? attachmentIds,
  }) async {
    try {
      print('🔍 [ForumService] createTopic called');
      final request = CreateTopicRequest(
        title: title,
        content: content,
        attachmentIds: attachmentIds,
      );
      print('🔍 [ForumService] Request created: ${request.toJson()}');

      print('🔍 [ForumService] Calling _forumApiService.createTopic...');
      final response = await _forumApiService.createTopic(request);
      print('🔍 [ForumService] API response received:');
      print('  - success: ${response.success}');
      print('  - data: ${response.data}');
      print('  - message: ${response.message}');

      return response;
    } catch (e, stackTrace) {
      print('❌ [ForumService] Error in createTopic: $e');
      print('❌ [ForumService] Stack trace: $stackTrace');
      throw Exception('Failed to create topic: $e');
    }
  }

  /// Get topics list with filters
  Future<DataResponse<List<ForumTopic>>> getTopics({
    String sort = 'latest',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('🔍 [ForumService] getTopics called');
      print('  - sort: $sort');
      print('  - limit: $limit');
      print('  - offset: $offset');

      print('🔍 [ForumService] Calling _forumApiService.getTopics...');
      final response = await _forumApiService.getTopics(
        sort,
        limit,
        offset,
      );
      print('🔍 [ForumService] API response received:');
      print('  - success: ${response.success}');
      print('  - data length: ${response.data?.length}');
      print('  - message: ${response.message}');

      return response;
    } catch (e, stackTrace) {
      print('❌ [ForumService] Error in getTopics: $e');
      print('❌ [ForumService] Stack trace: $stackTrace');
      throw Exception('Failed to get topics: $e');
    }
  }

  /// Get single topic by ID with replies
  Future<DataResponse<TopicDetailResponse>> getTopicById(String topicId) async {
    try {
      final response = await _forumApiService.getTopicById(topicId);
      return response;
    } catch (e) {
      throw Exception('Failed to get topic: $e');
    }
  }

  /// Update topic
  Future<DataResponse<ForumTopic>> updateTopic({
    required String topicId,
    String? title,
    String? content,
  }) async {
    try {
      final request = UpdateTopicRequest(
        title: title,
        content: content,
      );

      final response = await _forumApiService.updateTopic(topicId, request);
      return response;
    } catch (e) {
      throw Exception('Failed to update topic: $e');
    }
  }

  /// Delete topic
  Future<bool> deleteTopic(String topicId) async {
    try {
      final response = await _forumApiService.deleteTopic(topicId);
      return response.success;
    } catch (e) {
      throw Exception('Failed to delete topic: $e');
    }
  }

  /// Search topics
  Future<DataResponse<List<ForumTopic>>> searchTopics({
    required String query,
  }) async {
    try {
      final response = await _forumApiService.searchTopics(query);
      return response;
    } catch (e) {
      throw Exception('Failed to search topics: $e');
    }
  }

  /// Track topic view
  Future<bool> trackTopicView(String topicId) async {
    try {
      final response = await _forumApiService.trackTopicView(topicId);
      return response.success;
    } catch (e) {
      throw Exception('Failed to track view: $e');
    }
  }

  // =====================================================
  // REPLY METHODS
  // =====================================================

  /// Get replies for a topic
  Future<DataResponse<List<ForumReply>>> getTopicReplies(String topicId) async {
    try {
      final response = await _forumApiService.getTopicReplies(topicId);
      return response;
    } catch (e) {
      throw Exception('Failed to get replies: $e');
    }
  }

  /// Add reply to topic or reply
  Future<DataResponse<ForumReply>> addReply({
    required String topicId,
    required String content,
    String? parentReplyId,
    List<String>? attachmentIds,
  }) async {
    try {
      final request = CreateReplyRequest(
        content: content,
        parentReplyId: parentReplyId,
        attachmentIds: attachmentIds,
      );

      final response = await _forumApiService.addReply(topicId, request);
      return response;
    } catch (e) {
      throw Exception('Failed to add reply: $e');
    }
  }

  /// Update reply
  Future<DataResponse<ForumReply>> updateReply({
    required String replyId,
    required String content,
  }) async {
    try {
      final request = UpdateReplyRequest(content: content);
      final response = await _forumApiService.updateReply(replyId, request);
      return response;
    } catch (e) {
      throw Exception('Failed to update reply: $e');
    }
  }

  /// Delete reply
  Future<bool> deleteReply(String replyId) async {
    try {
      final response = await _forumApiService.deleteReply(replyId);
      return response.success;
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
    }
  }

  /// Toggle like on reply
  Future<DataResponse<LikeResponse>> toggleLike(String replyId) async {
    try {
      final response = await _forumApiService.toggleLike(replyId);
      return response;
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file icon based on file type
  String getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📋';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎥';
      case 'mp3':
      case 'wav':
        return '🎵';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }

  /// Validate topic content
  bool validateTopicContent(String title, String content) {
    return title.trim().isNotEmpty &&
        content.trim().isNotEmpty &&
        title.length <= 200;
  }

  /// Validate reply content
  bool validateReplyContent(String content) {
    return content.trim().isNotEmpty && content.length <= 500;
  }
}
