const { supabase } = require('../src/services/supabaseClient');

/**
 * Script để thiết lập Supabase Storage bucket cho avatars
 */
async function setupStorage() {
  console.log('🔧 Setting up Supabase Storage...');
  
  try {
    // Kiểm tra bucket avatars có tồn tại không
    console.log('📋 Checking if avatars bucket exists...');
    const { data: bucket, error: bucketError } = await supabase.storage.getBucket('avatars');
    
    if (bucketError && bucketError.statusCode === 404) {
      console.log('❌ Bucket "avatars" not found. Creating...');
      
      // Tạo bucket avatars
      const { data: newBucket, error: createError } = await supabase.storage.createBucket('avatars', {
        public: true,
        allowedMimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
        fileSizeLimit: 5242880, // 5MB
      });
      
      if (createError) {
        console.error('❌ Failed to create bucket:', createError);
        throw createError;
      }
      
      console.log('✅ Bucket "avatars" created successfully');
    } else if (bucketError) {
      console.error('❌ Error checking bucket:', bucketError);
      throw bucketError;
    } else {
      console.log('✅ Bucket "avatars" already exists');
    }
    
    // Kiểm tra quyền truy cập bucket
    console.log('🔐 Testing bucket access...');
    const { data: buckets, error: listError } = await supabase.storage.listBuckets();
    
    if (listError) {
      console.error('❌ Failed to list buckets:', listError);
      throw listError;
    }
    
    console.log('📦 Available buckets:', buckets.map(b => b.name));
    
    // Test upload một file nhỏ để kiểm tra quyền
    console.log('🧪 Testing upload permissions...');
    const testContent = Buffer.from('test');
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('avatars')
      .upload('test/test.txt', testContent, {
        contentType: 'text/plain',
        upsert: true
      });
    
    if (uploadError) {
      console.error('❌ Upload test failed:', uploadError);
      throw uploadError;
    }
    
    console.log('✅ Upload test successful');
    
    // Xóa file test
    const { error: deleteError } = await supabase.storage
      .from('avatars')
      .remove(['test/test.txt']);
    
    if (deleteError) {
      console.warn('⚠️ Failed to delete test file:', deleteError);
    } else {
      console.log('✅ Test file cleaned up');
    }
    
    console.log('🎉 Storage setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Storage setup failed:', error);
    console.log('\n🔧 Troubleshooting steps:');
    console.log('1. Check your SUPABASE_SERVICE_ROLE_KEY in .env file');
    console.log('2. Ensure the service role key has Storage permissions');
    console.log('3. Go to Supabase Dashboard > Storage and create bucket manually if needed');
    console.log('4. Check RLS policies for storage.objects table');
    process.exit(1);
  }
}

// Chạy script
if (require.main === module) {
  setupStorage();
}

module.exports = { setupStorage };
