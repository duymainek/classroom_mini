const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Validate required environment variables
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`);
  }
}

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Create Supabase client with service role key for admin operations
const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  },
  db: {
    schema: 'public'
  }
});

// Test connection function
async function testConnection() {
  try {
    const { data, error } = await supabase.from('users').select('count').limit(1);
    if (error) {
      console.error('Supabase connection test failed:', error.message);
      return false;
    }
    console.log('✅ Supabase connection successful');
    return true;
  } catch (error) {
    console.error('Supabase connection test error:', error.message);
    return false;
  }
}

// Initialize admin user if not exists
async function initializeAdminUser() {
  try {
    const adminUsername = process.env.ADMIN_USERNAME || 'admin';
    const adminPassword = process.env.ADMIN_PASSWORD || 'admin';
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@classroom.mini';
    const adminFullName = process.env.ADMIN_FULL_NAME || 'System Administrator';

    // Check if admin user already exists
    const { data: existingAdmin, error: checkError } = await supabase
      .from('users')
      .select('id')
      .eq('username', adminUsername)
      .eq('role', 'instructor')
      .single();

    if (checkError && checkError.code !== 'PGRST116') {
      throw checkError;
    }

    if (existingAdmin) {
      console.log('✅ Admin user already exists');
      return;
    }

    // Create admin user
    const bcrypt = require('bcrypt');
    const salt = await bcrypt.genSalt(12);
    const passwordHash = await bcrypt.hash(adminPassword, salt);

    const { data: newAdmin, error: createError } = await supabase
      .from('users')
      .insert({
        username: adminUsername,
        email: adminEmail,
        password_hash: passwordHash,
        salt: salt,
        full_name: adminFullName,
        role: 'instructor',
        is_active: true
      })
      .select()
      .single();

    if (createError) {
      throw createError;
    }

    console.log('✅ Admin user created successfully:', newAdmin.username);
  } catch (error) {
    console.error('❌ Failed to initialize admin user:', error.message);
  }
}

module.exports = {
  supabase,
  testConnection,
  initializeAdminUser
};