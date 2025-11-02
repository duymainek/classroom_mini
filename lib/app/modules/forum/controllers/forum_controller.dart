import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/forum_service.dart';
import 'package:classroom_mini/app/data/models/response/forum_response.dart';
import 'package:classroom_mini/app/data/services/sync_service.dart';
import 'package:classroom_mini/app/data/local/sync_queue_manager.dart';
import 'package:classroom_mini/app/data/network/interceptors/offline_interceptor.dart';

/**
 * Forum Controller
 * Manages forum topics list and interactions
 */
class ForumController extends GetxController {
  final ForumService _forumService = Get.find<ForumService>();
  final SyncService _syncService = Get.find<SyncService>();

  // State
  final topics = <ForumTopic>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  
  // Track pending operations: queueId -> topicId mapping
  final pendingTopicQueueIds = <String, String>{}.obs;

  // Filters
  final selectedSort = 'latest'.obs; // latest, popular, most_replied
  final searchQuery = ''.obs;

  // Pagination
  final int _limit = 20;
  int _offset = 0;

  @override
  void onInit() {
    super.onInit();
    loadTopics();
    _setupSyncListener();
  }
  
  void _setupSyncListener() {
    ever(_syncService.completedQueueIds, (Set<String> completed) {
      pendingTopicQueueIds.removeWhere((queueId, topicId) {
        if (completed.contains(queueId)) {
          return true;
        }
        if (!_syncService.isQueueIdPending(queueId)) {
          return true;
        }
        return false;
      });
    });
  }
  
  bool isTopicPending(String topicId) {
    return pendingTopicQueueIds.values.contains(topicId);
  }

  /// Load initial topics
  Future<void> loadTopics({bool refresh = false}) async {
    print('🔍 [ForumController] loadTopics called - refresh: $refresh');

    if (refresh) {
      _offset = 0;
      hasMore.value = true;
    }

    isLoading.value = true;

    try {
      print('🔍 [ForumController] Calling _forumService.getTopics...');
      final response = await _forumService.getTopics(
        sort: selectedSort.value,
        limit: _limit,
        offset: _offset,
      );

      print('🔍 [ForumController] Response received:');
      print('  - success: ${response.success}');
      print('  - data: ${response.data}');
      print('  - data length: ${response.data?.length}');

      if (response.success && response.data != null) {
        print('🔍 [ForumController] Processing topics...');
        for (int i = 0; i < response.data!.length; i++) {
          final topic = response.data![i];
          print('  Topic $i: ${topic.title}');
          print('    - id: ${topic.id}');
          print('    - author: ${topic.author.fullName}');
          print('    - replyCount: ${topic.replyCount}');
        }

        if (refresh) {
          topics.value = response.data!;
        } else {
          topics.addAll(response.data!);
        }

        hasMore.value = response.data!.length >= _limit;
        _offset += response.data!.length;
        print(
            '🔍 [ForumController] Topics loaded successfully. Total: ${topics.length}');
      } else {
        print('❌ [ForumController] Response failed or data is null');
      }
    } catch (e, stackTrace) {
      print('❌ [ForumController] Error loading topics: $e');
      print('❌ [ForumController] Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to load topics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more topics (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;

    try {
      final response = await _forumService.getTopics(
        sort: selectedSort.value,
        limit: _limit,
        offset: _offset,
      );

      if (response.success && response.data != null) {
        topics.addAll(response.data!);
        hasMore.value = response.data!.length >= _limit;
        _offset += response.data!.length;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more topics: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Change sort order
  void changeSort(String sort) {
    selectedSort.value = sort;
    loadTopics(refresh: true);
  }

  /// Search topics
  Future<void> searchTopics(String query) async {
    if (query.isEmpty) {
      loadTopics(refresh: true);
      return;
    }

    searchQuery.value = query;
    isLoading.value = true;

    try {
      final response = await _forumService.searchTopics(
        query: query,
      );

      if (response.success && response.data != null) {
        topics.value = response.data!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search topics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new topic
  Future<void> createTopic({
    required String title,
    required String content,
    List<String>? attachmentIds,
  }) async {
    print('🔍 [ForumController] createTopic called:');
    print('  - title: $title');
    print('  - content: $content');
    print('  - attachmentIds: $attachmentIds');

    try {
      print('🔍 [ForumController] Calling _forumService.createTopic...');
      final response = await _forumService.createTopic(
        title: title,
        content: content,
        attachmentIds: attachmentIds,
      );

      print('🔍 [ForumController] Create topic response:');
      print('  - success: ${response.success}');
      print('  - data: ${response.data}');
      
      String? queueId;
      try {
        queueId = PendingOperationTracker.getLatestQueueIdForPath('/forum/topics');
        if (queueId == null) {
          final pending = SyncQueueManager.getPending();
          final latestPending = pending.where((op) => 
            op.method == 'POST' && 
            op.path.contains('/forum/topics') &&
            op.data?['title'] == title
          ).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (latestPending.isNotEmpty) {
            queueId = latestPending.first.id;
            PendingOperationTracker.setQueueIdForPath('/forum/topics', queueId);
          }
        }
        print('📴 Found pending topic queueId: $queueId');
      } catch (e) {
        print('⚠️ Error checking pending operations: $e');
      }

      if (response.success && response.data != null) {
        print('🔍 [ForumController] Inserting new topic at index 0...');
        topics.insert(0, response.data!);
        
        if (queueId != null) {
          pendingTopicQueueIds[queueId] = response.data!.id;
          print('📴 Tracking pending topic: ${response.data!.id} -> $queueId');
        }
        
        print(
            '🔍 [ForumController] Topic inserted. Total topics: ${topics.length}');
        
        if (queueId != null) {
          Get.snackbar('Đã lưu', 'Chủ đề đã được lưu và sẽ được đồng bộ khi có mạng');
        } else {
          Get.snackbar('Success', 'Topic created successfully');
        }
      } else {
        print('❌ [ForumController] Create topic failed or data is null');
      }
    } catch (e, stackTrace) {
      print('❌ [ForumController] Error creating topic: $e');
      print('❌ [ForumController] Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to create topic: $e');
    }
  }

  /// Delete topic
  Future<void> deleteTopic(String topicId) async {
    try {
      final success = await _forumService.deleteTopic(topicId);
      if (success) {
        topics.removeWhere((topic) => topic.id == topicId);
        Get.snackbar('Success', 'Topic deleted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete topic: $e');
    }
  }

  /// Navigate to topic detail
  void goToTopicDetail(String topicId) {
    Get.toNamed('/forum/detail/$topicId');
  }

  /// Load more topics (alias for loadMore)
  Future<void> loadMoreTopics() async {
    await loadMore();
  }

  /// Refresh topics (alias for loadTopics with refresh)
  Future<void> refreshTopics() async {
    await loadTopics(refresh: true);
  }

  /// Check if there are more pages
  bool get hasMorePages => hasMore.value;

  /// Check if form is loading
  bool get isFormLoading => false;

  /// Get error message
  String? get errorMessage => null;

  /// Get courses list (placeholder)
  List<dynamic> get courses => [];

  /// Get selected course ID
  String? get selectedCourseId => null;

  /// Filter by course
  void filterByCourse(String? courseId) {
    // No longer needed for open forum
  }
}
