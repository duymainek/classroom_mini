import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../dashboard/views/responsive_dashboard_page.dart';
import '../../notification/views/notification_view.dart';
import '../../profile/views/profile_view.dart';
import '../../forum/views/forum_list_view.dart';
import '../../chat/views/chat_list_view.dart';
import '../../../../app/shared/widgets/sync_status_bar.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: Obx(() => IndexedStack(
                  index: controller.selectedIndex.value,
                  children: const [
                    ResponsiveDashboardPage(),
                    ForumListView(),
                    ChatListView(),
                    NotificationView(),
                    ProfileView(),
                  ],
                )),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: controller.selectedIndex.value,
            onTap: controller.changeTabIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                activeIcon: Icon(Icons.forum),
                label: 'Forum',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          )),
    );
  }
}
