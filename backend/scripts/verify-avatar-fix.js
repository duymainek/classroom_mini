/**
 * Script để verify rằng avatar upload đã được fix
 */
const { supabase } = require('../src/services/supabaseClient');

async function verifyAvatarFix() {
  console.log('🔍 Verifying avatar upload fix...');
  
  try {
    // 1. Kiểm tra bucket avatars có tồn tại không
    console.log('📋 Step 1: Checking avatars bucket...');
    const { data: bucket, error: bucketError } = await supabase.storage.getBucket('avatars');
    
    if (bucketError) {
      console.error('❌ Bucket check failed:', bucketError);
      return false;
    }
    
    console.log('✅ Avatars bucket exists:', bucket.name);
    
    // 2. Kiểm tra bucket có public không
    console.log('📋 Step 2: Checking bucket configuration...');
    const { data: buckets, error: listError } = await supabase.storage.listBuckets();
    
    if (listError) {
      console.error('❌ Failed to list buckets:', listError);
      return false;
    }
    
    const avatarsBucket = buckets.find(b => b.name === 'avatars');
    if (!avatarsBucket) {
      console.error('❌ Avatars bucket not found in bucket list');
      return false;
    }
    
    console.log('✅ Bucket configuration:', {
      name: avatarsBucket.name,
      public: avatarsBucket.public,
      allowedMimeTypes: avatarsBucket.allowedMimeTypes,
      fileSizeLimit: avatarsBucket.fileSizeLimit
    });
    
    // 3. Test upload một file ảnh nhỏ
    console.log('📋 Step 3: Testing image upload...');
    const testImageBuffer = Buffer.from([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, // color type, compression, filter, interlace
      0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
      0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82 // IEND chunk
    ]);
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('avatars')
      .upload('test/verify-fix.png', testImageBuffer, {
        contentType: 'image/png',
        upsert: true
      });
    
    if (uploadError) {
      console.error('❌ Upload test failed:', uploadError);
      return false;
    }
    
    console.log('✅ Upload test successful:', uploadData.path);
    
    // 4. Test lấy public URL
    console.log('📋 Step 4: Testing public URL...');
    const { data: urlData } = supabase.storage
      .from('avatars')
      .getPublicUrl('test/verify-fix.png');
    
    console.log('✅ Public URL generated:', urlData.publicUrl);
    
    // 5. Cleanup test file
    console.log('📋 Step 5: Cleaning up test file...');
    const { error: deleteError } = await supabase.storage
      .from('avatars')
      .remove(['test/verify-fix.png']);
    
    if (deleteError) {
      console.warn('⚠️ Failed to delete test file:', deleteError);
    } else {
      console.log('✅ Test file cleaned up');
    }
    
    console.log('🎉 Avatar upload fix verification completed successfully!');
    console.log('✅ All systems are ready for avatar uploads');
    
    return true;
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
    return false;
  }
}

// Chạy verification
if (require.main === module) {
  verifyAvatarFix().then(success => {
    if (success) {
      console.log('\n🎯 Next steps:');
      console.log('1. Test the API with a real authentication token');
      console.log('2. Upload an avatar from your Flutter app');
      console.log('3. Check that the avatar appears in your profile');
    } else {
      console.log('\n🔧 Troubleshooting:');
      console.log('1. Check your Supabase configuration');
      console.log('2. Ensure the avatars bucket exists and is public');
      console.log('3. Verify your service role key has storage permissions');
      process.exit(1);
    }
  });
}

module.exports = { verifyAvatarFix };
