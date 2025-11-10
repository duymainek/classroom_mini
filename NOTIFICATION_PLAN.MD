# NOTIFICATION SYSTEM - IMPLEMENTATION PLAN

## 🎯 CHIẾN LƯỢC

**Approach: Database-Driven Notifications với Supabase Triggers**

```
Event xảy ra (Assignment created, Quiz graded, etc.)
    ↓
Supabase Trigger tự động fired
    ↓
PL/pgSQL Function tạo notification records
    ↓
Insert vào bảng notifications
    ↓
Frontend polling/realtime để hiển thị
```

---

## 📊 REVIEW BẢNG NOTIFICATIONS

### Bảng hiện tại: `notifications`

**Đã có:**
- ✅ `user_id` - FK to users
- ✅ `type` - announcement, deadline, grade, feedback, submission, quiz, material, general
- ✅ `title`, `body` - Nội dung
- ✅ `data` (jsonb) - Metadata
- ✅ `is_read`, `read_at` - Read status
- ✅ Timestamps

**Cần thêm (optional):**
- `action_url` (text) - Deep link to resource
- `priority` (varchar) - low, medium, high
- `category` (varchar) - academic, social, system

---

## 🔔 NOTIFICATION EVENTS MAP

| Event | Trigger Table | Recipients | Type | Title Template |
|-------|---------------|------------|------|----------------|
| **Assignment created** | `assignment_groups` (INSERT) | Students in groups | `assignment` | "New assignment: {title}" |
| **Quiz created** | `quiz_groups` (INSERT) | Students in groups | `quiz` | "New quiz: {title}" |
| **Announcement created** | `announcement_groups` (INSERT) | Students in groups | `announcement` | "New announcement: {title}" |
| **Assignment graded** | `assignment_submissions` (UPDATE grade) | Student (owner) | `grade` | "Assignment graded: {title}" |
| **Quiz graded** | `quiz_submissions` (UPDATE grade) | Student (owner) | `grade` | "Quiz graded: {title}" |
| **Forum reply** | `forum_replies` (INSERT) | Topic author | `general` | "{user} replied to your topic" |
| **Material uploaded** | `materials` (INSERT) | All students in course | `material` | "New material: {title}" |
| **Deadline approaching** | CRON job (not trigger) | Students with pending work | `deadline` | "Deadline in 24h: {title}" |

---

## 🛠️ DATABASE IMPLEMENTATION

### Step 1: Helper Functions

**`functions/01_get_students_in_groups.sql`:**

```sql
-- =====================================================
-- HELPER: Get all student IDs from group IDs
-- =====================================================
CREATE OR REPLACE FUNCTION get_students_in_groups(group_ids UUID[])
RETURNS TABLE(student_id UUID) AS $$
BEGIN
  /**
   * Purpose: Given array of group IDs, return all student IDs enrolled
   * 
   * Logic:
   * 1. Query student_enrollments WHERE group_id IN group_ids
   * 2. Filter by is_active = true
   * 3. Return distinct student_id list
   * 
   * Used by: All notification triggers that target students by groups
   */
  
  RETURN QUERY
  SELECT DISTINCT se.student_id
  FROM student_enrollments se
  WHERE se.group_id = ANY(group_ids)
    AND se.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;
```

**`functions/02_create_notification.sql`:**

```sql
-- =====================================================
-- HELPER: Create notification for a user
-- =====================================================
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type VARCHAR,
  p_title VARCHAR,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  /**
   * Purpose: Create a notification record
   * 
   * Parameters:
   * - p_user_id: Recipient user ID
   * - p_type: Notification type (announcement, grade, etc)
   * - p_title: Notification title
   * - p_body: Notification body
   * - p_data: Additional JSON data (resource_id, resource_type, etc)
   * 
   * Returns: ID of created notification
   * 
   * Logic:
   * 1. Insert into notifications table
   * 2. Return generated ID
   * 
   * Used by: All trigger functions
   */
  
  INSERT INTO notifications (user_id, type, title, body, data)
  VALUES (p_user_id, p_type, p_title, p_body, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;
```

---

### Step 2: Trigger Functions

#### 2.1 Assignment Notifications

