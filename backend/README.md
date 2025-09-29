# Classroom Mini Backend API

Backend API cho ứng dụng E-learning Management với Node.js, Express và Supabase.

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18.0.0
- Supabase account và project
- Git

### Installation

1. **Clone repository và di chuyển vào thư mục backend:**
```bash
cd backend
```

2. **Install dependencies:**
```bash
npm install
```

3. **Setup environment variables:**
```bash
cp env.example .env
```

4. **Cập nhật file .env với thông tin Supabase của bạn:**
```env
# Supabase Configuration
SUPABASE_URL=https://jcarmifgsafuquvxddah.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_REFRESH_SECRET=your_super_secret_refresh_key_change_this_in_production
```

5. **Start development server:**
```bash
npm run dev
```

Server sẽ chạy tại: `http://localhost:3000`

## 📊 Database Schema

Trước khi chạy server, bạn cần tạo bảng `users` trong Supabase:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  salt VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('instructor', 'student')),
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT chk_instructor_username CHECK (
    (role = 'instructor' AND username = 'admin') OR role = 'student'
  )
);

-- Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

## 🔌 API Endpoints

### Authentication Endpoints

#### Public Endpoints
- `POST /api/auth/instructor/login` - Instructor login
- `POST /api/auth/student/login` - Student login  
- `POST /api/auth/refresh` - Refresh access token

#### Protected Endpoints (require authentication)
- `GET /api/auth/me` - Get current user info
- `PUT /api/auth/profile` - Update user profile
- `POST /api/auth/logout` - Logout

### Student Management Endpoints (Instructor Only)

#### CRUD Operations
- `POST /api/students` - Create student account
- `GET /api/students` - Get students with pagination, search, filter
- `PUT /api/students/:studentId` - Update student information
- `DELETE /api/students/:studentId` - Delete student account

#### Advanced Features
- `POST /api/students/bulk` - Bulk operations (activate, deactivate, delete)
- `GET /api/students/statistics` - Get student statistics
- `POST /api/students/:studentId/reset-password` - Reset student password
- `GET /api/students/export` - Export students data
- `GET /api/students/health` - Service health check
  
#### CSV Import (US03)
- `POST /api/students/import/preview` - Validate CSV records and return per-row status (READY/ERROR)
- `POST /api/students/import` - Create student accounts for valid records, returns summary and per-row results
- `GET /api/students/import/template` - Download CSV template

#### Query Parameters for GET /api/students
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `search` - Search in name, username, email
- `status` - Filter by status: all, active, inactive
- `sortBy` - Sort field: created_at, full_name, username, email
- `sortOrder` - Sort order: asc, desc

### Dashboard Endpoints (Protected)

#### Instructor Dashboard
- `GET /api/dashboard/instructor` - Get instructor dashboard statistics
- `GET /api/dashboard/current-semester` - Get current semester
- `POST /api/dashboard/switch-semester/:semesterId` - Switch semester context

#### Student Dashboard  
- `GET /api/dashboard/student` - Get student dashboard data

### Core Management Endpoints (Instructor Only)

#### Semester Management
- `POST /api/semesters` - Create new semester
- `GET /api/semesters` - Get semesters with pagination, search, filter
- `GET /api/semesters/:semesterId` - Get semester by ID
- `PUT /api/semesters/:semesterId` - Update semester
- `DELETE /api/semesters/:semesterId` - Delete semester
- `GET /api/semesters/statistics` - Get semester statistics

#### Course Management
- `POST /api/courses` - Create new course
- `GET /api/courses` - Get courses with pagination, search, filter
- `GET /api/courses/:courseId` - Get course by ID
- `PUT /api/courses/:courseId` - Update course
- `DELETE /api/courses/:courseId` - Delete course
- `GET /api/courses/semester/:semesterId` - Get courses by semester
- `GET /api/courses/statistics` - Get course statistics

#### Group Management
- `POST /api/groups` - Create new group
- `GET /api/groups` - Get groups with pagination, search, filter
- `GET /api/groups/:groupId` - Get group by ID
- `PUT /api/groups/:groupId` - Update group
- `DELETE /api/groups/:groupId` - Delete group
- `GET /api/groups/course/:courseId` - Get groups by course
- `GET /api/groups/statistics` - Get group statistics

#### Query Parameters for Core Management
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `search` - Search in relevant fields
- `status` - Filter by status: all, active, inactive
- `sortBy` - Sort field: created_at, name, code
- `sortOrder` - Sort order: asc, desc
- `semesterId` - Filter courses by semester (courses only)
- `courseId` - Filter groups by course (groups only)

### Example API Calls

#### Instructor Login
```bash
curl -X POST http://localhost:3000/api/auth/instructor/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}'
```

#### Create Student (requires instructor token)
```bash
curl -X POST http://localhost:3131/api/students \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "username": "student1",
    "password": "student123",
    "email": "student1@example.com",
    "fullName": "Nguyễn Văn A"
  }'
```

#### Get Students with Search and Pagination
```bash
curl -X GET "http://localhost:3131/api/students?page=1&limit=10&search=Nguyễn&status=active" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Bulk Operations
```bash
curl -X POST http://localhost:3131/api/students/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "studentIds": ["uuid1", "uuid2"],
    "action": "activate"
  }'
