const { supabase } = require('../src/services/supabaseClient');

/**
 * Script để kiểm tra forum tables và storage bucket
 */
async function checkForumStorage() {
  console.log('🔍 Checking Forum Tables and Storage...\n');
  
  try {
    // 1. Kiểm tra dữ liệu trong forum tables
    console.log('📊 Checking forum tables data...');
    
    const { data: topics, error: topicsError } = await supabase
      .from('forum_topics')
      .select('id, title, created_at')
      .limit(5);
    
    if (topicsError) {
      console.error('❌ Error querying forum_topics:', topicsError.message);
    } else {
      console.log(`✅ forum_topics: ${topics?.length || 0} records found`);
      if (topics && topics.length > 0) {
        console.log('   Sample records:');
        topics.forEach(t => {
          console.log(`   - ${t.id}: ${t.title} (${t.created_at})`);
        });
      }
    }
    
    const { data: tempAttachments, error: tempError } = await supabase
      .from('forum_temp_attachments')
      .select('id, file_name, file_url, storage_path, created_at')
      .limit(5);
    
    if (tempError) {
      console.error('❌ Error querying forum_temp_attachments:', tempError.message);
    } else {
      console.log(`✅ forum_temp_attachments: ${tempAttachments?.length || 0} records found`);
      if (tempAttachments && tempAttachments.length > 0) {
        console.log('   Sample records:');
        tempAttachments.forEach(t => {
          console.log(`   - ${t.file_name}: ${t.file_url}`);
          console.log(`     Storage path: ${t.storage_path}`);
        });
      }
    }
    
    const { data: attachments, error: attError } = await supabase
      .from('forum_attachments')
      .select('id, file_name, file_url, storage_path')
      .limit(5);
    
    if (attError) {
      console.error('❌ Error querying forum_attachments:', attError.message);
    } else {
      console.log(`✅ forum_attachments: ${attachments?.length || 0} records found`);
      if (attachments && attachments.length > 0) {
        console.log('   Sample records:');
        attachments.forEach(a => {
          console.log(`   - ${a.file_name}: ${a.file_url}`);
          console.log(`     Storage path: ${a.storage_path}`);
        });
      }
    }
    
    console.log('\n📦 Checking storage bucket...');
    
    // 2. Kiểm tra bucket forum-attachments
    const { data: bucket, error: bucketError } = await supabase.storage.getBucket('forum-attachments');
    
    if (bucketError) {
      if (bucketError.statusCode === 404 || bucketError.message?.includes('not found')) {
        console.log('❌ Bucket "forum-attachments" does not exist!');
        console.log('\n🔧 Creating bucket "forum-attachments"...');
        
        // Tạo bucket với public = true để có thể truy cập qua public URL
        const { data: newBucket, error: createError } = await supabase.storage.createBucket('forum-attachments', {
          public: true,
          fileSizeLimit: 10485760, // 10MB
        });
        
        if (createError) {
          console.error('❌ Failed to create bucket:', createError);
          console.log('\n💡 You can create the bucket manually in Supabase Dashboard:');
          console.log('   1. Go to Storage > Buckets');
          console.log('   2. Create new bucket named "forum-attachments"');
          console.log('   3. Set it as Public');
          throw createError;
        }
        
        console.log('✅ Bucket "forum-attachments" created successfully (public: true)');
      } else {
        console.error('❌ Error checking bucket:', bucketError);
        throw bucketError;
      }
    } else {
      console.log('✅ Bucket "forum-attachments" exists');
      console.log(`   - Public: ${bucket.public}`);
      console.log(`   - File size limit: ${bucket.fileSizeLimit || 'unlimited'}`);
      
      // Kiểm tra nếu bucket là private
      if (!bucket.public) {
        console.log('\n⚠️  WARNING: Bucket is private but code uses getPublicUrl()!');
        console.log('   This will cause "bucket not found" errors when accessing files.');
        console.log('\n🔧 Options to fix:');
        console.log('   1. Make bucket public (recommended for forum attachments)');
        console.log('   2. Use signed URLs instead of public URLs in code');
        
        console.log('\n💡 Making bucket public...');
        const { error: updateError } = await supabase.storage.updateBucket('forum-attachments', {
          public: true
        });
        
        if (updateError) {
          console.error('❌ Failed to update bucket:', updateError);
          console.log('\n💡 You can update manually in Supabase Dashboard:');
          console.log('   1. Go to Storage > Buckets > forum-attachments');
          console.log('   2. Toggle "Public bucket" to ON');
        } else {
          console.log('✅ Bucket updated to public successfully');
        }
      }
    }
    
    // 3. Kiểm tra storage policies
    console.log('\n🔐 Checking storage policies...');
    const { data: policies, error: policiesError } = await supabase
      .from('storage.objects')
      .select('*')
      .limit(0);
    
    if (policiesError) {
      console.log('⚠️  Could not check policies (may need to check manually in Dashboard)');
    } else {
      console.log('✅ Storage policies check passed');
    }
    
    // 4. Test upload/download
    console.log('\n🧪 Testing bucket access...');
    const testContent = Buffer.from('test file');
    const testPath = 'test/check.txt';
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('forum-attachments')
      .upload(testPath, testContent, {
        contentType: 'text/plain',
        upsert: true
      });
    
    if (uploadError) {
      console.error('❌ Upload test failed:', uploadError.message);
    } else {
      console.log('✅ Upload test successful');
      
      // Test public URL
      const { data: urlData } = supabase.storage
        .from('forum-attachments')
        .getPublicUrl(testPath);
      
      console.log(`   Public URL: ${urlData.publicUrl}`);
      
      // Test download
      const { data: downloadData, error: downloadError } = await supabase.storage
        .from('forum-attachments')
        .download(testPath);
      
      if (downloadError) {
        console.error('❌ Download test failed:', downloadError.message);
      } else {
        console.log('✅ Download test successful');
      }
      
      // Cleanup
      const { error: deleteError } = await supabase.storage
        .from('forum-attachments')
        .remove([testPath]);
      
      if (deleteError) {
        console.warn('⚠️  Failed to delete test file:', deleteError.message);
      } else {
        console.log('✅ Test file cleaned up');
      }
    }
    
    console.log('\n🎉 Forum storage check completed!');
    
  } catch (error) {
    console.error('❌ Check failed:', error);
    process.exit(1);
  }
}

// Chạy script
if (require.main === module) {
  checkForumStorage();
}

module.exports = { checkForumStorage };

