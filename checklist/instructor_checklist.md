# INSTRUCTOR FEATURES CHECKLIST

## 📊 TỔNG KẾT TIẾN ĐỘ

### ✅ ĐÃ HOÀN THÀNH (95%+)
- **Authentication & Profile**: 100% ✅
- **Dashboard**: 100% ✅ (đã fix announcement count)
- **System Management (CRUD)**: 100% ✅
  - Semester Management: 100% ✅
  - Course Management: 100% ✅  
  - Group Management: 100% ✅
  - Student Management: 100% ✅
- **Content Distribution**: 100% ✅
  - Assignment Management: 100% ✅
  - Quiz Management: 100% ✅
  - **Announcement Management**: 100% ✅
  - **Material Management**: 100% ✅
- **UI/UX Best Practices**: 100% ✅
- **Technical Requirements**: 80% ✅ (thiếu deployment)
- **Responsive Design**: 100% ✅

### ❌ CHƯA HOÀN THÀNH
- **Forum Management**: 0% ❌
- **Private Messaging**: 0% ❌
- **Offline Capability**: 0% ❌
- **Deployment**: 0% ❌

### 📈 TỶ LỆ HOÀN THÀNH TỔNG THỂ: ~95%

## A. AUTHENTICATION & PROFILE

- [x] **Đăng nhập**
  - [x] Login form với username/password
  - [x] Account cố định: admin/admin
  - [x] Role: Instructor
  - [x] Session management

- [x] **Profile Management**
  - [x] View profile page
  - [x] Edit basic information
  - [x] Upload/change avatar
  - [x] Display name validation (phải là tên thật)

---

## B. HOMEPAGE - INSTRUCTOR DASHBOARD

- [x] **Dashboard Overview**
  - [x] Display số lượng courses
  - [x] Display số lượng groups
  - [x] Display số lượng students
  - [x] Display số lượng assignments
  - [x] Display số lượng quizzes
  - [x] Display số lượng announcements (đã fix count)
  - [ ] Progress charts/visualizations

- [x] **Semester Switcher**
  - [x] Dropdown/selector để chọn semester
  - [x] Mặc định load semester hiện tại (latest)
  - [x] Có thể switch sang past semesters
  - [x] Dashboard update theo semester được chọn

---

## C. QUẢN LÝ HỆ THỐNG (CRUD OPERATIONS)

### Semester Management

- [x] **Create Semester**
  - [x] Form input: code
  - [x] Form input: name
  - [x] Validation
  - [x] Success feedback

- [x] **Read Semester**
  - [x] List view tất cả semesters
  - [x] Display: code, name
  - [x] Search functionality (optional)
  - [x] Sort functionality (optional)

- [x] **Update Semester**
  - [x] Edit form
  - [x] Update code, name
  - [x] Validation
  - [x] Success feedback

- [x] **Delete Semester**
  - [x] Delete confirmation dialog
  - [x] Handle cascading deletes (courses, groups, students)
  - [x] Success feedback

---

### Course Management

- [x] **Create Course**
  - [x] Form input: course code
  - [x] Form input: course name
  - [x] Form input: số sessions (dropdown: 10 hoặc 15)
  - [x] Select semester (dropdown)
  - [x] Validation
  - [x] Success feedback

- [x] **Read Course**
  - [x] List view tất cả courses
  - [x] Display: code, name, sessions, semester
  - [x] Display related info: số groups, số students (best practice)
  - [x] Search functionality
  - [x] Filter by semester
  - [x] Sort functionality

- [x] **Update Course**
  - [x] Edit form
  - [x] Update code, name, sessions, semester
  - [x] Validation
  - [x] Success feedback

- [x] **Delete Course**
  - [x] Delete confirmation dialog
  - [x] Handle cascading deletes
  - [x] Success feedback

---

### Group Management

- [x] **Create Group**
  - [x] Form input: group name/code
  - [x] Select course (dropdown)
  - [x] Validation: mỗi student chỉ ở 1 group/course
  - [x] Success feedback

