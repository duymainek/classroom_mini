# 📊 Database Schema - Chi tiết các bảng liên quan đến Student, Instructor và các luồng

## 📋 Mục lục

1. [Bảng người dùng (Users)](#1-bảng-người-dùng-users)
2. [Assignment (Bài tập)](#2-assignment-bài-tập)
3. [Quiz (Kiểm tra)](#3-quiz-kiểm-tra)
4. [Forum (Diễn đàn)](#4-forum-diễn-đàn)
5. [Chat (Tin nhắn)](#5-chat-tin-nhắn)
6. [Announcements (Thông báo)](#6-announcements-thông-báo)
7. [Materials (Tài liệu)](#7-materials-tài-liệu)
8. [Các bảng hỗ trợ](#8-các-bảng-hỗ-trợ)

---

## 1. Bảng người dùng (Users)

### 1.1. `users` - Bảng người dùng chính

**Mô tả**: Lưu trữ thông tin tất cả người dùng (student và instructor)

**Primary Keys**:
- `id` (uuid) - ID duy nhất của người dùng

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY, DEFAULT gen_random_uuid() | ID người dùng |
| `username` | varchar | UNIQUE, NOT NULL | Tên đăng nhập |
| `email` | varchar | UNIQUE, NOT NULL | Email |
| `password_hash` | varchar | NOT NULL | Mật khẩu đã hash |
| `salt` | varchar | NOT NULL | Salt cho password |
| `full_name` | varchar | NOT NULL, CHECK (2-50 ký tự, chỉ chữ) | Họ tên đầy đủ |
| `role` | varchar | NOT NULL, CHECK ('instructor' hoặc 'student') | Vai trò |
| `avatar_url` | text | NULLABLE | URL avatar |
| `is_active` | boolean | DEFAULT true | Trạng thái hoạt động |
| `last_login_at` | timestamp | NULLABLE | Lần đăng nhập cuối |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |
| `current_semester_id` | uuid | NULLABLE, FK → semesters.id | Học kỳ hiện tại |

**Foreign Keys**:
- `current_semester_id` → `semesters.id`

**Relationships**:
- Một user có thể có nhiều: `notifications`, `student_enrollments`, `quizzes` (instructor), `assignments` (instructor), `announcements` (instructor), `materials` (instructor), `forum_topics`, `forum_replies`, `quiz_submissions` (student), `assignment_submissions` (student), `chat_users`

---

### 1.2. `user_sessions` - Phiên đăng nhập

**Mô tả**: Quản lý các phiên đăng nhập của người dùng

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID phiên |
| `user_id` | uuid | FK → users.id | ID người dùng |
| `token_hash` | varchar | NOT NULL | Hash của token |
| `refresh_token_hash` | varchar | NULLABLE | Hash của refresh token |
| `expires_at` | timestamp | NOT NULL | Thời gian hết hạn |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `last_accessed_at` | timestamp | DEFAULT now() | Lần truy cập cuối |
| `device_info` | jsonb | NULLABLE | Thông tin thiết bị |
| `ip_address` | inet | NULLABLE | Địa chỉ IP |
| `is_active` | boolean | DEFAULT true | Trạng thái hoạt động |

**Foreign Keys**:
- `user_id` → `users.id`

---

### 1.3. `student_enrollments` - Đăng ký học của sinh viên

**Mô tả**: Quản lý việc đăng ký học của sinh viên vào các nhóm

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID đăng ký |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `group_id` | uuid | FK → groups.id | ID nhóm |
| `semester_id` | uuid | FK → semesters.id | ID học kỳ |
| `enrolled_at` | timestamp | DEFAULT now() | Ngày đăng ký |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `student_id` → `users.id`
- `group_id` → `groups.id`
- `semester_id` → `semesters.id`

---

## 2. Assignment (Bài tập)

### 2.1. `assignments` - Bài tập

**Mô tả**: Lưu trữ thông tin các bài tập

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID bài tập |
| `title` | varchar | NOT NULL, CHECK (2-255 ký tự) | Tiêu đề |
| `description` | text | NULLABLE | Mô tả |
| `course_id` | uuid | FK → courses.id | ID khóa học |
| `instructor_id` | uuid | FK → users.id | ID giảng viên |
| `start_date` | timestamp | NOT NULL | Ngày bắt đầu |
| `due_date` | timestamp | NOT NULL | Hạn nộp |
| `late_due_date` | timestamp | NULLABLE | Hạn nộp muộn |
| `allow_late_submission` | boolean | DEFAULT false | Cho phép nộp muộn |
| `max_attempts` | integer | DEFAULT 1, CHECK (> 0) | Số lần nộp tối đa |
| `file_formats` | text[] | DEFAULT '{}' | Định dạng file cho phép |
| `max_file_size` | integer | DEFAULT 10 | Kích thước file tối đa (MB) |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `course_id` → `courses.id`
- `instructor_id` → `users.id`

**Relationships**:
- Một assignment có nhiều: `assignment_submissions`, `assignment_attachments`, `assignment_groups`

---

### 2.2. `assignment_attachments` - File đính kèm bài tập

**Mô tả**: File đính kèm của bài tập (file mẫu, hướng dẫn)

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `assignment_id` | uuid | FK → assignments.id | ID bài tập |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | integer | NULLABLE | Kích thước (bytes) |
| `file_type` | varchar | NULLABLE | Loại file |
| `file_path` | text | NULLABLE | Đường dẫn lưu trữ |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `assignment_id` → `assignments.id`

---

### 2.3. `assignment_groups` - Phân nhóm bài tập

**Mô tả**: Liên kết bài tập với các nhóm được giao

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID liên kết |
| `assignment_id` | uuid | FK → assignments.id | ID bài tập |
| `group_id` | uuid | FK → groups.id | ID nhóm |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `assignment_id` → `assignments.id`
- `group_id` → `groups.id`

---

### 2.4. `assignment_submissions` - Bài nộp của sinh viên

**Mô tả**: Lưu trữ bài nộp của sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID bài nộp |
| `assignment_id` | uuid | FK → assignments.id | ID bài tập |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `attempt_number` | integer | NOT NULL, CHECK (> 0) | Số lần nộp |
| `submission_text` | text | NULLABLE | Nội dung text |
| `submitted_at` | timestamp | DEFAULT now() | Thời gian nộp |
| `is_late` | boolean | DEFAULT false | Nộp muộn |
| `grade` | numeric | NULLABLE, CHECK (0-100) | Điểm số |
| `feedback` | text | NULLABLE | Nhận xét |
| `graded_at` | timestamp | NULLABLE | Thời gian chấm |
| `graded_by` | uuid | NULLABLE, FK → users.id | ID người chấm |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `assignment_id` → `assignments.id`
- `student_id` → `users.id`
- `graded_by` → `users.id`

**Relationships**:
- Một submission có nhiều: `submission_attachments`

---

### 2.5. `submission_attachments` - File đính kèm bài nộp

**Mô tả**: File đính kèm trong bài nộp của sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `submission_id` | uuid | FK → assignment_submissions.id | ID bài nộp |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | integer | NULLABLE | Kích thước (bytes) |
| `file_type` | varchar | NULLABLE | Loại file |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `submission_id` → `assignment_submissions.id`

---

## 3. Quiz (Kiểm tra)

### 3.1. `quizzes` - Bài kiểm tra

**Mô tả**: Lưu trữ thông tin các bài kiểm tra

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID bài kiểm tra |
| `title` | varchar | NOT NULL, CHECK (2-255 ký tự) | Tiêu đề |
| `description` | text | NULLABLE | Mô tả |
| `course_id` | uuid | FK → courses.id | ID khóa học |
| `instructor_id` | uuid | FK → users.id | ID giảng viên |
| `start_date` | timestamp | NOT NULL | Ngày bắt đầu |
| `due_date` | timestamp | NOT NULL | Hạn nộp |
| `late_due_date` | timestamp | NULLABLE | Hạn nộp muộn |
| `allow_late_submission` | boolean | DEFAULT false | Cho phép nộp muộn |
| `max_attempts` | integer | DEFAULT 1, CHECK (> 0) | Số lần làm tối đa |
| `time_limit` | integer | NULLABLE | Thời gian làm bài (phút) |
| `shuffle_questions` | boolean | DEFAULT false | Xáo trộn câu hỏi |
| `shuffle_options` | boolean | DEFAULT false | Xáo trộn đáp án |
| `show_correct_answers` | boolean | DEFAULT false | Hiển thị đáp án đúng |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `course_id` → `courses.id`
- `instructor_id` → `users.id`

**Relationships**:
- Một quiz có nhiều: `quiz_questions`, `quiz_submissions`, `quiz_groups`

---

### 3.2. `quiz_questions` - Câu hỏi trong bài kiểm tra

**Mô tả**: Lưu trữ các câu hỏi trong bài kiểm tra

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID câu hỏi |
| `quiz_id` | uuid | FK → quizzes.id | ID bài kiểm tra |
| `question_text` | text | NOT NULL | Nội dung câu hỏi |
| `question_type` | varchar | NOT NULL, CHECK ('multiple_choice', 'true_false', 'essay') | Loại câu hỏi |
| `points` | integer | DEFAULT 1, CHECK (> 0) | Điểm số |
| `order_index` | integer | NOT NULL, CHECK (> 0) | Thứ tự |
| `is_required` | boolean | DEFAULT true | Bắt buộc |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `quiz_id` → `quizzes.id`

**Relationships**:
- Một question có nhiều: `quiz_question_options`, `quiz_answers`

---

### 3.3. `quiz_question_options` - Lựa chọn đáp án

**Mô tả**: Các lựa chọn đáp án cho câu hỏi trắc nghiệm

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lựa chọn |
| `question_id` | uuid | FK → quiz_questions.id | ID câu hỏi |
| `option_text` | text | NOT NULL | Nội dung lựa chọn |
| `is_correct` | boolean | DEFAULT false | Đáp án đúng |
| `order_index` | integer | NOT NULL, CHECK (> 0) | Thứ tự |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `question_id` → `quiz_questions.id`

**Relationships**:
- Một option có thể được chọn trong: `quiz_answers`

---

### 3.4. `quiz_groups` - Phân nhóm bài kiểm tra

**Mô tả**: Liên kết bài kiểm tra với các nhóm được giao

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID liên kết |
| `quiz_id` | uuid | FK → quizzes.id | ID bài kiểm tra |
| `group_id` | uuid | FK → groups.id | ID nhóm |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `quiz_id` → `quizzes.id`
- `group_id` → `groups.id`

---

### 3.5. `quiz_submissions` - Bài làm của sinh viên

**Mô tả**: Lưu trữ bài làm kiểm tra của sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID bài làm |
| `quiz_id` | uuid | FK → quizzes.id | ID bài kiểm tra |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `attempt_number` | integer | NOT NULL, CHECK (> 0) | Số lần làm |
| `started_at` | timestamp | DEFAULT now() | Thời gian bắt đầu |
| `submitted_at` | timestamp | NULLABLE | Thời gian nộp |
| `time_spent` | integer | NULLABLE | Thời gian làm (giây) |
| `total_score` | numeric | NULLABLE | Tổng điểm |
| `max_score` | numeric | NULLABLE | Điểm tối đa |
| `is_late` | boolean | DEFAULT false | Nộp muộn |
| `is_graded` | boolean | DEFAULT false | Đã chấm |
| `grade` | numeric | NULLABLE, CHECK (0-100) | Điểm số |
| `feedback` | text | NULLABLE | Nhận xét |
| `graded_at` | timestamp | NULLABLE | Thời gian chấm |
| `graded_by` | uuid | NULLABLE, FK → users.id | ID người chấm |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `quiz_id` → `quizzes.id`
- `student_id` → `users.id`
- `graded_by` → `users.id`

**Relationships**:
- Một submission có nhiều: `quiz_answers`

---

### 3.6. `quiz_answers` - Câu trả lời của sinh viên

**Mô tả**: Lưu trữ câu trả lời của sinh viên cho từng câu hỏi

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID câu trả lời |
| `submission_id` | uuid | FK → quiz_submissions.id | ID bài làm |
| `question_id` | uuid | FK → quiz_questions.id | ID câu hỏi |
| `answer_text` | text | NULLABLE | Câu trả lời dạng text (cho essay) |
| `selected_option_id` | uuid | NULLABLE, FK → quiz_question_options.id | ID lựa chọn đã chọn |
| `is_correct` | boolean | NULLABLE | Đúng/Sai |
| `points_earned` | numeric | DEFAULT 0 | Điểm đạt được |
| `review_status` | varchar | DEFAULT 'pending', CHECK ('pending', 'approved', 'rejected') | Trạng thái chấm (cho essay) |
| `manual_score` | numeric | NULLABLE | Điểm chấm thủ công (cho essay) |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `submission_id` → `quiz_submissions.id`
- `question_id` → `quiz_questions.id`
- `selected_option_id` → `quiz_question_options.id`

---

## 4. Forum (Diễn đàn)

### 4.1. `forum_topics` - Chủ đề diễn đàn

**Mô tả**: Lưu trữ các chủ đề thảo luận trong diễn đàn

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID chủ đề |
| `user_id` | uuid | FK → users.id | ID người tạo |
| `title` | varchar | NOT NULL, CHECK (không rỗng) | Tiêu đề |
| `content` | text | NOT NULL, CHECK (không rỗng) | Nội dung |
| `reply_count` | integer | DEFAULT 0 | Số lượng trả lời |
| `view_count` | integer | DEFAULT 0 | Số lượng lượt xem |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |
| `is_deleted` | boolean | DEFAULT false | Đã xóa |
| `is_pinned` | boolean | DEFAULT false | Ghim |
| `is_locked` | boolean | DEFAULT false | Khóa |

**Foreign Keys**:
- `user_id` → `users.id`

**Relationships**:
- Một topic có nhiều: `forum_replies`, `forum_attachments`, `forum_views`

---

### 4.2. `forum_replies` - Trả lời trong diễn đàn

**Mô tả**: Lưu trữ các câu trả lời trong chủ đề diễn đàn

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID trả lời |
| `topic_id` | uuid | FK → forum_topics.id | ID chủ đề |
| `user_id` | uuid | FK → users.id | ID người trả lời |
| `parent_reply_id` | uuid | NULLABLE, FK → forum_replies.id | ID trả lời cha (reply của reply) |
| `content` | text | NOT NULL, CHECK (<= 500 ký tự) | Nội dung |
| `like_count` | integer | DEFAULT 0 | Số lượt thích |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |
| `is_deleted` | boolean | DEFAULT false | Đã xóa |

**Foreign Keys**:
- `topic_id` → `forum_topics.id`
- `user_id` → `users.id`
- `parent_reply_id` → `forum_replies.id` (self-reference)

**Relationships**:
- Một reply có thể có: `forum_attachments`, `forum_likes`
- Một reply có thể có nhiều reply con (nested replies)

---

### 4.3. `forum_attachments` - File đính kèm diễn đàn

**Mô tả**: File đính kèm trong chủ đề hoặc trả lời diễn đàn

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `topic_id` | uuid | NULLABLE, FK → forum_topics.id | ID chủ đề |
| `reply_id` | uuid | NULLABLE, FK → forum_replies.id | ID trả lời |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | varchar | NOT NULL | Loại file |
| `storage_path` | text | NOT NULL | Đường dẫn lưu trữ |
| `uploaded_at` | timestamptz | DEFAULT now() | Ngày upload |

**Foreign Keys**:
- `topic_id` → `forum_topics.id`
- `reply_id` → `forum_replies.id`

**Lưu ý**: Một attachment phải thuộc về topic HOẶC reply (không thể cả hai)

---

### 4.4. `forum_likes` - Lượt thích trả lời

**Mô tả**: Lưu trữ lượt thích của người dùng cho các trả lời

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt thích |
| `reply_id` | uuid | FK → forum_replies.id | ID trả lời |
| `user_id` | uuid | FK → users.id | ID người thích |
| `created_at` | timestamptz | DEFAULT now() | Ngày thích |

**Foreign Keys**:
- `reply_id` → `forum_replies.id`
- `user_id` → `users.id`

---

### 4.5. `forum_views` - Lượt xem chủ đề

**Mô tả**: Theo dõi lượt xem của người dùng cho các chủ đề

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt xem |
| `topic_id` | uuid | FK → forum_topics.id | ID chủ đề |
| `user_id` | uuid | FK → users.id | ID người xem |
| `view_count` | integer | DEFAULT 1 | Số lần xem |
| `last_viewed_at` | timestamptz | DEFAULT now() | Lần xem cuối |

**Foreign Keys**:
- `topic_id` → `forum_topics.id`
- `user_id` → `users.id`

---

### 4.6. `forum_temp_attachments` - File tạm diễn đàn

**Mô tả**: Lưu trữ file tạm thời trước khi đính kèm vào topic/reply

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file tạm |
| `user_id` | uuid | NOT NULL | ID người dùng |
| `file_name` | text | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | text | NOT NULL | Loại file |
| `storage_path` | text | NOT NULL | Đường dẫn lưu trữ |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |

**Lưu ý**: Bảng này không có foreign key constraint, nhưng `user_id` tham chiếu đến `users.id`

---

## 5. Chat (Tin nhắn)

### 5.1. `chat_users` - Người dùng chat

**Mô tả**: Thông tin người dùng trong hệ thống chat (mở rộng từ users)

**Primary Keys**:
- `id` (uuid) - Trùng với users.id

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY, FK → users.id | ID người dùng |
| `first_name` | text | NULLABLE | Tên |
| `last_name` | text | NULLABLE | Họ |
| `image_url` | text | NULLABLE | URL ảnh đại diện |
| `role` | text | NULLABLE | Vai trò |
| `last_seen` | timestamptz | DEFAULT now() | Lần online cuối |
| `metadata` | jsonb | DEFAULT '{}' | Dữ liệu bổ sung |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `id` → `users.id` (1-1 relationship)

**Relationships**:
- Một chat_user có thể có nhiều: `chat_messages`, `chat_room_members`, `chat_message_read_status`

---

### 5.2. `chat_rooms` - Phòng chat

**Mô tả**: Lưu trữ thông tin các phòng chat (direct, group, channel)

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID phòng |
| `name` | text | NULLABLE | Tên phòng |
| `type` | text | NOT NULL, CHECK ('direct', 'group', 'channel') | Loại phòng |
| `image_url` | text | NULLABLE | Ảnh đại diện phòng |
| `user_ids` | uuid[] | NOT NULL | Danh sách ID thành viên |
| `last_message_id` | uuid | NULLABLE, FK → chat_messages.id | ID tin nhắn cuối |
| `last_message_at` | timestamptz | DEFAULT now() | Thời gian tin nhắn cuối |
| `metadata` | jsonb | DEFAULT '{}' | Dữ liệu bổ sung |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `last_message_id` → `chat_messages.id`

**Relationships**:
- Một room có nhiều: `chat_messages`, `chat_room_members`

---

### 5.3. `chat_messages` - Tin nhắn

**Mô tả**: Lưu trữ các tin nhắn trong phòng chat

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID tin nhắn |
| `room_id` | uuid | FK → chat_rooms.id | ID phòng |
| `author_id` | uuid | FK → chat_users.id | ID người gửi |
| `text` | text | NULLABLE | Nội dung text |
| `type` | text | NOT NULL, CHECK ('text', 'image', 'file', 'custom') | Loại tin nhắn |
| `uri` | text | NULLABLE | URI file (cho image/file) |
| `name` | text | NULLABLE | Tên file |
| `size` | numeric | NULLABLE | Kích thước file |
| `mime_type` | text | NULLABLE | MIME type |
| `width` | numeric | NULLABLE | Chiều rộng (cho image) |
| `height` | numeric | NULLABLE | Chiều cao (cho image) |
| `replied_message_id` | uuid | NULLABLE, FK → chat_messages.id | ID tin nhắn được reply |
| `status` | text | NULLABLE | Trạng thái |
| `preview_data` | jsonb | NULLABLE | Dữ liệu preview |
| `metadata` | jsonb | DEFAULT '{}' | Dữ liệu bổ sung |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `room_id` → `chat_rooms.id`
- `author_id` → `chat_users.id`
- `replied_message_id` → `chat_messages.id` (self-reference)

**Relationships**:
- Một message có thể được reply bởi nhiều message khác
- Một message có nhiều: `chat_message_read_status`

---

### 5.4. `chat_room_members` - Thành viên phòng chat

**Mô tả**: Quản lý thành viên và cài đặt cá nhân trong phòng chat

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID thành viên |
| `room_id` | uuid | FK → chat_rooms.id | ID phòng |
| `user_id` | uuid | FK → chat_users.id | ID người dùng |
| `is_hidden` | boolean | DEFAULT false | Ẩn phòng |
| `is_muted` | boolean | DEFAULT false | Tắt thông báo |
| `is_archived` | boolean | DEFAULT false | Lưu trữ |
| `unread_count` | integer | DEFAULT 0 | Số tin chưa đọc |
| `last_read_message_id` | uuid | NULLABLE, FK → chat_messages.id | ID tin nhắn đọc cuối |
| `last_read_at` | timestamptz | DEFAULT now() | Thời gian đọc cuối |
| `joined_at` | timestamptz | DEFAULT now() | Ngày tham gia |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `room_id` → `chat_rooms.id`
- `user_id` → `chat_users.id`
- `last_read_message_id` → `chat_messages.id`

---

### 5.5. `chat_message_read_status` - Trạng thái đọc tin nhắn

**Mô tả**: Theo dõi trạng thái đọc tin nhắn của từng người dùng

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID trạng thái |
| `message_id` | uuid | FK → chat_messages.id | ID tin nhắn |
| `user_id` | uuid | FK → chat_users.id | ID người dùng |
| `read_at` | timestamptz | DEFAULT now() | Thời gian đọc |

**Foreign Keys**:
- `message_id` → `chat_messages.id`
- `user_id` → `chat_users.id`

---

## 6. Announcements (Thông báo)

### 6.1. `announcements` - Thông báo

**Mô tả**: Lưu trữ các thông báo từ giảng viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID thông báo |
| `course_id` | uuid | FK → courses.id | ID khóa học |
| `instructor_id` | uuid | FK → users.id | ID giảng viên |
| `title` | varchar | NOT NULL, CHECK (2-200 ký tự) | Tiêu đề |
| `content` | text | NOT NULL, CHECK (>= 10 ký tự) | Nội dung |
| `scope_type` | varchar | NOT NULL, CHECK ('one_group', 'multiple_groups', 'all_groups') | Phạm vi |
| `published_at` | timestamptz | DEFAULT now() | Ngày xuất bản |
| `is_deleted` | boolean | DEFAULT false | Đã xóa |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `course_id` → `courses.id`
- `instructor_id` → `users.id`

**Relationships**:
- Một announcement có nhiều: `announcement_groups`, `announcement_files`, `announcement_attachments`, `announcement_comments`, `announcement_views`

---

### 6.2. `announcement_groups` - Phân nhóm thông báo

**Mô tả**: Liên kết thông báo với các nhóm được gửi

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID liên kết |
| `announcement_id` | uuid | FK → announcements.id | ID thông báo |
| `group_id` | uuid | FK → groups.id | ID nhóm |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |

**Foreign Keys**:
- `announcement_id` → `announcements.id`
- `group_id` → `groups.id`

---

### 6.3. `announcement_files` - File đính kèm thông báo

**Mô tả**: File đính kèm trong thông báo

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `announcement_id` | uuid | FK → announcements.id | ID thông báo |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | varchar | NULLABLE | Loại file |
| `uploaded_at` | timestamptz | DEFAULT now() | Ngày upload |

**Foreign Keys**:
- `announcement_id` → `announcements.id`

**Relationships**:
- Một file có nhiều: `announcement_downloads`

---

### 6.4. `announcement_attachments` - File đính kèm thông báo (bảng mới)

**Mô tả**: File đính kèm trong thông báo (có file_path)

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `announcement_id` | uuid | FK → announcements.id | ID thông báo |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | varchar | NOT NULL | Loại file |
| `file_path` | text | NOT NULL | Đường dẫn lưu trữ |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `announcement_id` → `announcements.id`

---

### 6.5. `announcement_comments` - Bình luận thông báo

**Mô tả**: Lưu trữ các bình luận của người dùng trên thông báo

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID bình luận |
| `announcement_id` | uuid | FK → announcements.id | ID thông báo |
| `user_id` | uuid | FK → users.id | ID người bình luận |
| `parent_comment_id` | uuid | NULLABLE, FK → announcement_comments.id | ID bình luận cha |
| `comment_text` | text | NOT NULL, CHECK (1-500 ký tự) | Nội dung bình luận |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `is_deleted` | boolean | DEFAULT false | Đã xóa |

**Foreign Keys**:
- `announcement_id` → `announcements.id`
- `user_id` → `users.id`
- `parent_comment_id` → `announcement_comments.id` (self-reference)

**Relationships**:
- Một comment có thể có nhiều comment con (nested comments)

---

### 6.6. `announcement_views` - Lượt xem thông báo

**Mô tả**: Theo dõi lượt xem thông báo của sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt xem |
| `announcement_id` | uuid | FK → announcements.id | ID thông báo |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `viewed_at` | timestamptz | DEFAULT now() | Thời gian xem |
| `view_count` | integer | DEFAULT 1 | Số lần xem |

**Foreign Keys**:
- `announcement_id` → `announcements.id`
- `student_id` → `users.id`

---

### 6.7. `announcement_downloads` - Lượt tải file thông báo

**Mô tả**: Theo dõi lượt tải file đính kèm thông báo

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt tải |
| `file_id` | uuid | FK → announcement_files.id | ID file |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `downloaded_at` | timestamptz | DEFAULT now() | Thời gian tải |
| `download_count` | integer | DEFAULT 1 | Số lần tải |

**Foreign Keys**:
- `file_id` → `announcement_files.id`
- `student_id` → `users.id`

---

## 7. Materials (Tài liệu)

### 7.1. `materials` - Tài liệu học tập

**Mô tả**: Lưu trữ thông tin các tài liệu học tập

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID tài liệu |
| `course_id` | uuid | FK → courses.id | ID khóa học |
| `instructor_id` | uuid | FK → users.id | ID giảng viên |
| `title` | varchar | NOT NULL, CHECK (2-255 ký tự) | Tiêu đề |
| `description` | text | NULLABLE | Mô tả |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `published_at` | timestamptz | DEFAULT now() | Ngày xuất bản |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `course_id` → `courses.id`
- `instructor_id` → `users.id`

**Relationships**:
- Một material có nhiều: `material_attachments`, `material_views`, `material_downloads`

---

### 7.2. `material_attachments` - File đính kèm tài liệu

**Mô tả**: File đính kèm trong tài liệu học tập

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file |
| `material_id` | uuid | FK → materials.id | ID tài liệu |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_url` | text | NOT NULL | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | varchar | NULLABLE | Loại file |
| `file_path` | text | NULLABLE | Đường dẫn lưu trữ |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `material_id` → `materials.id`

**Relationships**:
- Một attachment có nhiều: `material_downloads`

**RLS**: Enabled (Row Level Security)

---

### 7.3. `material_views` - Lượt xem tài liệu

**Mô tả**: Theo dõi lượt xem tài liệu của sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt xem |
| `material_id` | uuid | FK → materials.id | ID tài liệu |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `viewed_at` | timestamptz | DEFAULT now() | Thời gian xem |
| `view_count` | integer | DEFAULT 1 | Số lần xem |

**Foreign Keys**:
- `material_id` → `materials.id`
- `student_id` → `users.id`

**RLS**: Enabled (Row Level Security)

---

### 7.4. `material_downloads` - Lượt tải tài liệu

**Mô tả**: Theo dõi lượt tải file tài liệu

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID lượt tải |
| `file_id` | uuid | FK → material_attachments.id | ID file |
| `student_id` | uuid | FK → users.id | ID sinh viên |
| `downloaded_at` | timestamptz | DEFAULT now() | Thời gian tải |
| `download_count` | integer | DEFAULT 1 | Số lần tải |

**Foreign Keys**:
- `file_id` → `material_attachments.id`
- `student_id` → `users.id`

---

## 8. Các bảng hỗ trợ

### 8.1. `semesters` - Học kỳ

**Mô tả**: Quản lý các học kỳ

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID học kỳ |
| `code` | varchar | UNIQUE, NOT NULL, CHECK (2-20 ký tự) | Mã học kỳ |
| `name` | varchar | NOT NULL, CHECK (2-100 ký tự) | Tên học kỳ |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Relationships**:
- Một semester có nhiều: `courses`, `users` (current_semester_id), `student_enrollments`

---

### 8.2. `courses` - Khóa học

**Mô tả**: Quản lý các khóa học

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID khóa học |
| `code` | varchar | UNIQUE, NOT NULL, CHECK (2-20 ký tự) | Mã khóa học |
| `name` | varchar | NOT NULL, CHECK (2-100 ký tự) | Tên khóa học |
| `session_count` | integer | NOT NULL, CHECK (10 hoặc 15) | Số buổi học |
| `semester_id` | uuid | FK → semesters.id | ID học kỳ |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `semester_id` → `semesters.id`

**Relationships**:
- Một course có nhiều: `groups`, `quizzes`, `assignments`, `announcements`, `materials`

---

### 8.3. `groups` - Nhóm học

**Mô tả**: Quản lý các nhóm học trong khóa học

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID nhóm |
| `name` | varchar | NOT NULL, CHECK (2-100 ký tự) | Tên nhóm |
| `course_id` | uuid | FK → courses.id | ID khóa học |
| `is_active` | boolean | DEFAULT true | Trạng thái |
| `created_at` | timestamp | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamp | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `course_id` → `courses.id`

**Relationships**:
- Một group có nhiều: `student_enrollments`, `quiz_groups`, `assignment_groups`, `announcement_groups`

---

### 8.4. `notifications` - Thông báo hệ thống

**Mô tả**: Hệ thống thông báo cho sinh viên

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID thông báo |
| `user_id` | uuid | FK → users.id | ID người dùng |
| `type` | varchar | NOT NULL, CHECK ('announcement', 'deadline', 'grade', 'feedback', 'submission', 'quiz', 'material', 'general') | Loại thông báo |
| `title` | varchar | NOT NULL, CHECK (1-255 ký tự) | Tiêu đề |
| `body` | text | NOT NULL, CHECK (>= 1 ký tự) | Nội dung |
| `data` | jsonb | DEFAULT '{}' | Dữ liệu bổ sung |
| `is_read` | boolean | DEFAULT false | Đã đọc |
| `read_at` | timestamptz | NULLABLE | Thời gian đọc |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `updated_at` | timestamptz | DEFAULT now() | Ngày cập nhật |

**Foreign Keys**:
- `user_id` → `users.id`

---

### 8.5. `temp_attachments` - File tạm thời

**Mô tả**: Lưu trữ file tạm thời trước khi đính kèm vào assignment/material

**Primary Keys**:
- `id` (uuid)

**Columns**:

| Column | Type | Constraints | Mô tả |
|--------|------|-------------|-------|
| `id` | uuid | PRIMARY KEY | ID file tạm |
| `temp_id` | varchar | UNIQUE, NOT NULL | ID tạm thời |
| `user_id` | uuid | FK → users.id | ID người dùng |
| `file_name` | varchar | NOT NULL | Tên file |
| `file_path` | text | NOT NULL | Đường dẫn lưu trữ |
| `file_url` | text | NULLABLE | URL file |
| `file_size` | bigint | NOT NULL | Kích thước (bytes) |
| `file_type` | varchar | NOT NULL | Loại file |
| `attachment_type` | varchar | DEFAULT 'assignment' | Loại đính kèm |
| `material_id` | uuid | NULLABLE, FK → materials.id | ID tài liệu (nếu là material) |
| `is_finalized` | boolean | DEFAULT false | Đã hoàn tất |
| `created_at` | timestamptz | DEFAULT now() | Ngày tạo |
| `expires_at` | timestamptz | DEFAULT now() + 24h | Thời gian hết hạn |

**Foreign Keys**:
- `user_id` → `users.id`
- `material_id` → `materials.id`

---

## 📊 Sơ đồ quan hệ tổng quan

### Quan hệ chính:

```
users (1) ──< (N) student_enrollments (N) >── (1) groups (1) >──< (N) courses
  │                                                                      │
  │                                                                      │
  ├──< (N) assignments ──< (N) assignment_submissions                  │
  ├──< (N) quizzes ──< (N) quiz_submissions                            │
  ├──< (N) announcements ──< (N) announcement_views                    │
  ├──< (N) materials ──< (N) material_views                            │
  ├──< (N) forum_topics ──< (N) forum_replies                          │
  ├──< (1) chat_users ──< (N) chat_messages                            │
  └──< (N) notifications                                                │
                                                                        │
semesters (1) >──< (N) courses (1) >──< (N) groups
```

### Các bảng trung gian (Many-to-Many):

- `assignment_groups`: assignments ↔ groups
- `quiz_groups`: quizzes ↔ groups
- `announcement_groups`: announcements ↔ groups
- `chat_room_members`: chat_rooms ↔ chat_users

---

## 🔑 Tổng kết các Foreign Keys quan trọng

### Users (users.id) được tham chiếu bởi:
- `user_sessions.user_id`
- `student_enrollments.student_id`
- `assignments.instructor_id`
- `assignment_submissions.student_id`, `graded_by`
- `quizzes.instructor_id`
- `quiz_submissions.student_id`, `graded_by`
- `announcements.instructor_id`
- `announcement_views.student_id`
- `announcement_comments.user_id`
- `materials.instructor_id`
- `material_views.student_id`
- `forum_topics.user_id`
- `forum_replies.user_id`
- `forum_likes.user_id`
- `forum_views.user_id`
- `chat_users.id` (1-1)
- `notifications.user_id`
- `temp_attachments.user_id`

### Courses (courses.id) được tham chiếu bởi:
- `groups.course_id`
- `assignments.course_id`
- `quizzes.course_id`
- `announcements.course_id`
- `materials.course_id`

### Groups (groups.id) được tham chiếu bởi:
- `student_enrollments.group_id`
- `assignment_groups.group_id`
- `quiz_groups.group_id`
- `announcement_groups.group_id`

---

## 📝 Ghi chú quan trọng

1. **RLS (Row Level Security)**: Một số bảng có RLS enabled:
   - `material_attachments`
   - `material_views`
   - `forum_temp_attachments`

2. **Self-referencing**: Các bảng có quan hệ tự tham chiếu:
   - `forum_replies.parent_reply_id` → `forum_replies.id`
   - `announcement_comments.parent_comment_id` → `announcement_comments.id`
   - `chat_messages.replied_message_id` → `chat_messages.id`

3. **Timestamps**: 
   - Hầu hết bảng sử dụng `timestamp without time zone`
   - Các bảng mới hơn (forum, chat, announcements, materials) sử dụng `timestamp with time zone` (timestamptz)

4. **Soft Delete**: Một số bảng sử dụng `is_deleted` thay vì xóa thật:
   - `announcements.is_deleted`
   - `forum_topics.is_deleted`
   - `forum_replies.is_deleted`
   - `announcement_comments.is_deleted`










