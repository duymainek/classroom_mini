-- Add file_path column to assignment_attachments table for better file management
ALTER TABLE assignment_attachments 
ADD COLUMN file_path TEXT;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_assignment_attachments_assignment_id 
ON assignment_attachments(assignment_id);

-- Add index on file_path for faster lookups during deletion
CREATE INDEX IF NOT EXISTS idx_assignment_attachments_file_path 
ON assignment_attachments(file_path);

-- Create storage bucket for assignment attachments (run this in Supabase SQL editor)
-- This ensures the bucket exists for file uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'assignment-attachments',
  'assignment-attachments',
  true,
  104857600, -- 100MB limit
  ARRAY[
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
  ]
) ON CONFLICT (id) DO NOTHING;