```

#### Get Statistics
#### Import Preview
```bash
curl -X POST http://localhost:3131/api/students/import/preview \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "records": [
      {"fullName": "Nguyễn Văn A", "email": "a@classroom.edu", "username": "nguyenvana"},
      {"fullName": "Trần Thị B", "email": "b@classroom.edu", "username": "tranthib", "initialPassword": "student123"}
    ]
  }'
```

#### Import Confirm
```bash
curl -X POST http://localhost:3131/api/students/import \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "records": [
      {"fullName": "Nguyễn Văn A", "email": "a@classroom.edu", "username": "nguyenvana"}
    ]
  }'
```

#### Get CSV Template
```bash
curl -X GET http://localhost:3131/api/students/import/template \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```
```bash
curl -X GET http://localhost:3131/api/students/statistics \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Student Login
```bash
curl -X POST http://localhost:3131/api/auth/student/login \
  -H "Content-Type: application/json" \
  -d '{"username": "student1", "password": "student123"}'
```

#### Create Semester
```bash
curl -X POST http://localhost:3131/api/semesters \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "code": "HK2024-1",
    "name": "Học kỳ 1 năm 2024"
  }'
```

#### Create Course
```bash
curl -X POST http://localhost:3131/api/courses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "code": "CS101",
    "name": "Lập trình Cơ bản",
    "sessionCount": 15,
    "semesterId": "semester-uuid-here"
  }'
```

#### Create Group
```bash
curl -X POST http://localhost:3131/api/groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "name": "Nhóm 1",
    "courseId": "course-uuid-here"
  }'
```

#### Get Semesters with Search
```bash
curl -X GET "http://localhost:3131/api/semesters?page=1&limit=10&search=2024&status=active" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Courses by Semester
```bash
curl -X GET "http://localhost:3131/api/courses/semester/semester-uuid-here?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Groups by Course
```bash
curl -X GET "http://localhost:3131/api/groups/course/course-uuid-here?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Instructor Dashboard
```bash
curl -X GET http://localhost:3131/api/dashboard/instructor \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Student Dashboard
```bash
curl -X GET http://localhost:3131/api/dashboard/student \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Get Current Semester
```bash
curl -X GET http://localhost:3131/api/dashboard/current-semester \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Switch Semester Context
```bash
curl -X POST http://localhost:3131/api/dashboard/switch-semester/semester-uuid-here \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 🔐 Security Features

- **JWT Authentication** với access và refresh tokens
- **Password Hashing** với bcrypt và salt (12 rounds)
- **Rate Limiting** để chống brute force attacks
- **CORS** configuration
- **Helmet** cho security headers
- **Enhanced Input Validation** với Joi
  - Vietnamese name validation
  - SQL injection prevention
  - XSS protection
- **Role-based Access Control (RBAC)**
- **Bulk Operation Security** (max 100 items)
- **Search Input Sanitization**
  
- **Import Safety**
  - Max 1000 rows per request
  - Per-row validation (Vietnamese name, email, username rules)
  - Duplicate detection (in-file and existing DB)
  - Rate limiting on import endpoints

## 🏗️ Architecture

```
backend/
├── src/
│   ├── controllers/     # Request handlers
│   │   ├── authController.js
│   │   ├── studentController.js    # Student management
│   │   ├── semesterController.js   # NEW: Semester management
│   │   ├── courseController.js     # NEW: Course management
│   │   └── groupController.js      # NEW: Group management
│   ├── middleware/      # Custom middleware
│   │   ├── auth.js
│   │   └── errorHandler.js
│   ├── routes/         # Route definitions
│   │   ├── auth.js
│   │   ├── students.js             # Student management routes
│   │   ├── semesters.js            # NEW: Semester routes
│   │   ├── courses.js              # NEW: Course routes
│   │   └── groups.js               # NEW: Group routes
│   ├── models/         # Data models and validation
│   │   ├── semester.js             # NEW: Semester model
│   │   ├── course.js               # NEW: Course model
│   │   └── group.js                # NEW: Group model
│   ├── services/       # Business logic
│   │   └── supabaseClient.js
│   └── utils/          # Utility functions
│       ├── passwordUtils.js
│       ├── tokenUtils.js
│       └── validators.js           # ENHANCED: Vietnamese validation
├── server.js           # Main server file
├── test-api.sh         # Basic API testing
├── test-student-api.sh # Student API testing
└── package.json        # Dependencies
```

## 🧪 Testing

### Manual Testing
1. Start server: `npm run dev`
2. Test health endpoint: `GET http://localhost:3131/health`
3. Test auth routes: `GET http://localhost:3131/api/auth/test`

### Automated Testing
```bash
# Test basic authentication
./test-api.sh

# Test enhanced student management
./test-student-api.sh
```

### Default Admin Account
- Username: `admin`
- Password: `admin`
- Tài khoản này sẽ được tự động tạo khi server khởi động lần đầu

## 🔧 Development

### Available Scripts
```bash
npm start       # Start production server
npm run dev     # Start development server with nodemon
npm test        # Run tests (to be implemented)
npm run build   # Build for production
```

### Environment Variables
```env
PORT=3000
NODE_ENV=development
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_key
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## 🚀 Deployment

### Netlify Functions (Production)
1. Build project: `npm run build`
2. Deploy to Netlify với Netlify Functions enabled
3. Set environment variables trong Netlify dashboard

### Traditional Hosting
1. Set production environment variables
2. Run: `npm start`

## 📝 API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE",
  "errors": ["Validation error 1", "Validation error 2"]
}
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details