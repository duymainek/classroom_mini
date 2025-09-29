# 🔧 Khắc phục lỗi Avatar Upload - "Bucket not found"

## ❌ Vấn đề
Lỗi `BUCKET_VERIFICATION_FAILED` khi upload avatar:
```json
{
  "success": false,
  "message": "Bucket not found",
  "code": "BUCKET_VERIFICATION_FAILED"
}
```

## ✅ Giải pháp đã thực hiện

### 1. Tạo bucket `avatars` trong Supabase Storage
```bash
# Chạy script để tạo bucket tự động
node scripts/create-bucket-manually.js
```

### 2. Cải thiện error handling trong ProfileController
- Thêm logic kiểm tra và tạo bucket tự động
- Cải thiện thông báo lỗi chi tiết hơn
- Thêm logging để debug

### 3. Cấu hình bucket
- **Tên**: `avatars`
- **Public**: Yes
- **Allowed MIME types**: `image/png`, `image/jpeg`, `image/gif`, `image/webp`
- **File size limit**: 5MB

## 🧪 Kiểm tra

### 1. Test API endpoint
```bash
# Test với token hợp lệ
curl -X POST http://localhost:3131/api/profile/avatar \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "avatar=@path/to/image.jpg"
```

### 2. Test script
```bash
node scripts/test-avatar-upload.js
```

## 🔧 Troubleshooting

### Nếu vẫn gặp lỗi "Bucket not found":

1. **Kiểm tra Supabase Dashboard**:
   - Vào Storage section
   - Đảm bảo bucket `avatars` tồn tại
   - Kiểm tra bucket có public không

2. **Kiểm tra Service Role Key**:
   - Đảm bảo `SUPABASE_SERVICE_ROLE_KEY` trong `.env` đúng
   - Key phải có quyền Storage

3. **Kiểm tra RLS Policies**:
   - Vào Authentication > Policies
   - Đảm bảo có policy cho `storage.objects`

4. **Tạo bucket thủ công**:
   - Supabase Dashboard > Storage > New bucket
   - Name: `avatars`
   - Public: Yes
   - Allowed MIME types: `image/png, image/jpeg, image/gif, image/webp`

## 📋 Cấu hình bucket chuẩn

```javascript
{
  name: 'avatars',
  public: true,
  allowedMimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
  fileSizeLimit: 5242880 // 5MB
}
```

## 🎯 Kết quả mong đợi

Sau khi khắc phục, API upload avatar sẽ:
- ✅ Tự động tạo bucket nếu chưa có
- ✅ Xử lý ảnh với Sharp (resize 300x300, quality 90%)
- ✅ Upload lên Supabase Storage
- ✅ Cập nhật avatar_url trong database
- ✅ Trả về public URL của avatar

## 📝 Logs để debug

Khi upload thành công, bạn sẽ thấy logs:
```
✅ Avatars bucket exists
📤 Uploading avatar to: avatars/userId/avatar-timestamp.jpeg
✅ Avatar uploaded successfully
```

Khi có lỗi, logs sẽ hiển thị chi tiết lỗi để debug.
