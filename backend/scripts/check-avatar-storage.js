const { supabase } = require('../src/services/supabaseClient');

async function checkAvatarStorage() {
  console.log('🔍 Checking Avatar Storage...\n');
  
  try {
    const userId = '5e025bd4-e941-4514-b8de-4743b4b9800b';
    
    console.log('📋 Step 1: Checking avatars bucket...');
    const { data: bucket, error: bucketError } = await supabase.storage.getBucket('avatars');
    
    if (bucketError) {
      console.error('❌ Bucket check failed:', bucketError);
      return;
    }
    
    console.log('✅ Avatars bucket exists:', bucket.name);
    console.log('   Public:', bucket.public);
    
    console.log('\n📋 Step 2: Listing files in bucket...');
    const { data: files, error: listError } = await supabase.storage
      .from('avatars')
      .list('', {
        limit: 100,
        offset: 0,
        sortBy: { column: 'created_at', order: 'desc' }
      });
    
    if (listError) {
      console.error('❌ Failed to list files:', listError);
      return;
    }
    
    console.log(`✅ Found ${files?.length || 0} items in root`);
    
    if (files && files.length > 0) {
      console.log('\n📁 Root items:');
      files.forEach(item => {
        console.log(`   - ${item.name} (${item.id ? 'file' : 'folder'})`);
      });
    }
    
    console.log(`\n📋 Step 3: Checking files for user ${userId}...`);
    
    const pathsToCheck = [
      `avatars/${userId}`,  // Path sai (có prefix avatars/)
      `${userId}`,          // Path đúng
    ];
    
    for (const checkPath of pathsToCheck) {
      console.log(`\n   Checking path: ${checkPath}`);
      const { data: userFiles, error: userFilesError } = await supabase.storage
        .from('avatars')
        .list(checkPath, {
          limit: 100
        });
      
      if (userFilesError) {
        if (userFilesError.statusCode === 404) {
          console.log(`   ⚠️  Path not found: ${checkPath}`);
        } else {
          console.error(`   ❌ Error: ${userFilesError.message}`);
        }
      } else {
        console.log(`   ✅ Found ${userFiles?.length || 0} files:`);
        if (userFiles && userFiles.length > 0) {
          userFiles.forEach(file => {
            const fullPath = `${checkPath}/${file.name}`;
            const { data: urlData } = supabase.storage
              .from('avatars')
              .getPublicUrl(fullPath);
            console.log(`      - ${file.name}`);
            console.log(`        URL: ${urlData.publicUrl}`);
            console.log(`        Size: ${file.metadata?.size || 'unknown'} bytes`);
            console.log(`        Created: ${file.created_at}`);
          });
        }
      }
    }
    
    console.log('\n📋 Step 4: Checking database avatar URLs...');
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, username, avatar_url')
      .eq('id', userId)
      .limit(1);
    
    if (usersError) {
      console.error('❌ Failed to query users:', usersError);
    } else if (users && users.length > 0) {
      const user = users[0];
      console.log(`✅ User found: ${user.username}`);
      console.log(`   Avatar URL: ${user.avatar_url || 'null'}`);
      
      if (user.avatar_url) {
        const url = new URL(user.avatar_url);
        const pathParts = url.pathname.split('/').filter(p => p);
        console.log(`   URL path parts: ${pathParts.join(' -> ')}`);
        
        if (pathParts.includes('avatars') && pathParts[pathParts.indexOf('avatars') + 1] === 'avatars') {
          console.log('   ⚠️  WARNING: URL has duplicate "avatars" in path!');
        }
      }
    } else {
      console.log('⚠️  User not found in database');
    }
    
    console.log('\n✅ Check completed!');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

if (require.main === module) {
  checkAvatarStorage()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { checkAvatarStorage };

