const { supabase } = require('../src/services/supabaseClient');

async function fixAvatarUrls() {
  console.log('🔧 Fixing Avatar URLs in Database...\n');
  
  try {
    console.log('📋 Step 1: Finding users with duplicate avatar paths...');
    
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, username, avatar_url')
      .not('avatar_url', 'is', null);
    
    if (usersError) {
      console.error('❌ Failed to query users:', usersError);
      return;
    }
    
    console.log(`✅ Found ${users?.length || 0} users with avatar URLs\n`);
    
    if (!users || users.length === 0) {
      console.log('⚠️  No users with avatar URLs found');
      return;
    }
    
    let fixedCount = 0;
    let notFoundCount = 0;
    
    for (const user of users) {
      if (!user.avatar_url) continue;
      
      const url = new URL(user.avatar_url);
      const pathParts = url.pathname.split('/').filter(p => p);
      
      const avatarsIndex = pathParts.indexOf('avatars');
      if (avatarsIndex === -1) continue;
      
      // Check for duplicate 'avatars' in path
      if (pathParts[avatarsIndex + 1] === 'avatars' || user.avatar_url.includes('/avatars/avatars/')) {
        console.log(`\n🔍 User: ${user.username} (${user.id})`);
        console.log(`   Old URL: ${user.avatar_url}`);
        
        // Fix duplicate path
        let fixedUrl = user.avatar_url.replace('/avatars/avatars/', '/avatars/');
        
        // Extract the correct file path from URL
        const urlObj = new URL(fixedUrl);
        const pathPartsFixed = urlObj.pathname.split('/').filter(p => p);
        const avatarsIdx = pathPartsFixed.indexOf('avatars');
        
        if (avatarsIdx === -1) {
          console.log(`   ⚠️  Invalid URL format, setting avatar_url to null`);
          const { error: updateError } = await supabase
            .from('users')
            .update({ avatar_url: null, updated_at: new Date() })
            .eq('id', user.id);
          
          if (updateError) {
            console.error(`   ❌ Failed to update: ${updateError.message}`);
          } else {
            notFoundCount++;
          }
          continue;
        }
        
        // Get file path after 'avatars' bucket name
        const filePath = pathPartsFixed.slice(avatarsIdx + 1).join('/');
        console.log(`   File path in storage: ${filePath}`);
        
        // Check if file exists by trying to get it
        const { data: fileData, error: fileError } = await supabase.storage
          .from('avatars')
          .download(filePath);
        
        if (fileError || !fileData) {
          console.log(`   ⚠️  File not found in storage (${fileError?.message || 'unknown error'}), setting avatar_url to null`);
          
          const { error: updateError } = await supabase
            .from('users')
            .update({ avatar_url: null, updated_at: new Date() })
            .eq('id', user.id);
          
          if (updateError) {
            console.error(`   ❌ Failed to update: ${updateError.message}`);
          } else {
            console.log(`   ✅ Updated: avatar_url set to null`);
            notFoundCount++;
          }
        } else {
          console.log(`   ✅ File exists, fixing URL...`);
          console.log(`   New URL: ${fixedUrl}`);
          
          const { error: updateError } = await supabase
            .from('users')
            .update({ avatar_url: fixedUrl, updated_at: new Date() })
            .eq('id', user.id);
          
          if (updateError) {
            console.error(`   ❌ Failed to update: ${updateError.message}`);
          } else {
            console.log(`   ✅ Updated successfully`);
            fixedCount++;
          }
        }
      }
    }
    
    console.log(`\n✅ Fix completed!`);
    console.log(`   Fixed URLs: ${fixedCount}`);
    console.log(`   Set to null (file not found): ${notFoundCount}`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

if (require.main === module) {
  fixAvatarUrls()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { fixAvatarUrls };