**`functions/03_notify_assignment_created.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when assignment created
-- =====================================================
CREATE OR REPLACE FUNCTION notify_assignment_created()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id UUID;
  v_group_ids UUID[];
  v_assignment assignments%ROWTYPE;
BEGIN
  /**
   * Trigger: AFTER INSERT ON assignment_groups
   * Purpose: Create notifications when assignment assigned to groups
   * 
   * Logic:
   * 1. Collect all group_ids for this assignment (may be multiple inserts)
   * 2. Get assignment details (title, due_date, etc)
   * 3. Get all student_ids from those groups
   * 4. For each student:
   *    - Create notification with type 'assignment'
   *    - Include assignment_id, title, due_date in data
   * 
   * Note: Use AFTER INSERT trigger on assignment_groups (not assignments)
   * because we need group assignments to be complete first
   */
  
  -- Get assignment details
  SELECT * INTO v_assignment
  FROM assignments
  WHERE id = NEW.assignment_id;
  
  -- Get all groups for this assignment
  SELECT array_agg(group_id) INTO v_group_ids
  FROM assignment_groups
  WHERE assignment_id = NEW.assignment_id;
  
  -- Get students in these groups
  FOR v_student_id IN 
    SELECT student_id FROM get_students_in_groups(v_group_ids)
  LOOP
    PERFORM create_notification(
      v_student_id,
      'assignment',
      'New assignment: ' || v_assignment.title,
      'You have a new assignment due on ' || to_char(v_assignment.due_date, 'DD Mon YYYY'),
      jsonb_build_object(
        'assignment_id', v_assignment.id,
        'course_id', v_assignment.course_id,
        'due_date', v_assignment.due_date,
        'action_url', '/student/assignments/' || v_assignment.id
      )
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_notify_assignment_created
AFTER INSERT ON assignment_groups
FOR EACH ROW
EXECUTE FUNCTION notify_assignment_created();
```

#### 2.2 Quiz Notifications

**`functions/04_notify_quiz_created.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when quiz created
-- =====================================================
CREATE OR REPLACE FUNCTION notify_quiz_created()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id UUID;
  v_group_ids UUID[];
  v_quiz quizzes%ROWTYPE;
BEGIN
  /**
   * Similar to assignment notification
   * 
   * Trigger: AFTER INSERT ON quiz_groups
   * 
   * Logic:
   * 1. Get quiz details (title, start_date, due_date, time_limit)
   * 2. Get all groups for this quiz
   * 3. Get all students in groups
   * 4. Create notifications with type 'quiz'
   */
  
  SELECT * INTO v_quiz FROM quizzes WHERE id = NEW.quiz_id;
  
  SELECT array_agg(group_id) INTO v_group_ids
  FROM quiz_groups WHERE quiz_id = NEW.quiz_id;
  
  FOR v_student_id IN 
    SELECT student_id FROM get_students_in_groups(v_group_ids)
  LOOP
    PERFORM create_notification(
      v_student_id,
      'quiz',
      'New quiz: ' || v_quiz.title,
      'Quiz opens on ' || to_char(v_quiz.start_date, 'DD Mon YYYY HH24:MI'),
      jsonb_build_object(
        'quiz_id', v_quiz.id,
        'course_id', v_quiz.course_id,
        'start_date', v_quiz.start_date,
        'due_date', v_quiz.due_date,
        'time_limit', v_quiz.time_limit,
        'action_url', '/student/quizzes/' || v_quiz.id
      )
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_quiz_created
AFTER INSERT ON quiz_groups
FOR EACH ROW
EXECUTE FUNCTION notify_quiz_created();
```

#### 2.3 Announcement Notifications

**`functions/05_notify_announcement_created.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when announcement created
-- =====================================================
CREATE OR REPLACE FUNCTION notify_announcement_created()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id UUID;
  v_group_ids UUID[];
  v_announcement announcements%ROWTYPE;
BEGIN
  /**
   * Trigger: AFTER INSERT ON announcement_groups
   * 
   * Logic:
   * 1. Get announcement details (title, content preview)
   * 2. Get all groups for this announcement
   * 3. Get all students in groups
   * 4. Create notifications with type 'announcement'
   */
  
  SELECT * INTO v_announcement FROM announcements WHERE id = NEW.announcement_id;
  
  SELECT array_agg(group_id) INTO v_group_ids
  FROM announcement_groups WHERE announcement_id = NEW.announcement_id;
  
  FOR v_student_id IN 
    SELECT student_id FROM get_students_in_groups(v_group_ids)
  LOOP
    PERFORM create_notification(
      v_student_id,
      'announcement',
      'New announcement: ' || v_announcement.title,
      substring(v_announcement.content, 1, 100) || '...',
      jsonb_build_object(
        'announcement_id', v_announcement.id,
        'course_id', v_announcement.course_id,
        'action_url', '/student/announcements/' || v_announcement.id
      )
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_announcement_created
AFTER INSERT ON announcement_groups
FOR EACH ROW
EXECUTE FUNCTION notify_announcement_created();
```