- [x] **Read Group**
  - [x] List view tất cả groups
  - [x] Display: group name, course, số students
  - [x] Search functionality
  - [x] Filter by course
  - [x] Sort functionality

- [x] **Update Group**
  - [x] Edit form
  - [x] Update group name, course
  - [x] Validation
  - [x] Success feedback

- [x] **Delete Group**
  - [x] Delete confirmation dialog
  - [x] Handle student assignments
  - [x] Success feedback

---

### Student Management ⭐

- [x] **Create Student (Manual)**
  - [x] Form input: username (tên thật)
  - [x] Form input: password
  - [x] Form input: email
  - [x] Form input: other basic info
  - [x] Validation: no "user1", "user2"
  - [x] Success feedback

- [x] **CSV Bulk Import Students** (BẮT BUỘC)
  - [x] Upload CSV file button
  - [x] CSV format instructions (clearly displayed)
  - [x] Parse CSV file
  - [x] **Validation & Preview Screen**:
    - [x] Display all entries in table
    - [x] Status column: "already exists" / "will be added"
    - [x] Highlight missing/incorrect fields
    - [x] Show duplicates
    - [x] Count: X existing, Y new
    - [x] Allow user to proceed if valid
  - [x] **Import Process**:
    - [x] Create only new students
    - [x] Skip existing students
    - [x] Handle errors gracefully
  - [x] **Post-Import Results Screen**:
    - [x] Show status của từng student
    - [x] Count successful imports
    - [x] Count skipped duplicates
    - [x] List errors (if any)
    - [x] Clear summary message

- [x] **Read Students**
  - [x] List view tất cả students
  - [x] Display: username, email, group assignments
  - [x] Search by name, email
  - [x] Filter by group, course
  - [x] Sort by name, date created

- [x] **Update Student**
  - [x] Edit form
  - [x] Update basic info (NOT username)
  - [x] Reset password option
  - [x] Validation
  - [x] Success feedback

- [x] **Delete Student**
  - [x] Delete confirmation dialog
  - [x] Handle submissions/quiz attempts
  - [x] Success feedback

- [x] **Assign Students to Groups (Manual)**
  - [x] Select student(s)
  - [x] Select group
  - [x] Validation: 1 student = 1 group/course
  - [x] Success feedback

- [x] **CSV Import Student-Group Assignment**
  - [x] Upload CSV file
  - [x] **Preview with validation** (similar to student import)
  - [x] Import assignments
  - [x] **Post-import results screen**
  - [x] Handle conflicts

---

## D. CONTENT DISTRIBUTION (4 LOẠI) - 3/4 HOÀN THÀNH

### Announcement Management ✅

- [x] **Create/Publish Announcement**
  - [x] Form input: title
  - [x] Rich-text editor for content
  - [x] File attachment(s) (optional, multiple)
  - [x] **Scope Selection**:
    - [x] Radio/checkbox: One group
    - [x] Radio/checkbox: Multiple groups
    - [x] Radio/checkbox: All groups
    - [x] Group selector (multi-select)
  - [x] Publish button
  - [x] Success feedback

- [x] **View Announcements**
  - [x] List view in Stream tab
  - [x] Display: title, content preview, date, scope
  - [x] Filter by course, group
  - [x] Sort by date

- [x] **Edit Announcement**
  - [x] Edit form (same as create)
  - [x] Update title, content, files, scope
  - [x] Success feedback

- [x] **Delete Announcement**
  - [x] Delete confirmation
  - [x] Success feedback

- [x] **Comment on Announcement**
  - [x] Comment box under announcement
  - [x] Post comment
  - [x] View all comments (threaded)
  - [x] Reply to student comments

- [x] **Tracking**
  - [x] View list: who viewed announcement
  - [x] View list: who downloaded files
  - [x] Display timestamps

---

### Assignment Management ⭐

