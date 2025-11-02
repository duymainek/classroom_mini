const { supabase } = require('./supabaseClient');
const fileUploadService = require('./fileUploadService');

/**
 * Cleanup Service
 * Handles cleanup of expired temporary files and database records
 */
class CleanupService {
  /**
   * Clean up expired temporary attachments
   * @returns {Promise<{deletedRecords: number, deletedFiles: number, errors: string[]}>}
   */
  async cleanupExpiredTempAttachments() {
    const errors = [];
    let deletedRecords = 0;
    let deletedFiles = 0;

    try {
      console.log('Starting cleanup of expired temp attachments...');

      // Get expired temp attachments
      const { data: expiredAttachments, error: fetchError } = await supabase
        .from('temp_attachments')
        .select('id, file_path, temp_id')
        .lt('expires_at', new Date().toISOString())
        .eq('is_finalized', false);

      if (fetchError) {
        console.error('Error fetching expired temp attachments:', fetchError);
        errors.push(`Database fetch error: ${fetchError.message}`);
        return { deletedRecords: 0, deletedFiles: 0, errors };
      }

      if (!expiredAttachments || expiredAttachments.length === 0) {
        console.log('No expired temp attachments found');
        return { deletedRecords: 0, deletedFiles: 0, errors: [] };
      }

      console.log(`Found ${expiredAttachments.length} expired temp attachments`);

      // Delete files from storage
      for (const attachment of expiredAttachments) {
        try {
          const fileDeleted = await fileUploadService.deleteFile(attachment.file_path);
          if (fileDeleted) {
            deletedFiles++;
            console.log(`Deleted file: ${attachment.file_path}`);
          } else {
            errors.push(`Failed to delete file: ${attachment.file_path}`);
          }
        } catch (error) {
          console.error(`Error deleting file ${attachment.file_path}:`, error);
          errors.push(`File deletion error for ${attachment.temp_id}: ${error.message}`);
        }
      }

      // Delete database records
      const { error: deleteError } = await supabase
        .from('temp_attachments')
        .delete()
        .lt('expires_at', new Date().toISOString())
        .eq('is_finalized', false);

      if (deleteError) {
        console.error('Error deleting expired temp attachment records:', deleteError);
        errors.push(`Database deletion error: ${deleteError.message}`);
      } else {
        deletedRecords = expiredAttachments.length;
        console.log(`Deleted ${deletedRecords} expired temp attachment records`);
      }

      console.log('Cleanup completed:', {
        deletedRecords,
        deletedFiles,
        errorCount: errors.length
      });

      return { deletedRecords, deletedFiles, errors };
    } catch (error) {
      console.error('Cleanup service error:', error);
      errors.push(`Service error: ${error.message}`);
      return { deletedRecords, deletedFiles, errors };
    }
  }

  /**
   * Clean up orphaned temp files (files in storage but no DB records)
   * @returns {Promise<{deletedFiles: number, errors: string[]}>}
   */
  async cleanupOrphanedTempFiles() {
    const errors = [];
    let deletedFiles = 0;

    try {
      console.log('Starting cleanup of orphaned temp files...');

      // This would require listing files in storage and checking against DB
      // For now, we'll implement a simpler approach by cleaning up old temp directories
      const cutoffDate = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago
      
      // Get all temp attachments older than cutoff
      const { data: oldAttachments, error: fetchError } = await supabase
        .from('temp_attachments')
        .select('id, file_path, created_at')
        .lt('created_at', cutoffDate.toISOString());

      if (fetchError) {
        console.error('Error fetching old temp attachments:', fetchError);
        errors.push(`Database fetch error: ${fetchError.message}`);
        return { deletedFiles: 0, errors };
      }

      if (!oldAttachments || oldAttachments.length === 0) {
        console.log('No old temp attachments found');
        return { deletedFiles: 0, errors: [] };
      }

      console.log(`Found ${oldAttachments.length} old temp attachments`);

      // Delete files that are older than cutoff and not finalized
      for (const attachment of oldAttachments) {
        try {
          const fileDeleted = await fileUploadService.deleteFile(attachment.file_path);
          if (fileDeleted) {
            deletedFiles++;
            console.log(`Deleted orphaned file: ${attachment.file_path}`);
          }
        } catch (error) {
          console.error(`Error deleting orphaned file ${attachment.file_path}:`, error);
          errors.push(`Orphaned file deletion error: ${error.message}`);
        }
      }

      console.log('Orphaned files cleanup completed:', {
        deletedFiles,
        errorCount: errors.length
      });

      return { deletedFiles, errors };
    } catch (error) {
      console.error('Orphaned files cleanup error:', error);
      errors.push(`Service error: ${error.message}`);
      return { deletedFiles, errors };
    }
  }

  /**
   * Run full cleanup process
   * @returns {Promise<Object>}
   */
  async runFullCleanup() {
    console.log('Starting full cleanup process...');
    
    const startTime = Date.now();
    const results = {
      expiredAttachments: await this.cleanupExpiredTempAttachments(),
      orphanedFiles: await this.cleanupOrphanedTempFiles(),
      duration: 0
    };
    
    results.duration = Date.now() - startTime;
    
    console.log('Full cleanup completed:', results);
    return results;
  }
}

module.exports = new CleanupService();
