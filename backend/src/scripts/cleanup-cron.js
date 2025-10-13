#!/usr/bin/env node

/**
 * Cleanup Cron Script
 * Run this script periodically to clean up expired temporary files
 * 
 * Usage:
 * - Manual: node src/scripts/cleanup-cron.js
 * - Cron: 0 * * * * cd /path/to/project && node src/scripts/cleanup-cron.js
 */

const cleanupService = require('../services/cleanupService');

async function runCleanup() {
  try {
    console.log('=== Cleanup Cron Started ===');
    console.log('Timestamp:', new Date().toISOString());
    
    const results = await cleanupService.runFullCleanup();
    
    console.log('=== Cleanup Results ===');
    console.log('Expired attachments:', results.expiredAttachments);
    console.log('Orphaned files:', results.orphanedFiles);
    console.log('Duration:', results.duration + 'ms');
    
    // Exit with appropriate code
    const hasErrors = results.expiredAttachments.errors.length > 0 || 
                     results.orphanedFiles.errors.length > 0;
    
    if (hasErrors) {
      console.error('Cleanup completed with errors');
      process.exit(1);
    } else {
      console.log('Cleanup completed successfully');
      process.exit(0);
    }
  } catch (error) {
    console.error('Cleanup cron failed:', error);
    process.exit(1);
  }
}

// Run cleanup if this script is executed directly
if (require.main === module) {
  runCleanup();
}

module.exports = { runCleanup };