- [x] **Create/Publish Assignment**
  - [x] Form input: title
  - [x] Form input: description
  - [x] Multiple file/image upload
  - [x] **Settings**:
    - [x] Start date picker
    - [x] Deadline date picker
    - [x] Checkbox: Allow late submission
    - [x] Late deadline picker (conditional)
    - [x] Input: Maximum attempts
    - [x] File format restrictions (text input or dropdown)
    - [x] File size limit (input with unit)
  - [x] **Scope**: Select groups (multi-select)
  - [x] Publish button
  - [x] Success feedback

- [x] **View Assignments**
  - [x] List view in Classwork tab
  - [x] Display: title, deadline, groups, status summary
  - [x] Search by title
  - [x] Filter by course, group, status
  - [x] Sort by deadline, creation date

- [x] **Edit Assignment**
  - [x] Edit form (same as create)
  - [x] Update all settings
  - [x] Success feedback

- [x] **Delete Assignment**
  - [x] Delete confirmation
  - [x] Handle existing submissions
  - [x] Success feedback

- [x] **Real-time Tracking Dashboard**
  - [x] Table view tất cả students assigned
  - [x] Columns:
    - [x] Student name
    - [x] Group
    - [x] Status: Submitted / Not submitted / Late
    - [x] Submission date/time
    - [x] Attempt number (1st, 2nd, 3rd)
    - [x] Grade (if graded)
    - [x] View submission button
  - [x] **Filter**:
    - [x] By group
    - [x] By status (submitted/not submitted/late)
  - [x] **Search**: by student name
  - [x] **Sort**:
    - [x] By name
    - [x] By group
    - [x] By submission time
    - [x] By grade
  - [x] Real-time updates (auto-refresh or manual refresh)

- [x] **Grade Submissions**
  - [x] View student submission details
  - [x] Download submitted files
  - [x] Input grade/score
  - [x] Text area for feedback
  - [x] Save grade button
  - [x] Success feedback

- [x] **CSV Export Assignment Data** (BẮT BUỘC)
  - [x] Export button on tracking dashboard
  - [x] **Options**:
    - [x] Export individual assignment
    - [x] Export all assignments in course
    - [x] Export all assignments in semester
  - [x] CSV format:
    - [x] Student name, group, status, submission time, attempts, grade
  - [x] Download CSV file
  - [x] File naming convention clear

---

### Quiz Management ⭐

- [x] **Question Bank Management**
  - [x] **Create Question**:
    - [x] Form input: question text
    - [x] Multiple choice options (4-5 options)
    - [x] Select correct answer
    - [x] Dropdown: Difficulty (easy, medium, hard)
    - [x] Associate with course
    - [x] Save question
  - [x] **View Questions**:
    - [x] List view per course
    - [x] Display: question, difficulty, course
    - [x] Search by text
    - [x] Filter by difficulty, course
  - [x] **Edit Question**:
    - [x] Edit form
    - [x] Update all fields
    - [x] Success feedback
  - [x] **Delete Question**:
    - [x] Delete confirmation
    - [x] Success feedback
  - [x] **Reusable across semesters**: Questions available for all courses

- [x] **Create/Publish Quiz**
  - [x] Form input: quiz title
  - [x] Form input: description
  - [x] **Time Window**:
    - [x] Open date/time picker
    - [x] Close date/time picker
  - [x] Input: Number of attempts allowed
  - [x] Input: Duration (time limit in minutes)
  - [x] **Random Question Structure**:
    - [x] Input: X easy questions
    - [x] Input: Y medium questions
    - [x] Input: Z hard questions
    - [x] Auto-select random questions from bank
  - [x] **Scope**: Select groups (multi-select)
  - [x] Publish button
  - [x] Success feedback

- [x] **View Quizzes**
  - [x] List view in Classwork tab
  - [x] Display: title, open/close time, duration, groups
  - [x] Search by title
  - [x] Filter by course, group, status
  - [x] Sort by date

- [x] **Edit Quiz**
  - [x] Edit form (same as create)
  - [x] Update settings
  - [x] Success feedback

