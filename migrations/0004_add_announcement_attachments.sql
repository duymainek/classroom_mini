-- Create announcement_attachments table
CREATE TABLE IF NOT EXISTS announcement_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_announcement_attachments_announcement_id 
ON announcement_attachments(announcement_id);

-- Add attachment_type column to temp_attachments table to distinguish between assignment and announcement attachments
ALTER TABLE temp_attachments 
ADD COLUMN IF NOT EXISTS attachment_type VARCHAR(50) DEFAULT 'assignment';

-- Create index for temp_attachments by type
CREATE INDEX IF NOT EXISTS idx_temp_attachments_type 
ON temp_attachments(attachment_type);

-- Add RLS policies for announcement_attachments
ALTER TABLE announcement_attachments ENABLE ROW LEVEL SECURITY;

-- Policy for instructors to manage their announcement attachments
CREATE POLICY "Instructors can manage their announcement attachments" ON announcement_attachments
    FOR ALL USING (
        announcement_id IN (
            SELECT id FROM announcements WHERE instructor_id = auth.uid()
        )
    );

-- Policy for students to view announcement attachments they have access to
CREATE POLICY "Students can view announcement attachments they have access to" ON announcement_attachments
    FOR SELECT USING (
        announcement_id IN (
            SELECT a.id FROM announcements a
            INNER JOIN announcement_groups ag ON a.id = ag.announcement_id
            INNER JOIN groups g ON ag.group_id = g.id
            INNER JOIN student_enrollments se ON g.id = se.group_id
            WHERE se.student_id = auth.uid()
        )
    );