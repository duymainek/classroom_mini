# US04 Implementation Plan: Assignment Management System

## 🎯 Overview
Triển khai hệ thống quản lý bài tập (Assignment) với khả năng tạo, phân phối, theo dõi và đánh giá bài tập cho giảng viên và sinh viên.

## 📋 Requirements Analysis

### Core Features
1. **Assignment Creation**
   - Title, description, file attachments
   - Time settings (start date, deadline, late submission)
   - Submission limits (max attempts, file format, size)
   - Group distribution (one/multiple/all groups)

2. **Real-time Tracking**
   - Submission status (submitted/not submitted/late)
   - Multiple attempts tracking
   - Current grades
   - Filtering, searching, sorting
   - CSV export

3. **Student Interface**
   - View assignment details
   - Submit files with validation
   - Track submission history

## 🏗️ Architecture Design

### Database Schema
```sql
-- Assignments table
CREATE TABLE assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  course_id UUID REFERENCES courses(id),
  instructor_id UUID REFERENCES users(id),
  start_date TIMESTAMP NOT NULL,
  due_date TIMESTAMP NOT NULL,
  late_due_date TIMESTAMP,
  allow_late_submission BOOLEAN DEFAULT false,
  max_attempts INTEGER DEFAULT 1,
  file_formats TEXT[], -- ['pdf', 'doc', 'docx']
  max_file_size INTEGER, -- in MB
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Assignment attachments
CREATE TABLE assignment_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  file_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Assignment group distribution
CREATE TABLE assignment_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(assignment_id, group_id)
);

-- Assignment submissions
CREATE TABLE assignment_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL,
  submission_text TEXT,
  submitted_at TIMESTAMP DEFAULT NOW(),
  is_late BOOLEAN DEFAULT false,
  grade DECIMAL(5,2),
  feedback TEXT,
  graded_at TIMESTAMP,
  graded_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Submission attachments
CREATE TABLE submission_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID REFERENCES assignment_submissions(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  file_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Backend API Structure
```
/backend/src/
├── controllers/
│   └── assignmentController.js
├── routes/
│   └── assignments.js
├── models/
│   └── assignment.js
└── middleware/
    └── fileUpload.js
```

### Frontend Structure
```
lib/app/modules/assignments/
├── view/
│   ├── web/
│   │   ├── assignment_list_page.dart
│   │   ├── assignment_create_page.dart
│   │   ├── assignment_detail_page.dart
│   │   └── assignment_tracking_page.dart
│   ├── mobile/
│   │   ├── assignment_list_page.dart
│   │   ├── assignment_create_page.dart
│   │   ├── assignment_detail_page.dart
│   │   └── assignment_submit_page.dart
│   ├── desktop/
│   │   ├── assignment_list_page.dart
│   │   ├── assignment_create_page.dart
│   │   ├── assignment_detail_page.dart
│   │   └── assignment_tracking_page.dart
│   └── shared/
│       ├── widgets/
│       │   ├── assignment_card.dart
│       │   ├── assignment_form.dart
│       │   ├── submission_tracker.dart
│       │   └── file_upload_widget.dart
│       ├── models/
│       │   ├── assignment_model.dart
│       │   └── submission_model.dart
│       └── services/
│           └── assignment_service.dart
```

## 🚀 Implementation Steps

### Phase 1: Database & Backend API
1. **Database Schema Setup**
   - Create tables using Supabase MCP
   - Set up relationships and constraints
   - Create indexes for performance

2. **Backend API Development**
   - Assignment CRUD operations
   - File upload handling
   - Submission tracking
   - CSV export functionality

### Phase 2: Responsive UI Development
1. **Shared Components**
   - Assignment models and services
   - Common widgets and utilities

2. **Platform-specific Views**
   - Web: Full-featured interface
   - Mobile: Touch-optimized interface
   - Desktop: Multi-window support

### Phase 3: Integration & Testing
1. **API Integration**
   - Connect frontend to backend
   - Error handling and validation

2. **Testing & Validation**
   - Unit tests for backend
   - UI testing for all platforms
   - End-to-end testing

## 📱 Responsive Design Strategy

### Material 3 Design System
- **Web**: Full Material 3 components
- **Mobile**: Adaptive Material 3 with touch gestures
- **Desktop**: Material 3 with keyboard shortcuts

### Platform-specific Adaptations
- **Web**: Multi-column layouts, drag-and-drop
- **Mobile**: Bottom sheets, swipe gestures
- **Desktop**: Context menus, keyboard navigation

## 🔧 Technical Considerations

### File Upload & Storage
- Supabase Storage integration
- File validation and virus scanning
- Progress tracking for large files

### Real-time Updates
- WebSocket connections for live tracking
- Push notifications for mobile
- Desktop notifications

### Performance Optimization
- Lazy loading for large assignment lists
- Pagination for submissions
- Caching for frequently accessed data

## 📊 Success Metrics
- Assignment creation time < 2 minutes
- File upload success rate > 99%
- Real-time tracking accuracy
- Cross-platform consistency
- User satisfaction scores

## 🎯 Next Steps
1. Set up database schema
2. Implement backend API
3. Create shared UI components
4. Develop platform-specific views
5. Integration and testing
