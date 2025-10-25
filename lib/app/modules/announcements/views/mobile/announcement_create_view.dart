import 'package:flutter/material.dart';
import '../../widgets/announcement_form.dart';

/// Announcement Create Page
/// Wrapper for AnnouncementForm widget for creating new announcements
class MobileAnnouncementCreateView extends StatelessWidget {
  const MobileAnnouncementCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnouncementForm();
  }
}
