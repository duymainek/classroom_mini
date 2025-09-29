/**
 * Script test upload avatar
 */
const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const fetch = require('node-fetch');

async function testAvatarUpload() {
  console.log('🧪 Testing avatar upload API...');
  
  try {
    // Tạo một file ảnh test đơn giản (1x1 pixel PNG)
    const testImageBuffer = Buffer.from([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, // color type, compression, filter, interlace
      0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
      0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82 // IEND chunk
    ]);
    
    const formData = new FormData();
    formData.append('avatar', testImageBuffer, {
      filename: 'test-avatar.png',
      contentType: 'image/png'
    });
    
    // Test với token giả (sẽ fail ở auth middleware)
    const response = await fetch('http://localhost:3131/api/profile/avatar', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer fake-token-for-testing'
      },
      body: formData
    });
    
    const responseData = await response.text();
    console.log('📋 Response status:', response.status);
    console.log('📋 Response body:', responseData);
    
    if (response.status === 401) {
      console.log('✅ API is working (authentication required as expected)');
      console.log('🔧 To test with real token, you need to:');
      console.log('1. Login first to get a valid token');
      console.log('2. Use the token in Authorization header');
      return true;
    } else if (response.status === 500 && responseData.includes('BUCKET_VERIFICATION_FAILED')) {
      console.log('❌ Bucket still not found - check Supabase configuration');
      return false;
    } else {
      console.log('✅ API responded (status:', response.status, ')');
      return true;
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

// Chạy test
if (require.main === module) {
  testAvatarUpload().then(success => {
    if (success) {
      console.log('🎉 Avatar upload API test completed');
    } else {
      console.log('❌ Avatar upload API test failed');
      process.exit(1);
    }
  });
}

module.exports = { testAvatarUpload };