#### 2.4 Assignment Graded Notification

**`functions/06_notify_assignment_graded.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when assignment graded
-- =====================================================
CREATE OR REPLACE FUNCTION notify_assignment_graded()
RETURNS TRIGGER AS $$
DECLARE
  v_assignment assignments%ROWTYPE;
BEGIN
  /**
   * Trigger: AFTER UPDATE ON assignment_submissions
   * Condition: WHEN (NEW.grade IS NOT NULL AND OLD.grade IS NULL)
   * 
   * Logic:
   * 1. Check if grade was just added (OLD.grade IS NULL AND NEW.grade IS NOT NULL)
   * 2. Get assignment details
   * 3. Create notification for student with type 'grade'
   * 4. Include grade, feedback in data
   */
  
  -- Only notify if grade was just added
  IF OLD.grade IS NULL AND NEW.grade IS NOT NULL THEN
    SELECT * INTO v_assignment FROM assignments WHERE id = NEW.assignment_id;
    
    PERFORM create_notification(
      NEW.student_id,
      'grade',
      'Assignment graded: ' || v_assignment.title,
      'Your assignment has been graded. Score: ' || NEW.grade || '/100',
      jsonb_build_object(
        'submission_id', NEW.id,
        'assignment_id', v_assignment.id,
        'grade', NEW.grade,
        'feedback', NEW.feedback,
        'graded_at', NEW.graded_at,
        'action_url', '/student/assignments/' || v_assignment.id || '/submissions/' || NEW.id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_assignment_graded
AFTER UPDATE ON assignment_submissions
FOR EACH ROW
WHEN (NEW.grade IS NOT NULL AND OLD.grade IS NULL)
EXECUTE FUNCTION notify_assignment_graded();
```

#### 2.5 Quiz Graded Notification

**`functions/07_notify_quiz_graded.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when quiz graded
-- =====================================================
CREATE OR REPLACE FUNCTION notify_quiz_graded()
RETURNS TRIGGER AS $$
DECLARE
  v_quiz quizzes%ROWTYPE;
BEGIN
  /**
   * Similar to assignment graded
   * 
   * Trigger: AFTER UPDATE ON quiz_submissions
   * Condition: WHEN (NEW.is_graded = TRUE AND OLD.is_graded = FALSE)
   */
  
  IF OLD.is_graded = FALSE AND NEW.is_graded = TRUE THEN
    SELECT * INTO v_quiz FROM quizzes WHERE id = NEW.quiz_id;
    
    PERFORM create_notification(
      NEW.student_id,
      'grade',
      'Quiz graded: ' || v_quiz.title,
      'Your quiz has been graded. Score: ' || NEW.grade || '/100',
      jsonb_build_object(
        'submission_id', NEW.id,
        'quiz_id', v_quiz.id,
        'total_score', NEW.total_score,
        'max_score', NEW.max_score,
        'grade', NEW.grade,
        'action_url', '/student/quizzes/' || v_quiz.id || '/submissions/' || NEW.id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_quiz_graded
AFTER UPDATE ON quiz_submissions
FOR EACH ROW
WHEN (NEW.is_graded = TRUE AND OLD.is_graded = FALSE)
EXECUTE FUNCTION notify_quiz_graded();
```

#### 2.6 Forum Reply Notification

