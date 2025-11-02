const { supabase } = require('./supabaseClient');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

/**
 * File Upload Service
 * Handles file uploads to Supabase Storage
 */
class FileUploadService {
  constructor() {
    this.bucketName = 'assignment-attachments';
  }

  /**
   * Sanitize filename for storage keys
   * @param {string} filename - Original filename
   * @returns {string} Sanitized filename
   */
  sanitizeFilename(filename) {
    if (!filename) return 'unnamed_file';
    
    const sanitized = filename
      .replace(/[[\]{}]/g, '_') // Replace square and curly brackets
      .replace(/\s+/g, '_') // Replace spaces with underscores
      .replace(/[#<>:"/\\|?*]/g, '_') // Replace other problematic characters
      .replace(/_{2,}/g, '_') // Replace multiple underscores with single
      .replace(/^_+|_+$/g, '') // Remove leading/trailing underscores
      .substring(0, 100) // Limit length to 100 chars
      || 'unnamed_file'; // Fallback if everything was replaced
    
    return sanitized;
  }

  /**
   * Upload file to Supabase Storage
   * @param {Buffer} fileBuffer - File buffer
   * @param {string} fileName - Original file name
   * @param {string} fileType - MIME type
   * @param {string} userId - User ID for folder organization
   * @param {string} assignmentId - Assignment ID for folder organization
   * @returns {Promise<{fileUrl: string, fileName: string, fileSize: number}>}
   */
  async uploadFile(fileBuffer, fileName, fileType, userId, assignmentId) {
    try {
      // Sanitize and generate unique filename
      const sanitizedName = this.sanitizeFilename(fileName);
      const fileExtension = path.extname(sanitizedName);
      const uniqueFileName = `${uuidv4()}${fileExtension}`;
      
      // Create file path: assignments/{assignmentId}/{userId}/{uniqueFileName}
      const filePath = `assignments/${assignmentId}/${userId}/${uniqueFileName}`;

      console.log('Uploading file:', { 
        original: fileName, 
        sanitized: sanitizedName, 
        unique: uniqueFileName,
        path: filePath 
      });

      // Upload file to Supabase Storage
      const { data, error } = await supabase.storage
        .from(this.bucketName)
        .upload(filePath, fileBuffer, {
          contentType: fileType,
          duplex: 'half'
        });

      if (error) {
        console.error('Supabase storage upload error:', error);
        throw new Error(`Failed to upload file: ${error.message}`);
      }

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from(this.bucketName)
        .getPublicUrl(filePath);

      return {
        fileUrl: publicUrl,
        fileName: fileName, // Keep original name for display
        filePath: filePath, // Store internal path for deletion
        fileSize: fileBuffer.length,
        fileType: fileType
      };
    } catch (error) {
      console.error('File upload service error:', error);
      throw error;
    }
  }

  /**
   * Upload temporary file to Supabase Storage
   * @param {Buffer} fileBuffer - File buffer
   * @param {string} tempPath - Temporary file path
   * @param {string} fileType - MIME type
   * @returns {Promise<{publicUrl: string, filePath: string}>}
   */
  async uploadTempFile(fileBuffer, tempPath, fileType) {
    try {
      console.log('Uploading temp file:', { tempPath, fileType, bufferSize: fileBuffer.length });

      // Upload file to Supabase Storage
      const { data, error } = await supabase.storage
        .from(this.bucketName)
        .upload(tempPath, fileBuffer, {
          contentType: fileType,
          duplex: 'half'
        });

      if (error) {
        console.error('Supabase storage upload error:', error);
        throw new Error(`Failed to upload temp file: ${error.message}`);
      }

      console.log('Supabase upload successful:', data);

      // Get public URL
      const { data: urlData } = supabase.storage
        .from(this.bucketName)
        .getPublicUrl(tempPath);

      console.log('Public URL generated:', urlData.publicUrl);

      return {
        publicUrl: urlData.publicUrl,
        filePath: tempPath,
        url: urlData.publicUrl, // Alias for compatibility
      };
    } catch (error) {
      console.error('Temp file upload service error:', error);
      throw error;
    }
  }

  /**
   * Upload multiple files
   * @param {Array} files - Array of file objects {buffer, fileName, fileType}
   * @param {string} userId - User ID
   * @param {string} assignmentId - Assignment ID
   * @returns {Promise<Array>} Array of upload results
   */
  async uploadMultipleFiles(files, userId, assignmentId) {
    const uploadPromises = files.map(file =>
      this.uploadFile(file.buffer, file.fileName, file.fileType, userId, assignmentId)
    );

    try {
      return await Promise.all(uploadPromises);
    } catch (error) {
      console.error('Multiple file upload error:', error);
      throw new Error('Failed to upload one or more files');
    }
  }

  /**
   * Delete file from Supabase Storage
   * @param {string} filePath - File path in storage
   * @returns {Promise<boolean>}
   */
  async deleteFile(filePath) {
    try {
      const { error } = await supabase.storage
        .from(this.bucketName)
        .remove([filePath]);

      if (error) {
        console.error('File deletion error:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('File deletion service error:', error);
      return false;
    }
  }

  /**
   * Delete multiple files
   * @param {Array<string>} filePaths - Array of file paths
   * @returns {Promise<{success: number, failed: number}>}
   */
  async deleteMultipleFiles(filePaths) {
    let success = 0;
    let failed = 0;

    for (const filePath of filePaths) {
      const deleted = await this.deleteFile(filePath);
      if (deleted) {
        success++;
      } else {
        failed++;
      }
    }

    return { success, failed };
  }

  /**
   * Validate file before upload
   * @param {Object} file - File object
   * @param {Array<string>} allowedTypes - Allowed file types
   * @param {number} maxSize - Max file size in bytes
   * @returns {boolean|string} True if valid, error message if invalid
   */
  validateFile(file, allowedTypes = [], maxSize = 10 * 1024 * 1024) {
    // Check file size
    if (file.size > maxSize) {
      return `File size exceeds maximum allowed size of ${maxSize / (1024 * 1024)}MB`;
    }

    // Check file type if restrictions are set
    if (allowedTypes.length > 0) {
      const fileExtension = path.extname(file.fileName).toLowerCase().slice(1);
      if (!allowedTypes.includes(fileExtension)) {
        return `File type not allowed. Allowed types: ${allowedTypes.join(', ')}`;
      }
    }

    return true;
  }

  /**
   * Move file from temporary to permanent location
   * @param {string} sourcePath - Source file path
   * @param {string} destinationPath - Destination file path
   * @returns {Promise<{success: boolean, publicUrl?: string, error?: string}>}
   */
  async moveFile(sourcePath, destinationPath) {
    try {
      console.log('Moving file:', { sourcePath, destinationPath });

      // Download file from source
      const { data: sourceData, error: downloadError } = await supabase.storage
        .from(this.bucketName)
        .download(sourcePath);

      if (downloadError) {
        console.error('Download source file error:', downloadError);
        return { success: false, error: `Failed to download source file: ${downloadError.message}` };
      }

      // Upload to destination
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from(this.bucketName)
        .upload(destinationPath, sourceData, {
          contentType: 'application/octet-stream',
          duplex: 'half'
        });

      if (uploadError) {
        console.error('Upload destination file error:', uploadError);
        return { success: false, error: `Failed to upload to destination: ${uploadError.message}` };
      }

      // Get public URL for destination
      const { data: { publicUrl } } = supabase.storage
        .from(this.bucketName)
        .getPublicUrl(destinationPath);

      // Delete source file
      await this.deleteFile(sourcePath);

      console.log('File moved successfully:', { sourcePath, destinationPath, publicUrl });

      return {
        success: true,
        publicUrl: publicUrl,
        filePath: destinationPath
      };
    } catch (error) {
      console.error('Move file service error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get file info from storage
   * @param {string} filePath - File path in storage
   * @returns {Promise<Object|null>}
   */
  async getFileInfo(filePath) {
    try {
      const { data, error } = await supabase.storage
        .from(this.bucketName)
        .list(path.dirname(filePath), {
          search: path.basename(filePath)
        });

      if (error || !data || data.length === 0) {
        return null;
      }

      return data[0];
    } catch (error) {
      console.error('Get file info error:', error);
      return null;
    }
  }
}

module.exports = new FileUploadService();