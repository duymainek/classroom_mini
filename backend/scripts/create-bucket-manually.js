/**
 * Script để tạo bucket avatars thủ công
 * Chạy script này nếu bucket chưa được tạo tự động
 */

const { supabase } = require('../src/services/supabaseClient');

async function createBucketManually() {
  console.log('🔧 Creating avatars bucket manually...');
  
  try {
    // Tạo bucket avatars với cấu hình đầy đủ
    const { data, error } = await supabase.storage.createBucket('avatars', {
      public: true,
      allowedMimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
      fileSizeLimit: 5242880, // 5MB
    });
    
    if (error) {
      console.error('❌ Failed to create bucket:', error);
      console.log('\n🔧 Manual steps to create bucket:');
      console.log('1. Go to your Supabase Dashboard');
      console.log('2. Navigate to Storage section');
      console.log('3. Click "New bucket"');
      console.log('4. Name: "avatars"');
      console.log('5. Make it public: Yes');
      console.log('6. Allowed MIME types: image/png, image/jpeg, image/gif, image/webp');
      console.log('7. File size limit: 5MB');
      console.log('8. Click "Create bucket"');
      return false;
    }
    
    console.log('✅ Bucket "avatars" created successfully!');
    console.log('📋 Bucket details:', data);
    
    // Test upload để đảm bảo bucket hoạt động
    console.log('🧪 Testing bucket functionality...');
    const testContent = Buffer.from('test');
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('avatars')
      .upload('test/test.txt', testContent, {
        contentType: 'text/plain',
        upsert: true
      });
    
    if (uploadError) {
      console.error('❌ Upload test failed:', uploadError);
      return false;
    }
    
    console.log('✅ Upload test successful');
    
    // Cleanup test file
    const { error: deleteError } = await supabase.storage
      .from('avatars')
      .remove(['test/test.txt']);
    
    if (deleteError) {
      console.warn('⚠️ Failed to delete test file:', deleteError);
    } else {
      console.log('✅ Test file cleaned up');
    }
    
    console.log('🎉 Bucket setup completed successfully!');
    return true;
    
  } catch (error) {
    console.error('❌ Unexpected error:', error);
    return false;
  }
}

// Chạy script
if (require.main === module) {
  createBucketManually().then(success => {
    if (!success) {
      process.exit(1);
    }
  });
}

module.exports = { createBucketManually };