**`functions/08_notify_forum_reply.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when someone replies to your topic
-- =====================================================
CREATE OR REPLACE FUNCTION notify_forum_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_topic forum_topics%ROWTYPE;
  v_reply_author users%ROWTYPE;
BEGIN
  /**
   * Trigger: AFTER INSERT ON forum_replies
   * 
   * Logic:
   * 1. Get topic details and topic author
   * 2. Get reply author details
   * 3. If reply author != topic author:
   *    - Create notification for topic author
   *    - Type: 'general' or create new type 'forum'
   * 4. Include topic_id, reply_id in data
   */
  
  SELECT * INTO v_topic FROM forum_topics WHERE id = NEW.topic_id;
  SELECT * INTO v_reply_author FROM users WHERE id = NEW.user_id;
  
  -- Don't notify if replying to own topic
  IF NEW.user_id != v_topic.user_id THEN
    PERFORM create_notification(
      v_topic.user_id,
      'general',
      v_reply_author.full_name || ' replied to your topic',
      '"' || v_topic.title || '" - ' || substring(NEW.content, 1, 50) || '...',
      jsonb_build_object(
        'topic_id', v_topic.id,
        'reply_id', NEW.id,
        'reply_author_id', NEW.user_id,
        'reply_author_name', v_reply_author.full_name,
        'action_url', '/forum/topics/' || v_topic.id || '#reply-' || NEW.id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_forum_reply
AFTER INSERT ON forum_replies
FOR EACH ROW
EXECUTE FUNCTION notify_forum_reply();
```

#### 2.7 Material Uploaded Notification

**`functions/09_notify_material_uploaded.sql`:**

```sql
-- =====================================================
-- TRIGGER FUNCTION: Notify when material uploaded
-- =====================================================
CREATE OR REPLACE FUNCTION notify_material_uploaded()
RETURNS TRIGGER AS $$
DECLARE
  v_student_id UUID;
  v_group_ids UUID[];
BEGIN
  /**
   * Trigger: AFTER INSERT ON materials
   * 
   * Logic:
   * 1. Get all groups for this course
   * 2. Get all students in these groups
   * 3. Create notifications for all students
   * 
   * Note: Materials are visible to ALL students in course
   */
  
  -- Get all groups for this course
  SELECT array_agg(id) INTO v_group_ids
  FROM groups
  WHERE course_id = NEW.course_id AND is_active = TRUE;
  
  -- Get students in these groups
  FOR v_student_id IN 
    SELECT student_id FROM get_students_in_groups(v_group_ids)
  LOOP
    PERFORM create_notification(
      v_student_id,
      'material',
      'New material: ' || NEW.title,
      COALESCE(NEW.description, 'A new learning material has been uploaded'),
      jsonb_build_object(
        'material_id', NEW.id,
        'course_id', NEW.course_id,
        'action_url', '/student/materials/' || NEW.id
      )
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_material_uploaded
AFTER INSERT ON materials
FOR EACH ROW
EXECUTE FUNCTION notify_material_uploaded();
```

---

## 🔧 BACKEND APIs

### Notification Controller

**`controllers/notificationController.js`:**

```javascript
/**
 * Notification Controller
 * Handles student notifications
 */
class NotificationController {
  
  /**
   * Get notifications for current user
   * GET /api/student/notifications
   * Query: ?limit=20&offset=0&unread_only=false
   */
  getNotifications = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Get user_id from req.user.id
     * 2. Query notifications:
     *    - WHERE user_id = userId
     *    - If unread_only = true: AND is_read = false
     *    - ORDER BY created_at DESC
     *    - LIMIT and OFFSET for pagination
     * 3. Return notifications array with pagination info
     */
  });

  /**
   * Get unread count
   * GET /api/student/notifications/unread-count
   */
  getUnreadCount = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Get user_id from req.user.id
     * 2. Count notifications WHERE user_id = userId AND is_read = false
     * 3. Return { unreadCount: number }
     */
  });

  /**
   * Mark notification as read
   * PUT /api/student/notifications/:id/read
   */
  markAsRead = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Verify notification belongs to current user
     * 2. UPDATE notifications SET is_read = true, read_at = now()
     * 3. Return success
     */
  });

  /**
   * Mark all notifications as read
   * PUT /api/student/notifications/read-all
   */
  markAllAsRead = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. UPDATE all unread notifications for current user
     * 2. Return success with count
     */
  });

  /**
   * Delete notification
   * DELETE /api/student/notifications/:id
   */
  deleteNotification = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Verify ownership
     * 2. DELETE from notifications
     * 3. Return success
     */
  });

  /**
   * Delete all read notifications
   * DELETE /api/student/notifications/read
   */
  deleteAllRead = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. DELETE WHERE user_id = userId AND is_read = true
     * 2. Return success with count
     */
  });
}
```

