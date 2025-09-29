const { supabase } = require('../services/supabaseClient');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { validateProfileUpdate } = require('../utils/validators');
const multer = require('multer');
const sharp = require('sharp');

// Multer config for avatar upload
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
      cb(new AppError('Only image files are allowed', 400, 'INVALID_FILE_TYPE'), false);
    }
  }
});

class ProfileController {
  /**
   * Get current user's profile
   */
  getProfile = catchAsync(async (req, res) => {
    const userId = req.user.id;

    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, email, full_name, role, avatar_url, is_active, last_login_at, created_at, updated_at')
      .eq('id', userId)
      .single();

    if (error) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    res.json({
      success: true,
      data: { user },
    });
  });

  /**
   * Update current user's profile
   */
  updateProfile = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { full_name, email } = req.body;

    const { isValid, errors, data } = validateProfileUpdate({ full_name, email });
    if (!isValid) {
      return res.status(400).json({ success: false, message: 'Validation failed', errors });
    }

    // Check for email uniqueness if it's being changed
    if (data.email) {
      const { data: existingUser, error } = await supabase
        .from('users')
        .select('id')
        .eq('email', data.email)
        .neq('id', userId)
        .single();

      if (error && error.code !== 'PGRST116') throw error;
      if (existingUser) {
        throw new AppError('Email already in use', 409, 'EMAIL_IN_USE');
      }
    }

    const { data: updatedUser, error: updateError } = await supabase
      .from('users')
      .update({ ...data, updated_at: new Date() })
      .eq('id', userId)
      .select('id, username, email, full_name, role, avatar_url, is_active, last_login_at, created_at, updated_at')
      .single();

    if (updateError) {
      throw new AppError('Failed to update profile', 500, 'PROFILE_UPDATE_FAILED');
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user: updatedUser },
    });
  });

  /**
   * Upload user avatar
   */
  uploadAvatar = catchAsync(async (req, res) => {
    const userId = req.user.id;

    if (!req.file) {
      throw new AppError('Avatar file is required', 400, 'AVATAR_REQUIRED');
    }

    // Ensure the 'avatars' bucket exists and is public
    try {
      // Kiểm tra bucket có tồn tại không
      const { error: bucketError } = await supabase.storage.getBucket('avatars');

      if (bucketError) {
        console.log('Bucket check error:', bucketError);
        
        // Nếu bucket không tồn tại, thử tạo bucket
        if (bucketError.statusCode === 404 || bucketError.message?.includes('not found')) {
          console.log('Creating avatars bucket...');
          const { error: createBucketError } = await supabase.storage.createBucket('avatars', {
            public: true,
            allowedMimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
            fileSizeLimit: 5242880, // 5MB
          });
          
          if (createBucketError) {
            console.error('Supabase create bucket error:', createBucketError);
            throw new AppError('Failed to create avatars storage bucket. Please create the bucket manually in Supabase Dashboard > Storage', 500, 'BUCKET_CREATION_FAILED');
          }
          
          console.log('✅ Avatars bucket created successfully');
        } else {
          // Lỗi khác khi kiểm tra bucket
          console.error('Supabase bucket check error:', bucketError);
          throw new AppError(`Storage bucket error: ${bucketError.message}`, 500, 'BUCKET_VERIFICATION_FAILED');
        }
      } else {
        console.log('✅ Avatars bucket exists');
      }
    } catch (e) {
      console.error('Supabase bucket verification error:', e);
      throw new AppError(`Storage setup failed: ${e.message}. Please check your Supabase configuration and ensure the 'avatars' bucket exists in Storage.`, 500, 'BUCKET_VERIFICATION_FAILED');
    }

    // Process image with sharp
    const processedImage = await sharp(req.file.buffer)
      .resize(300, 300, { fit: 'cover' })
      .jpeg({ quality: 90 })
      .toBuffer();

    const fileName = `avatar-${userId}-${Date.now()}.jpeg`;
    const filePath = `avatars/${userId}/${fileName}`;

    // Upload to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(filePath, processedImage, {
        contentType: 'image/jpeg',
        upsert: true,
      });

    if (uploadError) {
      console.error("Supabase upload error:", uploadError);
      throw new AppError('Failed to upload avatar', 500, 'AVATAR_UPLOAD_FAILED');
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(filePath);

    const avatar_url = urlData.publicUrl;

    // Update user's avatar_url
    const { error: updateUserError } = await supabase
      .from('users')
      .update({ avatar_url, updated_at: new Date() })
      .eq('id', userId);

    if (updateUserError) {
      console.error("Supabase user update error:", updateUserError);
      throw new AppError('Failed to update user profile with new avatar', 500, 'AVATAR_UPDATE_FAILED');
    }

    res.json({
      success: true,
      message: 'Avatar uploaded successfully',
      data: { avatar_url },
    });
  });

  // Middleware for multer
  handleAvatarUpload = upload.single('avatar');
}

module.exports = new ProfileController();