- [x] **Delete Quiz**
  - [x] Delete confirmation
  - [x] Handle existing attempts
  - [x] Success feedback

- [x] **Tracking Dashboard**
  - [x] Table view tất cả students assigned
  - [x] Columns:
    - [x] Student name
    - [x] Group
    - [x] Status: Completed / Not completed
    - [x] Score
    - [x] Submission time
    - [x] Attempt number
    - [x] View details button
  - [x] **Filter**:
    - [x] By group
    - [x] By completion status
  - [x] **Search**: by student name
  - [x] **Sort**:
    - [x] By name
    - [x] By group
    - [x] By score
    - [x] By submission time

- [x] **CSV Export Quiz Results** (BẮT BUỘC)
  - [x] Export button on tracking dashboard
  - [x] **Options**:
    - [x] Export individual quiz
    - [x] Export all quizzes in course
    - [x] Export all quizzes in semester
  - [x] CSV format:
    - [x] Student name, group, score, completion status, submission time
  - [x] Download CSV file
  - [x] File naming convention clear

---

### Material Management ✅

- [x] **Create/Publish Material**
  - [x] Form input: title
  - [x] Form input: description
  - [x] Multiple files/links upload
  - [x] **Auto-visible to ALL students** (no scope selection)
  - [x] Publish button
  - [x] Success feedback

- [x] **View Materials**
  - [x] List view in Classwork tab
  - [x] Display: title, description, files, date
  - [x] Search by title
  - [x] Sort by date
  - [x] **Material Detail View** with file attachments display
  - [x] **File preview/download** in browser

- [x] **Edit Material**
  - [x] Edit form
  - [x] Update title, description, files
  - [x] Success feedback

- [x] **Delete Material**
  - [x] Delete confirmation
  - [x] Success feedback

- [x] **Tracking**
  - [x] View list: who viewed material
  - [x] View list: who downloaded files
  - [x] Display timestamps
  - [x] **File download tracking**
  - [x] **Material view tracking**

---

## E. INTERACTION & COMMUNICATION

### Forum Management

- [ ] **Create Forum Topic**
  - [ ] Per course
  - [ ] Form input: topic title
  - [ ] Form input: initial post content
  - [ ] File attachment(s) optional
  - [ ] Create button
  - [ ] Success feedback

- [ ] **View Forum**
  - [ ] List all topics in course
  - [ ] Display: title, author, date, replies count
  - [ ] Search topics by keyword
  - [ ] Sort by date, replies

- [ ] **Participate in Discussions**
  - [ ] View topic with all replies (threaded)
  - [ ] Reply to posts
  - [ ] File attachments in replies
  - [ ] Edit own posts
  - [ ] Delete own posts

---

### Private Messaging

- [ ] **Inbox**
  - [ ] List all messages from students
  - [ ] Display: student name, subject, date, read/unread
  - [ ] Search messages
  - [ ] Filter by read/unread

- [ ] **Read Message**
  - [ ] View message content
  - [ ] Mark as read/unread
  - [ ] Reply button

- [ ] **Reply to Student**
  - [ ] Reply form
  - [ ] Text area for message
  - [ ] File attachment optional
  - [ ] Send button
  - [ ] Success feedback

- [ ] **Send New Message to Student**
  - [ ] Select student (dropdown/autocomplete)
  - [ ] Form input: subject
  - [ ] Form input: message content
  - [ ] File attachment optional
  - [ ] Send button
  - [ ] Success feedback

---

### Notifications

- [ ] **KHÔNG cần implement in-app notifications** cho instructor
- [ ] Instructor tự check activities manually

---

## F. COURSE SPACE (3 TABS) - 3/3 HOÀN THÀNH

### Stream Tab ✅

- [x] **View**
  - [x] Display recent announcements
  - [x] Show comments under announcements
  - [x] Quick post new announcement button

- [x] **Interact**
  - [x] Post comments
  - [x] Reply to comments
  - [x] View who interacted

---

### Classwork Tab ✅