**Routes:**

```javascript
// routes/notificationRoutes.js
router.get('/notifications', notificationController.getNotifications);
router.get('/notifications/unread-count', notificationController.getUnreadCount);
router.put('/notifications/:id/read', notificationController.markAsRead);
router.put('/notifications/read-all', notificationController.markAllAsRead);
router.delete('/notifications/:id', notificationController.deleteNotification);
router.delete('/notifications/read', notificationController.deleteAllRead);
```

---

## 📱 FRONTEND (Flutter)

### Models

```dart
/**
 * models/response/notification_response.dart
 * 
 * Fields:
 * - id, userId, type, title, body
 * - data (Map<String, dynamic>)
 * - isRead, readAt
 * - createdAt
 * 
 * Helpers:
 * - String get typeIcon (return icon based on type)
 * - Color get typeColor (return color based on type)
 * - String get actionUrl (extract from data)
 */
```

### Service

```dart
/**
 * services/notification_service.dart
 * 
 * Methods:
 * - Future<List<Notification>> getNotifications()
 * - Future<int> getUnreadCount()
 * - Future<void> markAsRead(String id)
 * - Future<void> markAllAsRead()
 * - Future<void> deleteNotification(String id)
 * 
 * Polling:
 * - Timer.periodic(Duration(minutes: 1), checkNewNotifications)
 * - Update badge count when new notifications arrive
 */
```

### Controller

```dart
/**
 * modules/notifications/controllers/notifications_controller.dart
 * 
 * State:
 * - notifications (RxList<Notification>)
 * - unreadCount (RxInt)
 * - isLoading (RxBool)
 * 
 * Methods:
 * - loadNotifications()
 * - refreshNotifications() (pull-to-refresh)
 * - markAsRead(String id)
 * - markAllAsRead()
 * - deleteNotification(String id)
 * - handleNotificationTap(Notification notification)
 *   → Navigate to action_url
 * 
 * Lifecycle:
 * - onInit: Load notifications + start polling
 * - onClose: Stop polling timer
 */
```

### UI

```dart
/**
 * modules/notifications/views/notifications_page.dart
 * 
 * Layout:
 * 
 * AppBar:
 *   - Title: "Notifications"
 *   - Actions: Mark all as read button
 * 
 * Body:
 *   - RefreshIndicator (pull-to-refresh)
 *   - ListView.builder:
 *     - Each item: NotificationCard
 *       - Icon (based on type)
 *       - Title
 *       - Body (truncated)
 *       - Timestamp
 *       - Unread indicator (blue dot)
 *       - Swipe to delete
 *     - Tap: Mark as read + navigate to resource
 * 
 * Empty state: "No notifications"
 * 
 * Tabs (optional):
 *   - All
 *   - Unread
 *   - Assignments
 *   - Grades
 */
```

### Notification Badge

```dart
/**
 * widgets/notification_bell.dart
 * 
 * Display bell icon with badge count in AppBar
 * 
 * Features:
 * - Icon: Icons.notifications
 * - Badge: Show unread count (if > 0)
 * - Tap: Navigate to notifications page
 * - Auto-update badge when count changes
 */
```

---

## ⏰ DEADLINE NOTIFICATIONS (CRON Job)

### Backend Scheduled Task

```javascript
/**
 * services/deadlineNotificationService.js
 * 
 * Run every hour (or use pg_cron extension)
 * 
 * Logic:
 * 1. Find all assignments/quizzes with:
 *    - due_date between NOW and NOW + 24 hours
 *    - Student has NOT submitted yet
 * 
 * 2. For each pending assignment/quiz:
 *    - Get student_id
 *    - Create notification with type 'deadline'
 *    - Title: "Deadline approaching: {title}"
 *    - Body: "Due in {hours} hours"
 * 
 * 3. Prevent duplicate notifications:
 *    - Check if notification already sent (by checking existing notifications)
 *    - Use data.resource_id to dedupe
 */
```

**Alternative: Use Supabase pg_cron:**

