# ProfileController Implementation Guide

## 📋 Tổng quan
Tạo ProfileController để quản lý hồ sơ cá nhân người dùng theo yêu cầu US10.

## 🗄️ Database Schema
- **Bảng**: `users`
- **Cột avatar**: `avatar_url` (TEXT, nullable)
- **Các cột khác**: `id`, `username`, `email`, `full_name`, `role`, `is_active`, `last_login_at`, `created_at`, `updated_at`, `current_semester_id`

## 🚀 API Endpoints cần tạo

### 1. GET /api/profile
**Mục đích**: Lấy thông tin hồ sơ cá nhân của user hiện tại

**Response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "email": "string", 
      "full_name": "string",
      "role": "instructor|student",
      "avatar_url": "string|null",
      "is_active": true,
      "last_login_at": "timestamp",
      "created_at": "timestamp",
      "updated_at": "timestamp"
    }
  }
}
```

### 2. PUT /api/profile
**Mục đích**: Cập nhật thông tin hồ sơ cá nhân

**Request Body**:
```json
{
  "full_name": "string",
  "email": "string"
}
```

**Validation**:
- `full_name`: 2-50 ký tự, chỉ chữ cái và khoảng trắng
- `email`: format email hợp lệ, unique
- Không cho phép thay đổi `username`, `role`

**Response**:
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user": { /* updated user data */ }
  }
}
```

### 3. POST /api/profile/avatar
**Mục đích**: Upload avatar cho user

**Request**: `multipart/form-data`
- `avatar`: File (image/jpeg, image/png, image/gif)
- Max size: 5MB
- Max dimensions: 1024x1024px

**Response**:
```json
{
  "success": true,
  "message": "Avatar uploaded successfully",
  "data": {
    "avatar_url": "https://supabase-storage-url/avatars/user-id/filename.jpg"
  }
}
```

## 🔧 Implementation Details

### 1. ProfileController Structure
```javascript
const { supabase } = require('../services/supabaseClient');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const multer = require('multer');
const sharp = require('sharp');

class ProfileController {
  // GET /api/profile
  getProfile = catchAsync(async (req, res) => { ... });
  
  // PUT /api/profile  
  updateProfile = catchAsync(async (req, res) => { ... });
  
  // POST /api/profile/avatar
  uploadAvatar = catchAsync(async (req, res) => { ... });
}
```

### 2. Dependencies cần cài đặt
```bash
npm install multer sharp
```

### 3. Multer Configuration
```javascript
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});
```

### 4. Supabase Storage Setup
- **Bucket name**: `avatars`
- **Path pattern**: `avatars/{user_id}/{filename}`
- **Public access**: Yes (để hiển thị avatar)

### 5. Image Processing với Sharp
```javascript
// Resize và optimize image
const processedImage = await sharp(req.file.buffer)
  .resize(300, 300, { fit: 'cover' })
  .jpeg({ quality: 80 })
  .toBuffer();
```

### 6. Error Handling
- **Validation errors**: 400 Bad Request
- **File too large**: 413 Payload Too Large
- **Invalid file type**: 400 Bad Request
- **User not found**: 404 Not Found
- **Database errors**: 500 Internal Server Error

## 🔒 Security Considerations

### 1. File Upload Security
- Validate file type (chỉ cho phép image)
- Giới hạn kích thước file (5MB)
- Resize image để tránh DoS
- Tạo unique filename để tránh conflict

### 2. Data Validation
- Validate email format
- Validate full_name (chỉ chữ cái và khoảng trắng)
- Check email uniqueness trước khi update

### 3. Authorization
- Chỉ cho phép user cập nhật profile của chính mình
- Sử dụng `req.user.id` từ auth middleware

## 📝 Routes Setup

### File: `src/routes/profile.js`
```javascript
const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { authenticateToken } = require('../middleware/auth');
const multer = require('multer');

// Multer config
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Routes
router.get('/', authenticateToken, profileController.getProfile);
router.put('/', authenticateToken, profileController.updateProfile);
router.post('/avatar', authenticateToken, upload.single('avatar'), profileController.uploadAvatar);

module.exports = router;
```

### File: `src/routes/index.js` (hoặc server.js)
```javascript
app.use('/api/profile', require('./routes/profile'));
```

## 🧪 Testing

### 1. GET /api/profile
```bash
curl -X GET http://localhost:3000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. PUT /api/profile
```bash
curl -X PUT http://localhost:3000/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"full_name": "New Name", "email": "new@email.com"}'
```

### 3. POST /api/profile/avatar
```bash
curl -X POST http://localhost:3000/api/profile/avatar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "avatar=@/path/to/image.jpg"
```

## 📋 Checklist Implementation

- [ ] Tạo ProfileController class
- [ ] Implement getProfile method
- [ ] Implement updateProfile method  
- [ ] Implement uploadAvatar method
- [ ] Setup multer configuration
- [ ] Setup Supabase storage bucket
- [ ] Add image processing với Sharp
- [ ] Tạo routes file
- [ ] Add routes vào main app
- [ ] Test tất cả endpoints
- [ ] Handle error cases
- [ ] Add JSDoc documentation

## 🎯 Key Features

1. **GET Profile**: Lấy thông tin user hiện tại
2. **UPDATE Profile**: Cập nhật full_name và email
3. **UPLOAD Avatar**: Upload và resize ảnh avatar
4. **Security**: Validate input, file type, size limits
5. **Error Handling**: Comprehensive error responses
6. **Image Processing**: Auto-resize và optimize ảnh