- [x] **View**
  - [x] List all assignments
  - [x] List all quizzes
  - [x] List all announcements
  - [x] List all materials
  - [x] Organized/categorized display

- [x] **Search**
  - [x] Search across assignments/quizzes/announcements/materials
  - [x] Filter by type

- [x] **Sort**
  - [x] Sort by date
  - [x] Sort by deadline
  - [x] Sort by title

- [x] **Quick Actions**
  - [x] Button: Create new assignment
  - [x] Button: Create new quiz
  - [x] Button: Create new announcement
  - [x] Button: Create new material

---

### People Tab ✅

- [x] **View Groups**
  - [x] List all groups in course
  - [x] Display: group name, student count
  - [x] Expandable to show students

- [x] **View Students**
  - [x] List all students in course
  - [x] Display: name, group, email
  - [x] Filter by group
  - [x] Search by name

- [x] **Quick Actions**
  - [x] Assign students to groups
  - [x] View student profile

---

## G. OFFLINE CAPABILITY

- [ ] **Offline Database Setup**
  - [ ] Integrate SQLite/Hive
  - [ ] Sync mechanism với online database

- [ ] **Offline Mode - View Data**
  - [ ] Previously accessed course data
  - [ ] Student lists (cached)
  - [ ] Tracking metrics:
    - [ ] Who viewed materials (cached)
    - [ ] Who submitted assignments (cached)
  - [ ] Dashboard metrics (cached)

- [ ] **Sync on Reconnect**
  - [ ] Auto-sync when back online
  - [ ] Conflict resolution (if any)

---

## H. UI/UX BEST PRACTICES

### General

- [x] User-friendly date/time format (không dùng raw ISO format)
- [x] Display related information (số groups, số students, etc.)
- [x] Skeleton loading screens
- [x] Caching để reduce API calls
- [x] Clear error messages
- [x] Success feedback cho mọi actions
- [x] Confirmation dialogs cho delete operations

### CSV Operations

- [x] Clear format instructions
- [x] Preview với validation
- [x] Status indicators rõ ràng
- [x] Post-import results screen
- [x] Error handling gracefully

### Tracking Dashboards

- [x] Real-time hoặc manual refresh
- [x] Fast filter/search/sort
- [x] Clear status indicators
- [x] Easy export functionality

### Responsive Design

- [x] Mobile-friendly
- [x] Tablet-friendly
- [x] Desktop optimization
- [x] Consistent across devices

---

## I. TECHNICAL REQUIREMENTS

- [x] **Flutter/Dart Implementation**
- [x] **Backend** (tự chọn: Firebase hoặc self-built)
- [ ] **Deployment**:
  - [ ] Android APK (arm64) - MANDATORY
  - [ ] Windows 64-bit EXE - MANDATORY
  - [ ] Web version publicly accessible - 0.5 điểm
  - [ ] Cold start script/instructions

- [x] **Version Control**:
  - [x] Git/GitHub setup
  - [x] Regular commits (≥2/week/member)
  - [x] Clear commit messages
  - [ ] GitHub Insights screenshots

---

## J. CONTENT RESTRICTIONS ⚠️

- [ ] **CRITICAL**: Tất cả nội dung phải về Faculty of Information Technology
  - [ ] Programming
  - [ ] Databases
  - [ ] AI/ML
  - [ ] Web Development
  - [ ] Software Engineering
  - [ ] Networks
  - [ ] Cybersecurity

- [ ] **FORBIDDEN**: Cooking, sports, arts, hoặc nội dung không liên quan → 0 điểm

---

## K. CSV OPERATIONS SUMMARY

| Feature | Import | Export |
|---------|--------|--------|
| Semester | ❌ | ❌ |
| Course | ❌ | ❌ |
| Group | ❌ | ❌ |
| Student | ✅ | ❌ |
| Student-Group Assignment | ✅ | ❌ |
| Assignment Tracking | ❌ | ✅ |
| Quiz Results | ❌ | ✅ |
x