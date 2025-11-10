const multer = require('multer');
const { supabase } = require('../services/supabaseClient');
const fileUploadService = require('../services/fileUploadService');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    cb(null, true);
  }
});

class SubmissionFileController {
  /**
   * Upload temporary attachment for submission
   */
  uploadTempFile = [
    upload.single('file'),
    catchAsync(async (req, res) => {
      const userId = req.user.id;
      const file = req.file;

      if (!file) {
        throw new AppError('No file provided', 400, 'NO_FILE');
      }

      try {
        const sanitizedFileName = fileUploadService.sanitizeFilename(file.originalname);
        
        console.log('Submission filename sanitization:', { 
          original: file.originalname, 
          sanitized: sanitizedFileName 
        });

        const tempPath = `temp/submissions/${userId}/${Date.now()}_${sanitizedFileName}`;
        const uploadResult = await fileUploadService.uploadTempFile(
          file.buffer,
          tempPath,
          file.mimetype
        );

        const tempAttachmentId = `temp_submission_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

        console.log('=== SAVING TO TEMP_ATTACHMENTS TABLE (SUBMISSION) ===');
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
            attachment_type: 'submission'
          })
          .select('id, temp_id, file_name, file_url, file_size, file_type, created_at')
          .single();

        console.log('Database insert result:', { tempAttachment, dbError });

        if (dbError) {
          console.error('Database temp attachment save error:', dbError);
          await fileUploadService.deleteFile(uploadResult.filePath);
          throw new AppError('Failed to save temporary attachment', 500, 'DB_SAVE_FAILED');
        }

        console.log('Successfully saved to temp_attachments table');
        console.log('=== END SAVE TO TEMP_ATTACHMENTS (SUBMISSION) ===');

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
   * Finalize temporary attachments for submission
   */
  finalizeTempAttachments = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const { tempAttachmentIds } = req.body;
    const userId = req.user.id;

    console.log('=== FINALIZE TEMP ATTACHMENTS METHOD DEBUG (SUBMISSION) ===');
    console.log('Submission ID:', submissionId);
    console.log('User ID:', userId);
    console.log('Temp Attachment IDs:', tempAttachmentIds);

    if (!tempAttachmentIds || !Array.isArray(tempAttachmentIds) || tempAttachmentIds.length === 0) {
      console.log('No temp attachment IDs provided');
      return res.status(400).json({
        success: false,
        message: 'No temporary attachment IDs provided',
        code: 'NO_TEMP_ATTACHMENTS'
      });
    }

    try {
      console.log('Fetching temp attachments from database...');
      const { data: tempAttachments, error: fetchError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', tempAttachmentIds)
        .eq('user_id', userId)
        .eq('is_finalized', false);

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

      console.log(`Found ${tempAttachments.length} temp attachments to finalize`);

      const finalAttachments = [];
      const errors = [];

      for (const tempAttachment of tempAttachments) {
        try {
          const sanitizedName = fileUploadService.sanitizeFilename(tempAttachment.file_name);
          const permanentPath = `submissions/${submissionId}/${Date.now()}_${sanitizedName}`;
          const moveResult = await fileUploadService.moveFile(
            tempAttachment.file_path,
            permanentPath
          );

          if (!moveResult.success) {
            errors.push(`Failed to move file ${tempAttachment.file_name}: ${moveResult.error}`);
            continue;
          }

          const { data: submissionAttachment, error: insertError } = await supabase
            .from('submission_attachments')
            .insert({
              submission_id: submissionId,
              file_name: tempAttachment.file_name,
              file_url: moveResult.publicUrl || tempAttachment.file_url,
              file_size: tempAttachment.file_size,
              file_type: tempAttachment.file_type
            })
            .select('id, file_name, file_url, file_size, file_type, created_at')
            .single();

          if (insertError) {
            console.error('Insert submission attachment error:', insertError);
            errors.push(`Failed to create submission attachment for ${tempAttachment.file_name}`);
            continue;
          }

          await supabase
            .from('temp_attachments')
            .update({ is_finalized: true })
            .eq('id', tempAttachment.id);

          finalAttachments.push(submissionAttachment);
        } catch (error) {
          console.error(`Error processing temp attachment ${tempAttachment.temp_id}:`, error);
          errors.push(`Error processing ${tempAttachment.file_name}: ${error.message}`);
        }
      }

      const processedTempIds = tempAttachments
        .filter(t => t.is_finalized === true)
        .map(t => t.id);
      if (processedTempIds.length > 0) {
        await supabase
          .from('temp_attachments')
          .delete()
          .in('id', processedTempIds);
      }

      if (errors.length > 0) {
        console.warn('Some attachments failed to finalize:', errors);
      }

      res.json(buildResponse(true, 'Attachments finalized successfully', {
        attachments: finalAttachments,
        errors: errors.length > 0 ? errors : undefined
      }));
    } catch (error) {
      console.error('Finalize temp attachments error:', error);
      throw new AppError('Failed to finalize attachments', 500, 'FINALIZE_FAILED');
    }
  });
}

module.exports = new SubmissionFileController();

