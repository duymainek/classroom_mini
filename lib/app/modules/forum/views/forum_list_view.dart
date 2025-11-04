import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/modules/forum/controllers/forum_controller.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_topic_card.dart';
import 'package:classroom_mini/app/modules/forum/widgets/forum_topic_form.dart';
import 'package:classroom_mini/app/modules/forum/design/forum_design_system.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';

/**
 * Enhanced Forum List View
 * Implements responsive design and improved UX patterns
 */
class ForumListView extends StatefulWidget {
  const ForumListView({super.key});

  @override
  State<ForumListView> createState() => _ForumListViewState();
}

class _ForumListViewState extends State<ForumListView>
    with TickerProviderStateMixin {
  late ForumController controller;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _setupController();
    _setupAnimations();
    _setupScrollListener();
  }

  void _setupController() {
    if (!Get.isRegistered<ForumController>()) {
      Get.put(ForumController());
    }
    controller = Get.find<ForumController>();

    // Force reload topics if list is empty
    if (controller.topics.isEmpty && !controller.isLoading.value) {
      print('🔍 [ForumListView] Topics list is empty, forcing reload...');
      controller.loadTopics(refresh: true);
    }
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: ForumDesignSystem.animationNormal,
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: ForumAnimations.bounceOut,
    ));

    _fabAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showFab = _scrollController.offset < 100;
      if (showFab != _showFab) {
        setState(() => _showFab = showFab);
        if (showFab) {
          _fabAnimationController.forward();
        } else {
          _fabAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width >= ForumDesignSystem.tabletBreakpoint;

    return Scaffold(
      backgroundColor: ForumDesignSystem.getSurfaceColor(context),
      appBar: _buildAppBar(context, isTablet),
      body: _buildBody(context, isTablet),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    return AppBar(
      backgroundColor:
          ForumDesignSystem.getSurfaceColor(context, isElevated: true),
      elevation: ForumDesignSystem.elevationSM,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ForumDesignSystem.spacingSM),
            decoration: BoxDecoration(
              color: ForumDesignSystem.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
            ),
            child: Icon(
              Icons.forum,
              color: ForumDesignSystem.primary,
              size: ForumDesignSystem.iconMD,
            ),
          ),
          SizedBox(width: ForumDesignSystem.spacingMD),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forum',
                style: ForumDesignSystem.headingStyle.copyWith(
                  color: ForumDesignSystem.getTextColor(context),
                ),
              ),
              Text(
                'Open Discussion',
                style: ForumDesignSystem.captionStyle.copyWith(
                  color: ForumDesignSystem.getTextColor(context,
                      isSecondary: true),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isTablet) ...[
          _buildSortButton(context),
          SizedBox(width: ForumDesignSystem.spacingSM),
        ],
        _buildCreateButton(context),
        SizedBox(width: ForumDesignSystem.spacingMD),
      ],
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return Obx(() => PopupMenuButton<String>(
          onSelected: (value) {
            controller.selectedSort.value = value;
            controller.loadTopics(refresh: true);
            HapticFeedback.lightImpact();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'latest',
              child: Row(
                children: [
                  Icon(Icons.access_time),
                  SizedBox(width: 8),
                  Text('Latest'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'popular',
              child: Row(
                children: [
                  Icon(Icons.trending_up),
                  SizedBox(width: 8),
                  Text('Popular'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'most_replied',
              child: Row(
                children: [
                  Icon(Icons.chat_bubble),
                  SizedBox(width: 8),
                  Text('Most Replied'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ForumDesignSystem.spacingMD,
              vertical: ForumDesignSystem.spacingSM,
            ),
            decoration: BoxDecoration(
              color: ForumDesignSystem.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
              border: Border.all(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort,
                  size: ForumDesignSystem.iconSM,
                  color: ForumDesignSystem.getTextColor(context,
                      isSecondary: true),
                ),
                SizedBox(width: ForumDesignSystem.spacingSM),
                Text(
                  'Sort',
                  style: ForumDesignSystem.captionStyle.copyWith(
                    color: ForumDesignSystem.getTextColor(context,
                        isSecondary: true),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildCreateButton(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    return Obx(() {
      if (!connectivityService.isOnline.value) {
        return const SizedBox.shrink();
      }
      return IconButton(
        onPressed: () => _showCreateTopicDialog(context),
        icon: Icon(
          Icons.add,
          color: ForumDesignSystem.primary,
        ),
        style: IconButton.styleFrom(
          backgroundColor: ForumDesignSystem.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ForumDesignSystem.radiusMD),
          ),
        ),
      );
    });
  }

  Widget _buildBody(BuildContext context, bool isTablet) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState(context);
      }

      if (controller.topics.isEmpty) {
        return _buildEmptyState(context);
      }

      return _buildTopicsList(context, isTablet);
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(ForumDesignSystem.primary),
          ),
          SizedBox(height: ForumDesignSystem.spacingMD),
          Text(
            'Loading topics...',
            style: ForumDesignSystem.bodyStyle.copyWith(
              color: ForumDesignSystem.getTextColor(context, isSecondary: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ForumDesignSystem.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ForumDesignSystem.spacingXL),
              decoration: BoxDecoration(
                color: ForumDesignSystem.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ForumDesignSystem.radiusXL),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: ForumDesignSystem.iconXL * 2,
                color: ForumDesignSystem.primary,
              ),
            ),
            SizedBox(height: ForumDesignSystem.spacingLG),
            Text(
              'No topics yet',
              style: ForumDesignSystem.headingStyle.copyWith(
                color: ForumDesignSystem.getTextColor(context),
              ),
            ),
            SizedBox(height: ForumDesignSystem.spacingSM),
            Text(
              'Be the first to start a discussion!',
              style: ForumDesignSystem.bodyStyle.copyWith(
                color:
                    ForumDesignSystem.getTextColor(context, isSecondary: true),
              ),
              textAlign: TextAlign.center,
            ),
            Obx(() {
              final connectivityService = Get.find<ConnectivityService>();
              if (!connectivityService.isOnline.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  SizedBox(height: ForumDesignSystem.spacingLG),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTopicDialog(context),
                    icon: Icon(Icons.add),
                    label: Text('Create First Topic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ForumDesignSystem.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: ForumDesignSystem.spacingLG,
                        vertical: ForumDesignSystem.spacingMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ForumDesignSystem.radiusMD),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsList(BuildContext context, bool isTablet) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await controller.loadTopics(refresh: true);
      },
      color: ForumDesignSystem.primary,
      backgroundColor: ForumDesignSystem.getSurfaceColor(context),
      strokeWidth: 2.5,
      displacement: 40.0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ForumDesignSystem.getResponsivePadding(context),
        itemCount: controller.topics.length,
        itemBuilder: (context, index) {
          final topic = controller.topics[index];
          return AnimatedContainer(
            duration: ForumDesignSystem.animationFast,
            curve: ForumAnimations.easeOut,
            child: ForumTopicCard(
              topic: topic,
              onTap: () {
                HapticFeedback.lightImpact();
                Get.toNamed('/forum/detail/${topic.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    return Obx(() {
      if (!connectivityService.isOnline.value) {
        return const SizedBox.shrink();
      }
      return ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'forum_fab',
          onPressed: () => _showCreateTopicDialog(context),
          backgroundColor: ForumDesignSystem.primary,
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text('New Topic'),
          elevation: ForumDesignSystem.elevationLG,
        ),
      );
    });
  }

  void _showCreateTopicDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForumTopicForm(),
    );
  }
}
