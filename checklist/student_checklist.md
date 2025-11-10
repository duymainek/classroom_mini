# STUDENT FEATURES - IMPLEMENTATION PLAN

## 🎯 PHÂN TÍCH FEATURES

### ✅ ĐÃ CÓ - REUSE TỪ INSTRUCTOR (70%)

| Feature | Status | Notes |
|---------|--------|-------|
| **Authentication** | ✅ Reuse | Chỉ cần thêm student role check |
| **Profile Management** | ✅ Reuse | Same UI, different permissions |
| **Forum** | ✅ Reuse 90% | Students = equal rights, chỉ thêm role badge |
| **Private Chat** | ✅ Reuse 100% | Đã implement full cho cả 2 roles |
| **View Courses** | ✅ Reuse UI | Khác logic: enrolled courses vs owned courses |
| **View Announcements** | ✅ Reuse UI | Khác scope: student chỉ thấy trong scope |
| **View Materials** | ✅ Reuse UI | Student view + download tracking |
| **View Assignments** | ⚠️ Partial | UI reuse, thêm submission features |
| **View Quizzes** | ⚠️ Partial | UI reuse, thêm take quiz features |

### 🆕 CẦN IMPLEMENT MỚI (30%)

| Feature | Priority | Complexity |
|---------|----------|-----------|
| **Homepage - Enrolled Courses** | 🔴 High | Medium |  
| **Personal Dashboard** | 🔴 High | Medium |
| **Submit Assignment** | 🔴 High | High |
| **Take Quiz** | 🔴 High | High |
| **View Grades & Feedback** | 🔴 High | Low |
| **Notifications System** | 🟡 Medium | High |
| **Progress Tracking** | 🟡 Medium | Medium |
| **Deadline Calendar** | 🟢 Low | Low |

---

## 📋 STUDENT FEATURES CHECKLIST

## A. AUTHENTICATION & ROLE DETECTION

- [ ] **Role Detection System**
  - [ ] Add `role` field to User model (instructor/student)
  - [ ] Create `AuthService.currentUserRole` getter
  - [ ] Create `RoleMiddleware` for route protection
  - [ ] Create `@RequireRole(['student'])` annotation
  - [ ] Update login flow to detect role từ token/response
  - [ ] Store role in local storage (GetStorage/SharedPreferences)

- [ ] **Role-Based Navigation**
  - [ ] Create separate route configs:
    - `InstructorRoutes` - /instructor/...
    - `StudentRoutes` - /student/...
  - [ ] Redirect after login based on role:
    - instructor → `/instructor/dashboard`
    - student → `/student/home`
  - [ ] Implement bottom navigation for each role
  - [ ] Block access to wrong role routes (404 or redirect)

---

## B. HOMEPAGE - ENROLLED COURSES

- [ ] **Course List View (Student)**
  - [ ] API: `GET /student/courses/enrolled`
  - [ ] Show only enrolled courses (not all courses)
  - [ ] Course card displays:
    - [ ] Cover image
    - [ ] Course name
    - [ ] Instructor name
    - [ ] Progress bar (% completed)
    - [ ] Upcoming deadline badge
  - [ ] Empty state: "You are not enrolled in any courses"
  - [ ] Pull-to-refresh functionality
  - [ ] Cache enrolled courses (TTL: 1 hour)

- [ ] **Semester Switcher (Student)**
  - [ ] Dropdown to select semester
  - [ ] Default: current (latest) semester
  - [ ] Past semesters: READ-ONLY mode
  - [ ] Show indicator: "Past semester - view only"
  - [ ] Disable submit/quiz actions in past semesters

---

## C. COURSE SPACE (Student View - 3 TABS)

### Stream Tab (Reuse 90%)

