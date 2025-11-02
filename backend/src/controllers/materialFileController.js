const multer = require('multer');
const fileUploadService = require('../services/fileUploadService');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
const { supabase } = require('../services/supabaseClient');

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB max file size
    files: 10 // Max 10 files per request
  },
  fileFilter: (req, file, cb) => {
    // Basic file type validation (can be overridden by service)
    const allowedMimes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/zip',
      'application/x-rar-compressed'
    ];

    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new AppError(`File type ${file.mimetype} not allowed`, 400, 'INVALID_FILE_TYPE'), false);
    }
  }
});

class MaterialFileController {
  /**
   * Upload temporary attachment for material creation
   */
  uploadTempAttachment = [
    upload.single('file'), // Accept single file
    catchAsync(async (req, res) => {
      const userId = req.user.id;
      const file = req.file;

      if (!file) {
        throw new AppError('No file provided', 400, 'NO_FILE');
      }

      try {
        // Sanitize filename using the service method
        const sanitizedFileName = fileUploadService.sanitizeFilename(file.originalname);
        
        console.log('Material filename sanitization:', { 
          original: file.originalname, 
          sanitized: sanitizedFileName 
        });

        // Upload to temporary storage location
        const tempPath = `temp/materials/${userId}/${Date.now()}_${sanitizedFileName}`;
        const uploadResult = await fileUploadService.uploadTempFile(
          file.buffer,
          tempPath,
          file.mimetype
        );

        // Generate temporary attachment ID for frontend tracking
        const tempAttachmentId = `temp_material_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

        // Save to temp_attachments table
        console.log('=== SAVING TO TEMP_ATTACHMENTS TABLE (MATERIAL) ===');
        console.log('Temp ID:', tempAttachmentId);
        console.log('User ID:', userId);
        console.log('File name:', file.originalname);
        console.log('File path:', uploadResult.filePath);
        console.log('File size:', file.size);
        console.log('File type:', file.mimetype);

        const { data: tempAttachment, error: dbError } = await supabase
          .from('temp_attachments')
          .insert({
            temp_id: tempAttachmentId,
            user_id: userId,
            file_name: file.originalname,
            file_path: uploadResult.filePath,
            file_url: uploadResult.publicUrl,
            file_size: file.size,
            file_type: file.mimetype,
            attachment_type: 'material' // Distinguish from assignment/announcement attachments
          })
          .select('id, temp_id, file_name, file_url, file_size, file_type, created_at')
          .single();

        console.log('Database insert result:', { tempAttachment, dbError });

        if (dbError) {
          console.error('Database temp attachment save error:', dbError);
          // Try to clean up uploaded file
          await fileUploadService.deleteFile(uploadResult.filePath);
          throw new AppError('Failed to save temporary attachment', 500, 'DB_SAVE_FAILED');
        }

        console.log('Successfully saved to temp_attachments table');
        console.log('=== END SAVE TO TEMP_ATTACHMENTS (MATERIAL) ===');

        const response = buildResponse(true, 'File uploaded successfully', {
          attachmentId: tempAttachment.temp_id,
          fileName: tempAttachment.file_name,
          fileUrl: tempAttachment.file_url,
          fileSize: tempAttachment.file_size,
          fileType: tempAttachment.file_type,
          createdAt: tempAttachment.created_at
        });

        res.json(response);
      } catch (error) {
        console.error('Temp file upload error:', error);
        throw new AppError('Failed to upload file', 500, 'UPLOAD_FAILED');
      }
    })
  ];

  /**
   * Finalize temporary attachments for material
   */
  finalizeTempAttachments = catchAsync(async (req, res) => {
    const { materialId } = req.params;
    const { attachmentIds, tempAttachmentIds } = req.body;
    const userId = req.user.id;

    // Support both attachmentIds and tempAttachmentIds for backward compatibility
    const tempIds = attachmentIds || tempAttachmentIds;

    console.log('=== FINALIZE TEMP ATTACHMENTS METHOD DEBUG (MATERIAL) ===');
    console.log('Material ID:', materialId);
    console.log('User ID:', userId);
    console.log('Attachment IDs from client:', attachmentIds);
    console.log('Temp Attachment IDs (legacy):', tempAttachmentIds);
    console.log('Using temp IDs:', tempIds);

    if (!tempIds || !Array.isArray(tempIds) || tempIds.length === 0) {
      console.log('No temp attachment IDs provided');
      return res.status(400).json({
        success: false,
        message: 'No temporary attachment IDs provided',
        code: 'NO_TEMP_ATTACHMENTS'
      });
    }

    try {
      console.log('Fetching temp attachments from database...');
      // Get temp attachments for this user (including already finalized ones)
      const { data: tempAttachments, error: fetchError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', tempIds)
        .eq('user_id', userId);

      console.log('Database query result:', { tempAttachments, fetchError });

      if (fetchError) {
        console.error('Fetch temp attachments error:', fetchError);
        throw new AppError('Failed to fetch temporary attachments', 500, 'FETCH_TEMP_FAILED');
      }

      if (!tempAttachments || tempAttachments.length === 0) {
        console.log('No temp attachments found in database');
        return res.status(404).json({
          success: false,
          message: 'No valid temporary attachments found',
          code: 'TEMP_ATTACHMENTS_NOT_FOUND'
        });
      }

      // Check if attachments are already finalized
      const alreadyFinalized = tempAttachments.filter(ta => ta.is_finalized);
      if (alreadyFinalized.length > 0) {
        console.log('Some attachments already finalized:', alreadyFinalized.map(ta => ta.temp_id));
        // Return success if already finalized
        return res.json({
          success: true,
          message: 'Attachments already finalized',
          data: {
            attachments: alreadyFinalized.map(ta => ({
              id: ta.id,
              fileName: ta.file_name,
              fileUrl: ta.file_url,
              fileSize: ta.file_size,
              fileType: ta.file_type
            }))
          }
        });
      }

      console.log(`Found ${tempAttachments.length} temp attachments to finalize`);

      // Move files from temp to permanent location and create material attachments
      const finalAttachments = [];
      const errors = [];

      for (const tempAttachment of tempAttachments) {
        try {
          // Move file from temp to permanent location
          const sanitizedName = fileUploadService.sanitizeFilename(tempAttachment.file_name);
          const permanentPath = `materials/${materialId}/${Date.now()}_${sanitizedName}`;
          const moveResult = await fileUploadService.moveFile(
            tempAttachment.file_path,
            permanentPath
          );

          if (!moveResult.success) {
            errors.push(`Failed to move file ${tempAttachment.file_name}: ${moveResult.error}`);
            continue;
          }

          // Create material attachment record
          const { data: materialAttachment, error: insertError } = await supabase
            .from('material_attachments')
            .insert({
              material_id: materialId,
              file_name: tempAttachment.file_name,
              file_url: moveResult.publicUrl || tempAttachment.file_url,
              file_size: tempAttachment.file_size,
              file_type: tempAttachment.file_type,
              file_path: permanentPath
            })
            .select('id, file_name, file_url, file_size, file_type, created_at')
            .single();

          if (insertError) {
            console.error('Insert material attachment error:', insertError);
            errors.push(`Failed to create material attachment for ${tempAttachment.file_name}`);
            continue;
          }

          // Mark temp attachment as finalized
          await supabase
            .from('temp_attachments')
            .update({ is_finalized: true })
            .eq('id', tempAttachment.id);

          finalAttachments.push(materialAttachment);
        } catch (error) {
          console.error(`Error processing temp attachment ${tempAttachment.temp_id}:`, error);
          errors.push(`Error processing ${tempAttachment.file_name}: ${error.message}`);
        }
      }

      // Clean up any remaining temp files that were successfully processed
      const processedTempIds = tempAttachments
        .filter(t => t.is_finalized === true)
        .map(t => t.id);
      if (processedTempIds.length > 0) {
        await supabase
          .from('temp_attachments')
          .delete()
          .in('id', processedTempIds);
      }

      const response = {
        success: true,
        message: `Finalized ${finalAttachments.length} attachments`,
        data: {
          attachments: finalAttachments,
          processedCount: finalAttachments.length,
          totalRequested: tempIds.length,
          errors: errors.length > 0 ? errors : undefined
        }
      };

      if (errors.length > 0) {
        response.message += ` (${errors.length} errors occurred)`;
      }

      res.json(response);
    } catch (error) {
      console.error('Finalize temp attachments error:', error);
      throw new AppError('Failed to finalize temporary attachments', 500, 'FINALIZE_FAILED');
    }
  });

  /**
   * Delete material attachment
   */
  deleteMaterialAttachment = catchAsync(async (req, res) => {
    const { attachmentId } = req.params;
    const userId = req.user.id;

    // Get attachment with material details
    const { data: attachment } = await supabase
      .from('material_attachments')
      .select(`
        id, file_path, file_name,
        materials!inner(id, instructor_id)
      `)
      .eq('id', attachmentId)
      .single();

    if (!attachment) {
      throw new AppError('Attachment not found', 404, 'ATTACHMENT_NOT_FOUND');
    }

    // Check if user has permission to delete
    if (attachment.materials.instructor_id !== userId) {
      throw new AppError('Access denied', 403, 'ACCESS_DENIED');
    }

    try {
      // Delete from storage
      if (attachment.file_path) {
        await fileUploadService.deleteFile(attachment.file_path);
      }

      // Delete from database
      const { error } = await supabase
        .from('material_attachments')
        .delete()
        .eq('id', attachmentId);

      if (error) {
        console.error('Database attachment deletion error:', error);
        throw new AppError('Failed to delete attachment record', 500, 'DB_DELETE_FAILED');
      }

      res.json(
        buildResponse(true, 'Attachment deleted successfully', {
          deletedAttachment: {
            id: attachmentId,
            fileName: attachment.file_name
          }
        })
      );
    } catch (error) {
      console.error('Attachment deletion error:', error);
      throw new AppError('Failed to delete attachment', 500, 'DELETE_FAILED');
    }
  });

  /**
   * Get material attachments
   */
  getMaterialAttachments = catchAsync(async (req, res) => {
    const { materialId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Verify access to material
    let accessQuery = supabase
      .from('materials')
      .select('id')
      .eq('id', materialId);

    if (userRole === 'instructor') {
      accessQuery = accessQuery.eq('instructor_id', userId);
    } else {
      // Student access check through course enrollment
      accessQuery = accessQuery.select(`
        id,
        courses!inner(
          student_enrollments!inner(student_id)
        )
      `).eq('courses.student_enrollments.student_id', userId);
    }

    const { data: material } = await accessQuery.single();

    if (!material) {
      throw new AppError('Material not found or access denied', 404, 'MATERIAL_NOT_FOUND');
    }

    // Get attachments
    const { data: attachments, error } = await supabase
      .from('material_attachments')
      .select('id, file_name, file_url, file_size, file_type, created_at')
      .eq('material_id', materialId)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Get attachments error:', error);
      throw new AppError('Failed to fetch attachments', 500, 'GET_ATTACHMENTS_FAILED');
    }

    res.json(
      buildResponse(true, undefined, {
        attachments: attachments || [],
        count: attachments?.length || 0
      })
    );
  });
}

module.exports = new MaterialFileController();
