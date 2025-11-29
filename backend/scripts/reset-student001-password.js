const { supabase } = require('../src/services/supabaseClient');
const { hashPassword } = require('../src/utils/passwordUtils');

async function resetPassword() {
  console.log('🔧 Resetting password for student001...\n');
  
  try {
    const username = 'student001';
    const newPassword = '123456';
    
    console.log(`📋 Step 1: Finding user ${username}...`);
    
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, username, email, role')
      .eq('username', username)
      .eq('role', 'student')
      .single();
    
    if (userError || !user) {
      console.error('❌ User not found:', userError?.message || 'User does not exist');
      return;
    }
    
    console.log(`✅ User found: ${user.username} (${user.email})`);
    
    console.log(`\n📋 Step 2: Hashing new password...`);
    const { hash: passwordHash, salt } = await hashPassword(newPassword, 12);
    
    console.log(`✅ Password hashed successfully`);
    console.log(`   Hash: ${passwordHash.substring(0, 30)}...`);
    console.log(`   Salt: ${salt}`);
    
    console.log(`\n📋 Step 3: Updating password in database...`);
    const { data: updatedUser, error: updateError } = await supabase
      .from('users')
      .update({ 
        password_hash: passwordHash,
        salt: salt,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id)
      .select('id, username, email, role')
      .single();
    
    if (updateError) {
      console.error('❌ Failed to update password:', updateError.message);
      return;
    }
    
    console.log(`✅ Password updated successfully!`);
    console.log(`\n📝 Summary:`);
    console.log(`   Username: ${updatedUser.username}`);
    console.log(`   Email: ${updatedUser.email}`);
    console.log(`   New Password: ${newPassword}`);
    console.log(`\n✅ Reset completed!`);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

if (require.main === module) {
  resetPassword()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { resetPassword };