- [ ] **View Announcements** ✅ Reuse
  - [ ] Filter: only show announcements in scope (student's group)
  - [ ] Mark announcement as viewed (track view)
  - [ ] Download files (track download)

- [ ] **Comment on Announcements** ✅ Reuse
  - [ ] Post comments (same as instructor)
  - [ ] Reply to instructor/other students
  - [ ] No special badge (not instructor)

### Classwork Tab (Need Updates)

- [ ] **View Assignments**
  - [ ] Reuse instructor UI for list view
  - [ ] Show submission status per student:
    - [ ] Not submitted (red)
    - [ ] Submitted (green)
    - [ ] Late submission (orange)
    - [ ] Graded (show score)
  - [ ] Filter: All / Not Submitted / Submitted / Graded
  - [ ] Sort: Deadline / Title
  - [ ] Click → Open assignment detail

- [ ] **Assignment Detail (Student)**
  - [ ] Show assignment info (reuse instructor UI)
  - [ ] **Submission Section** (NEW):
    - [ ] File upload area (drag & drop or browse)
    - [ ] Multiple files support (within limits)
    - [ ] Preview uploaded files
    - [ ] Submit button
    - [ ] Attempt counter: "Attempt 1 of 3"
    - [ ] Late submission warning
  - [ ] **Submission History** (NEW):
    - [ ] List all attempts with timestamps
    - [ ] Download submitted files
    - [ ] View grade & feedback (if graded)
  - [ ] Disable submit if:
    - [ ] Past deadline and late not allowed
    - [ ] Max attempts reached
    - [ ] Past semester (read-only)

- [ ] **View Quizzes**
  - [ ] Reuse instructor UI for list view
  - [ ] Show quiz status:
    - [ ] Not started
    - [ ] In progress (if time window open)
    - [ ] Completed (show score)
    - [ ] Closed (time window passed)
  - [ ] Click → Open quiz detail or take quiz

- [ ] **Quiz Detail (Student)**
  - [ ] Show quiz info (reuse instructor UI)
  - [ ] **Quiz Status Display**:
    - [ ] If not open yet: "Opens on [date]"
    - [ ] If open: "Take Quiz" button
    - [ ] If completed: Show score + review answers
    - [ ] If closed: "Quiz closed"
  - [ ] **Attempt Info**:
    - [ ] Attempts used: "1 of 3"
    - [ ] Remaining time (if active attempt)

- [ ] **Take Quiz (NEW)**
  - [ ] Start quiz flow:
    - [ ] Confirmation dialog with rules
    - [ ] Timer starts on confirm
  - [ ] Quiz interface:
    - [ ] Question counter: "5 of 10"
    - [ ] Timer countdown (prominent)
    - [ ] Question text + options (radio buttons)
    - [ ] Previous/Next navigation
    - [ ] Flag for review
    - [ ] Submit quiz button (with confirmation)
  - [ ] Auto-submit when time expires
  - [ ] Show score immediately (if configured)
  - [ ] Navigate back to quiz detail

- [ ] **View Materials** ✅ Reuse
  - [ ] Same UI as instructor
  - [ ] Track view when opened
  - [ ] Track download when file downloaded

### People Tab ✅ Reuse

- [ ] Same as instructor:
  - [ ] View groups in course
  - [ ] View students in course
  - [ ] No edit permissions

---

## D. PERSONAL DASHBOARD (NEW)

- [ ] **Dashboard Overview**
  - [ ] Section: Assignments
    - [ ] Submitted count
    - [ ] Pending count
    - [ ] Late count
    - [ ] Average grade (if graded)
  - [ ] Section: Quizzes
    - [ ] Completed count
    - [ ] Pending count
    - [ ] Average score
  - [ ] Section: Upcoming Deadlines
    - [ ] List next 5 deadlines (assignments + quizzes)
    - [ ] Countdown timer for nearest deadline
    - [ ] Color coding: Red (< 24h), Orange (< 3 days), Green (> 3 days)
  - [ ] Section: Progress Chart
    - [ ] Line chart: grades over time
    - [ ] Bar chart: completed vs pending

- [ ] **Past Semester Dashboard**
  - [ ] Same layout, read-only
  - [ ] Show final grades
  - [ ] No pending/upcoming items

---

## E. GRADES & FEEDBACK

- [ ] **Grades Page**
  - [ ] API: `GET /student/grades?course_id=xxx`
  - [ ] Table view:
    - [ ] Assignment/Quiz name
    - [ ] Submitted date
    - [ ] Grade/Score
    - [ ] Feedback (expandable)
    - [ ] Status: Pending / Graded
  - [ ] Filter by: Course, Type (Assignment/Quiz), Status
  - [ ] Sort by: Date / Grade
  - [ ] Export grades (CSV) - optional

- [ ] **Feedback Detail Dialog**
  - [ ] Show instructor feedback (full text)
  - [ ] Show grade
  - [ ] Show submitted files (if assignment)
  - [ ] Download graded files (if any)
  - [ ] Close button

---

## F. NOTIFICATIONS (NEW - HIGH PRIORITY)

### In-App Notifications

- [ ] **Notification Model**
  ```dart
  class Notification {
    String id;
    String userId;
    String type; // announcement, deadline, grade, feedback, submission
    String title;
    String body;
    Map<String, dynamic> data; // link to resource
    bool isRead;
    DateTime createdAt;
  }
  ```

- [ ] **Notification API**
  - [ ] `GET /student/notifications` - Get all notifications
  - [ ] `GET /student/notifications/unread-count` - Get unread count
  - [ ] `PUT /student/notifications/:id/read` - Mark as read
  - [ ] `PUT /student/notifications/read-all` - Mark all as read
  - [ ] `DELETE /student/notifications/:id` - Delete notification

- [ ] **Notification Service (Backend)**
  - [ ] Create notification when:
    - [ ] New announcement published (in student's scope)
    - [ ] Assignment/quiz deadline approaching (24h, 1h)
    - [ ] Grade posted
    - [ ] Feedback added
    - [ ] Assignment/quiz submission confirmed
  - [ ] Store in database: `notifications` table
  - [ ] Optional: Send via Socket.IO for real-time

- [ ] **Notification Center UI**
  - [ ] Bell icon in AppBar with badge count
  - [ ] Tap bell → open notifications panel (bottom sheet or page)
  - [ ] Notification list:
    - [ ] Icon based on type
    - [ ] Title + timestamp
    - [ ] Body preview (1-2 lines)
    - [ ] Unread indicator (blue dot or bold text)
    - [ ] Tap → mark as read + navigate to resource
  - [ ] Actions:
    - [ ] Mark all as read
    - [ ] Clear all (delete)
  - [ ] Empty state: "No notifications"
  - [ ] Pull-to-refresh

- [ ] **Real-time Updates (Optional)**
  - [ ] Socket.IO listener for new notifications
  - [ ] Show toast/snackbar when new notification arrives
  - [ ] Update badge count immediately
  - [ ] Add to notification list without refresh

### Email Notifications (Backend)

- [ ] **Email Service Setup**
  - [ ] Choose email provider: SendGrid / AWS SES / Mailgun
  - [ ] Setup email templates:
    - [ ] New announcement template
    - [ ] Deadline reminder template
    - [ ] Grade posted template
    - [ ] Submission confirmation template
  - [ ] Queue email jobs (use Bull/Bee-Queue or similar)

- [ ] **Email Triggers**
  - [ ] Send email when:
    - [ ] New announcement (immediate)
    - [ ] Deadline approaching (24h before, 1h before)
    - [ ] Grade posted (immediate)
    - [ ] Submission confirmed (immediate)
  - [ ] Email content:
    - [ ] Subject line
    - [ ] Preview text
    - [ ] Link to resource in app
    - [ ] Unsubscribe link (optional)

- [ ] **Email Preferences (Optional)**
  - [ ] Student can configure:
    - [ ] Enable/disable email notifications
    - [ ] Choose notification types
    - [ ] Digest mode (daily summary vs immediate)

---

## G. PROGRESS TRACKING

- [ ] **Progress Calculation**
  - [ ] API: `GET /student/progress?course_id=xxx`
  - [ ] Calculate:
    - [ ] Completion percentage (submitted assignments + completed quizzes / total)
    - [ ] Grade average
    - [ ] Attendance (if tracked)
    - [ ] Participation score (forum posts, comments)

- [ ] **Progress Widgets**
  - [ ] Circular progress indicator on course card
  - [ ] Progress bar on dashboard
  - [ ] Progress chart (line graph over time)
  - [ ] Comparison with class average (optional)

---

## H. FORUM (Minor Updates)

- [ ] **Student-Specific Features**
  - [ ] Create topics ✅ Already implemented (equal rights)
  - [ ] Reply to topics ✅ Already implemented
  - [ ] Like replies ✅ Already implemented
  - [ ] Edit own posts ✅ Already implemented
  - [ ] Delete own posts ✅ Already implemented

- [ ] **UI Updates**
  - [ ] Remove "Instructor" badge from student posts
  - [ ] Show student role badge (optional: "Student" or class/group)
  - [ ] Same attachment support as instructor

---

## I. PRIVATE MESSAGING ✅ COMPLETE

- [ ] **Already Implemented** (100% done)
  - [ ] Send/receive messages
  - [ ] Real-time via Socket.IO
  - [ ] Typing indicators
  - [ ] Read receipts
  - [ ] Search users (find instructor)
  - [ ] Unread count

- [ ] **No Changes Needed**

---

## J. OFFLINE CAPABILITY (Same as Instructor)

- [ ] **Cache Strategy** (Reuse same interceptor)
  - [ ] Cache enrolled courses (1 hour)
  - [ ] Cache course materials (1 day)
  - [ ] Cache announcements (6 hours)
  - [ ] Cache assignment list (1 hour)
  - [ ] Cache quiz list (1 hour)
  - [ ] Cache grades (1 hour)
  - [ ] Cache dashboard metrics (1 hour)

- [ ] **Offline Behavior**
  - [ ] View cached data with indicator
  - [ ] Cannot submit assignments offline
  - [ ] Cannot take quizzes offline
  - [ ] Cannot post forum replies offline
  - [ ] Show "Offline mode" banner

---

## K. UI/UX (Student-Specific)

- [ ] **Bottom Navigation**
  ```dart
  BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icons.home, label: 'Home'),
      BottomNavigationBarItem(icon: Icons.assignment, label: 'Assignments'),
      BottomNavigationBarItem(icon: Icons.quiz, label: 'Quizzes'),
      BottomNavigationBarItem(icon: Icons.forum, label: 'Forum'),
      BottomNavigationBarItem(icon: Icons.person, label: 'Profile'),
    ],
  )
  ```

- [ ] **AppBar Actions**
  - [ ] Notification bell (with badge)
  - [ ] Chat icon (navigate to messages)
  - [ ] Search icon

- [ ] **Color Scheme**
  - [ ] Different from instructor (optional)
  - [ ] Student: Blue/Purple theme
  - [ ] Instructor: Green/Teal theme (current)

---

## 📊 IMPLEMENTATION PRIORITY

### Phase 1: Core Features (Week 1-2)
1. ✅ Role detection & navigation
2. ✅ Homepage - enrolled courses
3. ✅ View course content (announcements, materials)
4. ✅ Personal dashboard (basic)

### Phase 2: Submissions (Week 3-4)
5. ✅ Submit assignments (file upload)
6. ✅ Take quizzes (quiz interface)
7. ✅ View grades & feedback

### Phase 3: Engagement (Week 5)
8. ✅ In-app notifications (basic)
9. ✅ Progress tracking
10. ✅ Forum updates (minor)

### Phase 4: Polish (Week 6)
11. ✅ Email notifications (backend)
12. ✅ Real-time notifications
13. ✅ Deadline calendar
14. ✅ Advanced progress charts

---

## 🔄 REUSE CHECKLIST

### ✅ Components to Reuse:

| Component | Reuse % | Changes Needed |
|-----------|---------|----------------|
| **Authentication** | 90% | Add role detection |
| **Profile Page** | 100% | No changes |
| **Course Card** | 80% | Add progress indicator |
| **Announcement List** | 100% | Filter by scope |
| **Material List** | 100% | No changes |
| **Assignment List** | 70% | Add submission status |
| **Quiz List** | 70% | Add completion status |
| **Forum** | 95% | Remove instructor badge |
| **Chat** | 100% | No changes |
| **File Upload Widget** | 100% | Reuse for submissions |

### 🆕 New Components:

- Dashboard widgets (charts, progress bars)
- Quiz taking interface
- Assignment submission form
- Notification center
- Grade table view
- Feedback dialog

---

## 🗂️ FILE STRUCTURE (New Files Only)

```
lib/app/
├── data/
│   ├── models/
│   │   ├── request/
│   │   │   ├── submit_assignment_request.dart (NEW)
│   │   │   ├── submit_quiz_request.dart (NEW)
│   │   │   └── mark_notification_read_request.dart (NEW)
│   │   └── response/
│   │       ├── enrolled_course_response.dart (NEW)
│   │       ├── submission_response.dart (NEW)
│   │       ├── grade_response.dart (NEW)
│   │       ├── notification_response.dart (NEW)
│   │       └── progress_response.dart (NEW)
│   ├── services/
│   │   ├── student_api_service.dart (NEW)
│   │   └── notification_service.dart (NEW)
│   └── repositories/
│       ├── submission_repository.dart (NEW)
│       ├── grade_repository.dart (NEW)
│       └── notification_repository.dart (NEW)
├── modules/
│   └── student/ (NEW)
│       ├── home/
│       │   ├── controllers/
│       │   │   └── student_home_controller.dart
│       │   ├── views/
│       │   │   └── student_home_page.dart
│       │   └── bindings/
│       ├── dashboard/
│       │   ├── controllers/
│       │   │   └── dashboard_controller.dart
│       │   └── views/
│       │       └── dashboard_page.dart
│       ├── submissions/
│       │   ├── controllers/
│       │   │   ├── submit_assignment_controller.dart
│       │   │   └── take_quiz_controller.dart
│       │   └── views/
│       │       ├── submit_assignment_page.dart
│       │       └── take_quiz_page.dart
│       ├── grades/
│       │   ├── controllers/
│       │   │   └── grades_controller.dart
│       │   └── views/
│       │       └── grades_page.dart
│       └── notifications/
│           ├── controllers/
│           │   └── notifications_controller.dart
│           └── views/
│               └── notifications_page.dart
└── routes/
    └── student_routes.dart (NEW)
```

---

## 🔐 ROLE-BASED ACCESS CONTROL

### Route Protection Example:

```dart
// middleware/role_middleware.dart (NEW)
class RoleMiddleware extends GetMiddleware {
  final List<String> allowedRoles;
  
  RoleMiddleware(this.allowedRoles);
  
  @override
  RouteSettings? redirect(String? route) {
    final userRole = Get.find<AuthService>().currentUserRole;
    
    if (!allowedRoles.contains(userRole)) {
      return RouteSettings(name: '/unauthorized');
    }
    
    return null;
  }
}

// routes/app_pages.dart
GetPage(
  name: '/student/home',
  page: () => StudentHomePage(),
  middlewares: [RoleMiddleware(['student'])],
  binding: StudentHomeBinding(),
),

GetPage(
  name: '/instructor/dashboard',
  page: () => InstructorDashboardPage(),
  middlewares: [RoleMiddleware(['instructor'])],
  binding: InstructorDashboardBinding(),
),
```

---

Đây là plan đầy đủ cho Student features. Có khoảng **70% reuse** code từ instructor, **30% new features**. 

Bạn muốn tôi detail phần nào trước? 
1. Role detection system?
2. Submit assignment flow?
3. Take quiz flow?
4. Notification system?
5. Personal dashboard?