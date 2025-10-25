-- Create materials table
CREATE TABLE IF NOT EXISTS materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create material_attachments table
CREATE TABLE IF NOT EXISTS material_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create material_views table for tracking views
CREATE TABLE IF NOT EXISTS material_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    view_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(material_id, student_id)
);

-- Create material_downloads table for tracking file downloads
CREATE TABLE IF NOT EXISTS material_downloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    attachment_id UUID NOT NULL REFERENCES material_attachments(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_materials_course_id ON materials(course_id);
CREATE INDEX IF NOT EXISTS idx_materials_instructor_id ON materials(instructor_id);
CREATE INDEX IF NOT EXISTS idx_materials_published_at ON materials(published_at);

CREATE INDEX IF NOT EXISTS idx_material_attachments_material_id ON material_attachments(material_id);

CREATE INDEX IF NOT EXISTS idx_material_views_material_id ON material_views(material_id);
CREATE INDEX IF NOT EXISTS idx_material_views_student_id ON material_views(student_id);

CREATE INDEX IF NOT EXISTS idx_material_downloads_material_id ON material_downloads(material_id);
CREATE INDEX IF NOT EXISTS idx_material_downloads_attachment_id ON material_downloads(attachment_id);
CREATE INDEX IF NOT EXISTS idx_material_downloads_student_id ON material_downloads(student_id);

-- Enable RLS for all tables
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_downloads ENABLE ROW LEVEL SECURITY;

-- RLS Policies for materials table
-- Policy for instructors to manage their materials
CREATE POLICY "Instructors can manage their materials" ON materials
    FOR ALL USING (instructor_id = auth.uid());

-- Policy for students to view materials from their enrolled courses
CREATE POLICY "Students can view materials from their courses" ON materials
    FOR SELECT USING (
        course_id IN (
            SELECT c.id FROM courses c
            INNER JOIN groups g ON c.id = g.course_id
            INNER JOIN student_enrollments se ON g.id = se.group_id
            WHERE se.student_id = auth.uid()
        )
    );

-- RLS Policies for material_attachments table
-- Policy for instructors to manage material attachments
CREATE POLICY "Instructors can manage material attachments" ON material_attachments
    FOR ALL USING (
        material_id IN (
            SELECT id FROM materials WHERE instructor_id = auth.uid()
        )
    );

-- Policy for students to view material attachments they have access to
CREATE POLICY "Students can view material attachments they have access to" ON material_attachments
    FOR SELECT USING (
        material_id IN (
            SELECT m.id FROM materials m
            INNER JOIN courses c ON m.course_id = c.id
            INNER JOIN groups g ON c.id = g.course_id
            INNER JOIN student_enrollments se ON g.id = se.group_id
            WHERE se.student_id = auth.uid()
        )
    );

-- RLS Policies for material_views table
-- Policy for students to track their own views
CREATE POLICY "Students can track their own material views" ON material_views
    FOR ALL USING (student_id = auth.uid());

-- Policy for instructors to view tracking data for their materials
CREATE POLICY "Instructors can view tracking for their materials" ON material_views
    FOR SELECT USING (
        material_id IN (
            SELECT id FROM materials WHERE instructor_id = auth.uid()
        )
    );

-- RLS Policies for material_downloads table
-- Policy for students to track their own downloads
CREATE POLICY "Students can track their own material downloads" ON material_downloads
    FOR ALL USING (student_id = auth.uid());

-- Policy for instructors to view download tracking for their materials
CREATE POLICY "Instructors can view download tracking for their materials" ON material_downloads
    FOR SELECT USING (
        material_id IN (
            SELECT id FROM materials WHERE instructor_id = auth.uid()
        )
    );

-- Update temp_attachments to support material attachments
ALTER TABLE temp_attachments 
ADD COLUMN IF NOT EXISTS material_id UUID REFERENCES materials(id) ON DELETE CASCADE;

-- Create index for temp_attachments by material_id
CREATE INDEX IF NOT EXISTS idx_temp_attachments_material_id 
ON temp_attachments(material_id);

-- Add RLS policy for temp_attachments with material_id
CREATE POLICY "Users can manage temp attachments for materials" ON temp_attachments
    FOR ALL USING (
        (attachment_type = 'material' AND material_id IN (
            SELECT id FROM materials WHERE instructor_id = auth.uid()
        )) OR
        (attachment_type = 'assignment' AND assignment_id IN (
            SELECT id FROM assignments WHERE instructor_id = auth.uid()
        )) OR
        (attachment_type = 'announcement' AND announcement_id IN (
            SELECT id FROM announcements WHERE instructor_id = auth.uid()
        ))
    );