```sql
-- Schedule deadline check every hour
SELECT cron.schedule(
  'check-deadlines',
  '0 * * * *', -- Every hour
  $$
  INSERT INTO notifications (user_id, type, title, body, data)
  SELECT 
    se.student_id,
    'deadline',
    'Deadline approaching: ' || a.title,
    'Due in ' || EXTRACT(HOUR FROM (a.due_date - NOW())) || ' hours',
    jsonb_build_object('assignment_id', a.id, 'due_date', a.due_date)
  FROM assignments a
  JOIN assignment_groups ag ON ag.assignment_id = a.id
  JOIN student_enrollments se ON se.group_id = ag.group_id
  WHERE a.due_date BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
    AND NOT EXISTS (
      SELECT 1 FROM assignment_submissions asub
      WHERE asub.assignment_id = a.id AND asub.student_id = se.student_id
    )
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.user_id = se.student_id
        AND n.type = 'deadline'
        AND n.data->>'assignment_id' = a.id::text
        AND n.created_at > NOW() - INTERVAL '23 hours'
    );
  $$
);
```

---

## 📊 NOTIFICATION TYPES SUMMARY

| Type | Event | Trigger Table | Recipients |
|------|-------|---------------|------------|
| `assignment` | New assignment | `assignment_groups` INSERT | Students in groups |
| `quiz` | New quiz | `quiz_groups` INSERT | Students in groups |
| `announcement` | New announcement | `announcement_groups` INSERT | Students in groups |
| `grade` | Assignment graded | `assignment_submissions` UPDATE | Student (owner) |
| `grade` | Quiz graded | `quiz_submissions` UPDATE | Student (owner) |
| `general` | Forum reply | `forum_replies` INSERT | Topic author |
| `material` | Material uploaded | `materials` INSERT | All students in course |
| `deadline` | Deadline approaching | CRON job | Students with pending work |

---

## ✅ IMPLEMENTATION CHECKLIST

### Database:
- [ ] Create helper functions (get_students_in_groups, create_notification)
- [ ] Create trigger function for assignment notifications
- [ ] Create trigger function for quiz notifications
- [ ] Create trigger function for announcement notifications
- [ ] Create trigger function for assignment graded
- [ ] Create trigger function for quiz graded
- [ ] Create trigger function for forum reply
- [ ] Create trigger function for material uploaded
- [ ] Setup CRON job for deadline notifications (optional)
- [ ] Test all triggers with sample data

### Backend:
- [ ] Implement NotificationController
- [ ] Setup routes
- [ ] Test APIs with Postman
- [ ] Add indexes on notifications table (user_id, is_read, created_at)

### Frontend:
- [ ] Create notification models
- [ ] Create notification service with polling
- [ ] Create notifications page
- [ ] Create notification bell widget
- [ ] Implement navigation to resources (deep linking)
- [ ] Test notification flow end-to-end

### Testing:
- [ ] Create assignment → Check student receives notification
- [ ] Grade assignment → Check student receives grade notification
- [ ] Reply to forum → Check topic author receives notification
- [ ] Mark notification as read → Check UI updates
- [ ] Delete notification → Check removed from list

---

## 🔔 NOTIFICATION EXAMPLES

**Assignment Created:**
```json
{
  "type": "assignment",
  "title": "New assignment: Build REST API",
  "body": "You have a new assignment due on 15 Dec 2024",
  "data": {
    "assignment_id": "uuid",
    "course_id": "uuid",
    "due_date": "2024-12-15T23:59:59Z",
    "action_url": "/student/assignments/uuid"
  }
}
```

**Assignment Graded:**
```json
{
  "type": "grade",
  "title": "Assignment graded: Build REST API",
  "body": "Your assignment has been graded. Score: 85/100",
  "data": {
    "assignment_id": "uuid",
    "submission_id": "uuid",
    "grade": 85,
    "feedback": "Good work!",
    "action_url": "/student/assignments/uuid/submissions/uuid"
  }
}
```

**Forum Reply:**
```json
{
  "type": "general",
  "title": "John Doe replied to your topic",
  "body": "\"How to deploy Docker?\" - I suggest using docker-compose...",
  "data": {
    "topic_id": "uuid",
    "reply_id": "uuid",
    "reply_author_id": "uuid",
    "action_url": "/forum/topics/uuid#reply-uuid"
  }
}
```

---

Đây là plan đầy đủ với database triggers tự động tạo notifications. Approach này giúp:
- ✅ Real-time notifications (trigger fired ngay)
- ✅ Không cần polling backend
- ✅ Consistent (không miss events)
- ✅ Scalable (database handle logic)

Bạn có muốn tôi detail phần nào không? 🚀